defmodule Diff.HexClient do
  @config :hex_core.default_config()

  require Logger

  def get_versions() do
    try do
      with {:ok, {200, _, results}} <- :hex_repo.get_versions(@config) do
        {:ok, results}
      end
    rescue
      e in MatchError -> {:error, e}
    end
  end

  def get_tarball(name, version) do
    with {:ok, {200, _, tarball}} <- :hex_repo.get_tarball(@config, name, version) do
      {:ok, tarball}
    else
      {:ok, {403, _, _}} -> {:error, :not_found}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    path = to_charlist(path)

    with {:ok, _} <- :hex_tarball.unpack(tarball, path) do
      :ok
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
    case System.cmd("git", ["diff", "--no-index", path_from, path_to]) do
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
