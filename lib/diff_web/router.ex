defmodule DiffWeb.Router do
  use DiffWeb, :router
  use Plug.ErrorHandler

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {DiffWeb.LayoutView, :root}
    plug :put_secure_browser_headers
  end

  scope "/", DiffWeb do
    pipe_through :browser

    live "/", SearchLiveView
    live "/diff/:package/:versions", DiffLiveView
    live "/diffs", DiffLiveView
  end
end
