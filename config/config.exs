# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :diff,
  cache_version: 2,
  package_store_impl: Diff.Package.DefaultStore,
  repo_url: "https://repo.hex.pm"

# Configures the endpoint
config :diff, DiffWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  secret_key_base: "sCQPp27jGUACmECgpI4vEwAJUrryxT7+d2IzxkbUv/57paSo723fbsED+EmRcvfj",
  render_errors: [
    view: DiffWeb.ErrorView,
    accepts: ~w(html json),
    layout: {DiffWeb.LayoutView, "root.html"}
  ],
  pubsub_server: Diff.PubSub,
  live_view: [signing_salt: "Bmk5Cupu"]

config :esbuild,
  version: "0.25.0",
  diff: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.1.11",
  default: [
    args: ~w(
      --input=./assets/css/app.css
      --output=./priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter, format: "$metadata[$level] $message\n"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
