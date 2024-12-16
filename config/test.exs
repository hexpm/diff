import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :diff, DiffWeb.Endpoint,
  http: [port: 5004],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

config :diff,
  package_store_impl: Diff.Package.StoreMock,
  storage_impl: Diff.StorageMock
