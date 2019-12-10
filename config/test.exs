use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :diff, DiffWeb.Endpoint,
  http: [port: 5004],
  server: false

config :goth, config: %{"project_id" => "diff"}

# Print only warnings and errors during test
config :logger, level: :warn
