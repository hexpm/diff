defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  def diff(conn, %{"package" => package, "from" => from, "to" => to}) do
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
end
