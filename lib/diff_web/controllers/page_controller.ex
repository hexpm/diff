defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  def diff(conn, %{"package" => package, "from" => from, "to" => to}) do
    case Diff.Storage.get(package, from, to) do
      {:ok, diff} ->
        Logger.debug("cache hit for #{inspect(package)}")
        render(conn, "diff.html", diff: diff)

      {:error, :not_found} ->
        case Diff.HexClient.diff(package, from, to) do
          {:ok, diff} ->
            Diff.Storage.put(package, from, to, diff)
            render(conn, "diff.html", diff: diff)

          {:error, :not_found} ->
            render(conn, "404.html")

          {:error, reason} ->
            Logger.error("Failed to generate diff with:\n#{inspect(reason)}")
            render(conn, "500.html")
        end
    end
  end
end
