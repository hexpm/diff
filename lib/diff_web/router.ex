defmodule DiffWeb.Router do
  use DiffWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DiffWeb do
    pipe_through :browser

    live "/", SearchView
    get "/diff/:package/:from/:to", PageController, :diff
  end

  # Other scopes may use custom stacks.
  # scope "/api", DiffWeb do
  #   pipe_through :api
  # end
end
