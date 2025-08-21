defmodule Diff.Hex do
  @config %{
    :hex_core.default_config()
    | http_adapter: {Diff.Hex.Adapter, %{}},
      http_user_agent_fragment: "hexpm_diff"
  }

  @max_file_size 1024 * 1024

  require Logger

  def get_versions() do
    with {:ok, {200, _, results}} <- :hex_repo.get_versions(@config) do
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
    with {:ok, {200, _, tarball}} <- :hex_repo.get_tarball(@config, package, version) do
      {:ok, tarball}
    else
      {:ok, {403, _, _}} ->
        {:error, :not_found}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get tarball for package: #{package}. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    path = to_charlist(path)

    with {:ok, _} <- :hex_tarball.unpack(tarball, path) do
      :ok
    end
  end

  def get_checksums(package, versions) do
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(@config, package) do
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
    path_from = tmp_path("package-#{package}-#{from}-")
    path_to = tmp_path("package-#{package}-#{to}-")

    with {:ok, tarball_from} <- get_tarball(package, from),
         :ok <- unpack_tarball(tarball_from, path_from),
         {:ok, tarball_to} <- get_tarball(package, to),
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
        all_files
        |> Stream.flat_map(fn file ->
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
        |> Stream.transform(
          fn -> :ok end,
          fn elem, :ok -> {[elem], :ok} end,
          fn :ok ->
            File.rm_rf(path_from)
            File.rm_rf(path_to)
          end
        )

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

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join([System.tmp_dir!(), "diff", prefix <> random_string])
  end
end
