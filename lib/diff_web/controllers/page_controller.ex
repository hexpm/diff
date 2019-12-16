defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  def diff(conn, %{"package" => package, "versions" => versions}) do
    case parse_versions(versions) do
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

  defp parse_versions(versions) do
    with [from, to] <- String.split(versions, "..", trim: true),
         {:ok, from} <- Version.parse(from),
         {:ok, to} <- Version.parse(to) do
      {:ok, to_string(from), to_string(to)}
    else
      _ ->
        :error
    end
  end
end
