defmodule Diff.Hex do
  @behaviour Diff.Hex.Behaviour

  defp config() do
    config = %{
      :hex_core.default_config()
      | http_adapter: {Diff.Hex.Adapter, %{}},
        http_user_agent_fragment: "hexpm_diff",
        repo_url: Application.fetch_env!(:diff, :repo_url)
    }

    if repo_public_key = Application.get_env(:diff, :repo_public_key) do
      %{config | repo_public_key: repo_public_key}
    else
      %{config | repo_verify: false}
    end
  end

  @max_file_size 1024 * 1024

  require Logger

  def get_versions() do
    with {:ok, {200, _, results}} <- :hex_repo.get_versions(config()) do
      {:ok, results}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package versions. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def get_tarball(package, version) do
    path = Diff.TmpDir.tmp_file("tarball")

    case :hex_repo.get_tarball_to_file(config(), package, version, to_charlist(path)) do
      {:ok, {200, _headers}} ->
        {:ok, path}

      {:ok, {403, _}} ->
        {:error, :not_found}

      {:ok, {status, _}} ->
        Logger.error("Failed to get tarball for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get tarball for package: #{package}. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def unpack_tarball(tarball_path, output_path) do
    with {:ok, _} <-
           :hex_tarball.unpack({:file, to_charlist(tarball_path)}, to_charlist(output_path)) do
      ensure_readable(output_path)
      :ok
    end
  end

  defp ensure_readable(dir) do
    dir
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.each(fn path ->
      case File.stat(path) do
        {:ok, %{type: :directory, access: access}} when access in [:none, :write] ->
          File.chmod(path, 0o755)

        {:ok, %{type: :regular, access: access}} when access in [:none, :write] ->
          File.chmod(path, 0o644)

        _ ->
          :ok
      end
    end)
  end

  def get_checksums(package, versions) do
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(config(), package) do
      checksums =
        for release <- releases.releases, release.version in versions do
          release.outer_checksum
        end

      {:ok, checksums}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get checksums for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Failed to get checksums for package: #{package}. Reason: #{inspect(reason)}"
        )

        {:error, :not_found}
    end
  end

  def diff(package, from, to) do
    with {:ok, tarball_from} <- get_tarball(package, from),
         path_from = Diff.TmpDir.tmp_dir("package-#{package}-#{from}"),
         :ok <- unpack_tarball(tarball_from, path_from),
         {:ok, tarball_to} <- get_tarball(package, to),
         path_to = Diff.TmpDir.tmp_dir("package-#{package}-#{to}"),
         :ok <- unpack_tarball(tarball_to, path_to) do
      from_files = tree_files(path_from)
      to_files = tree_files(path_to)

      new_files = to_files -- from_files
      removed_files = from_files -- to_files
      changed_files = MapSet.new((to_files -- new_files) -- removed_files)
      new_files = MapSet.new(new_files)
      removed_files = MapSet.new(removed_files)

      all_files = (from_files ++ to_files) |> Enum.uniq() |> Enum.sort()

      stream =
        Stream.flat_map(all_files, fn file ->
          {path_old, path_new} =
            cond do
              file in new_files -> {"/dev/null", Path.join(path_to, file)}
              file in removed_files -> {Path.join(path_from, file), "/dev/null"}
              file in changed_files -> {Path.join(path_from, file), Path.join(path_to, file)}
            end

          with {_, true} <- {:file_size_old, file_size_check?(path_old)},
               {_, true} <- {:file_size_new, file_size_check?(path_new)},
               {_, {:ok, output}} <- {:git_diff, git_diff(path_old, path_new)} do
            if output do
              [{:ok, {output, path_from, path_to}}]
            else
              []
            end
          else
            {:file_size_old, false} ->
              [{:too_large, Path.relative_to(path_old, path_from)}]

            {:file_size_new, false} ->
              [{:too_large, Path.relative_to(path_new, path_to)}]

            {error, {:error, reason}} ->
              [{:error, {error, reason}}]
          end
        end)

      {:ok, stream}
    else
      error ->
        Logger.error("Failed to create diff #{package} #{from}..#{to} with: #{inspect(error)}")
        :error
    end
  end

  defp git_diff(path_from, path_to) do
    case System.cmd("git", [
           "-c",
           "core.quotepath=false",
           "-c",
           "diff.algorithm=histogram",
           "diff",
           "--no-index",
           "--no-color",
           path_from,
           path_to
         ]) do
      {"", 0} -> {:ok, nil}
      {output, 1} -> {:ok, output}
      other -> {:error, other}
    end
  end

  defp file_size_check?(path) do
    File.stat!(path).size <= @max_file_size
  end

  defp tree_files(directory) do
    directory
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?(&1, raw: true))
    |> Enum.map(&Path.relative_to(&1, directory))
  end
end
