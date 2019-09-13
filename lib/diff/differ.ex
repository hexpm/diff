defmodule Diff.Differ do
  require Logger
  import Diff.HexClient

  @spec diff(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, :not_found | :unknown}
  def diff(package, from, to) do
    path_from = tmp_path("#{package}-#{from}-")
    path_to = tmp_path("#{package}-#{to}-")

    try do
      {:ok, tarball_from} = get_tarball(package, from)
      {:ok, tarball_to} = get_tarball(package, to)

      :ok = unpack_tarball(tarball_from, path_from)
      :ok = unpack_tarball(tarball_to, path_to)

      {:ok, gd} = git_diff(path_from, path_to)
      File.write("debugme", gd)
      IO.inspect(gd, label: "diff")
      {:ok, parsed} = GitDiff.parse_patch(gd)
      rendered = Diff.Render.diff_to_html(parsed)
      {:ok, :erlang.iolist_to_binary(rendered)}
    rescue
      error ->
        Logger.error(inspect(error))
        {:error, :unknown}
    after
      File.rm_rf!(path_from)
      File.rm_rf!(path_to)
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
