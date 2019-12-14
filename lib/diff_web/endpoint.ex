defmodule DiffWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :diff

  socket "/live", Phoenix.LiveView.Socket

  plug DiffWeb.Plugs.Forwarded

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :diff,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug DiffWeb.Plugs.Status
  plug Plug.RequestId
  plug Logster.Plugs.Logger, excludes: [:params]
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  if Mix.env() == :prod do
    plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
  end

  plug DiffWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.fetch_env!("DIFF_PORT")

      case Integer.parse(port) do
        {_int, ""} ->
          host = System.fetch_env!("DIFF_HOST")
          secret_key_base = System.fetch_env!("DIFF_SECRET_KEY_BASE")
          config = put_in(config[:http][:port], port)
          config = put_in(config[:url][:host], host)
          config = put_in(config[:secret_key_base], secret_key_base)
          {:ok, config}

        :error ->
          {:ok, config}
      end
    else
      {:ok, config}
    end
  end
end
