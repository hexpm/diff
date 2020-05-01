defmodule DiffWeb.Router do
  use DiffWeb, :router
  use Plug.ErrorHandler
  use DiffWeb.Plugs.Rollbax

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :put_secure_browser_headers
  end

  scope "/", DiffWeb do
    pipe_through :browser

    live "/", SearchLiveView
    get "/diff/:package/:versions", PageController, :diff
    get "/diffs", PageController, :diffs
  end
end
