# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :diff,
  cache_version: 1,
  package_store_impl: Diff.Package.DefaultStore

# Configures the endpoint
config :diff, DiffWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "sCQPp27jGUACmECgpI4vEwAJUrryxT7+d2IzxkbUv/57paSo723fbsED+EmRcvfj",
  render_errors: [view: DiffWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Diff.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "Bmk5Cupu"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :rollbax, enabled: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
