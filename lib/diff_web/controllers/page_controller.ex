defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  def diff(conn, %{"package" => package, "versions" => versions}) do
    case parse_versions(versions) do
      {:ok, from, to} ->
        do_diff(conn, package, from, to)

      :error ->
        render_error(conn, 400)
    end
  end

  defp do_diff(conn, _package, version, version) do
    render_error(conn, 400)
  end

  defp do_diff(conn, _package, :latest, _version) do
    render_error(conn, 400)
  end

  defp do_diff(conn, package, from, :latest) do
    case Diff.Package.Store.get_versions(package) do
      {:ok, versions} ->
        to =
          versions
          |> Enum.map(&Version.parse!/1)
          |> Enum.filter(&(&1.pre == []))
          |> Enum.max(Version)

        do_diff(conn, package, from, to)

      {:error, :not_found} ->
        render_error(conn, 404)
    end
  end

  defp do_diff(conn, package, from, to) do
    from = to_string(from)
    to = to_string(to)

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
            render_error(conn, 500)
        end
    end
  end

  defp parse_versions(versions) do
    with [from, to] <- versions |> String.split("..") |> Enum.map(&String.trim/1),
         {:ok, from} <- parse_version(from),
         {:ok, to} <- parse_version(to) do
      {:ok, from, to}
    else
      _ ->
        :error
    end
  end

  defp parse_version(""), do: {:ok, :latest}
  defp parse_version(input), do: Version.parse(input)

  defp render_error(conn, status) do
    conn
    |> put_status(status)
    |> render("#{status}.html")
  end
end
