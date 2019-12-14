defmodule Diff.Hex do
  @config Map.put(:hex_core.default_config(), :http_adapter, Diff.Hex.Adapter)

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
        for release <- releases, release.version in versions do
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
    path_from = tmp_path("#{package}-#{from}-")
    path_to = tmp_path("#{package}-#{to}-")

    try do
      with {:ok, tarball_from} <- get_tarball(package, from),
           {:ok, tarball_to} <- get_tarball(package, to),
           :ok <- unpack_tarball(tarball_from, path_from),
           :ok <- unpack_tarball(tarball_to, path_to),
           {:ok, gd} <- git_diff(path_from, path_to) do
        GitDiff.parse_patch(gd)
      else
        error ->
          Logger.error(inspect(error))
          {:error, :unknown}
      end
    after
      File.rm_rf(path_from)
      File.rm_rf(path_to)
    end
  end

  defp git_diff(path_from, path_to) do
    case System.cmd("git", [
           "-c",
           "core.quotepath=false",
           "diff",
           "--no-index",
           "--no-color",
           path_from,
           path_to
         ]) do
      {"", 1} ->
        {:error, :not_found}

      {result, 1} ->
        cleaned = String.replace(result, [path_from, path_to], "")
        {:ok, cleaned}

      other ->
        {:error, other}
    end
  end

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join(System.tmp_dir!(), prefix <> random_string)
  end
end
