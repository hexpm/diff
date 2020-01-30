defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  def diff(conn, %{"package" => package, "versions" => versions}) do
    case parse_versions(package, versions) do
      {:ok, from, to} ->
        do_diff(conn, package, from, to)

      :error ->
        conn
        |> put_status(400)
        |> render("400.html")
    end
  end

  defp do_diff(conn, package, from, to) do
    case Diff.Storage.get(package, from, to) do
      {:ok, diff} ->
        Logger.debug("cache hit for #{inspect(package)}")
        render(conn, "diff.html", diff: diff)

      {:error, :not_found} ->
        case Diff.Hex.diff(package, from, to) do
          {:ok, diff} ->
            rendered =
              Phoenix.View.render_to_iodata(DiffWeb.RenderView, "render.html", diff: diff)

            Diff.Storage.put(package, from, to, rendered)
            render(conn, "diff.html", diff: rendered)

          {:error, :unknown} ->
            render(conn, "500.html")
        end
    end
  end

  defp parse_versions(package, versions) do
    with [from, to] <- versions |> String.split("..") |> Enum.map(&String.trim/1),
         {:ok, from} <- parse_version(package, :from, from),
         {:ok, to} <- parse_version(package, :to, to) do
      {:ok, to_string(from), to_string(to)}
    else
      _ ->
        :error
    end
  end

  defp parse_version(_package, :from, ""), do: :error

  defp parse_version(package, :to, "") do
    with {:ok, versions} <- Diff.Package.Store.get_versions(package) do
      version =
        versions
        |> Enum.map(&Version.parse!/1)
        |> Enum.max()

      {:ok, version}
    end
  end

  defp parse_version(_package, _kind, input), do: Version.parse(input)
end
