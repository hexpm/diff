defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
