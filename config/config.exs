# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :diff,
  cache_version: 2,
  package_store_impl: Diff.Package.DefaultStore

# Configures the endpoint
config :diff, DiffWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "sCQPp27jGUACmECgpI4vEwAJUrryxT7+d2IzxkbUv/57paSo723fbsED+EmRcvfj",
  render_errors: [
    view: DiffWeb.ErrorView,
    accepts: ~w(html json),
    layout: {DiffWeb.LayoutView, "root.html"}
  ],
  pubsub_server: Diff.PubSub,
  live_view: [signing_salt: "Bmk5Cupu"]

# Configures Elixir's Logger
config :logger, :default_formatter, format: "$metadata[$level] $message\n"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
