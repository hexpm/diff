import Config

if config_env() == :prod do
  config :diff,
    host: System.fetch_env!("DIFF_HOST"),
    hexpm_host: System.fetch_env!("DIFF_HEXPM_HOST"),
    cache_version: String.to_integer(System.fetch_env!("DIFF_CACHE_VERSION")),
    bucket: System.fetch_env!("DIFF_BUCKET")

  config :diff, DiffWeb.Endpoint,
    http: [port: String.to_integer(System.fetch_env!("DIFF_PORT"))],
    url: [host: System.fetch_env!("DIFF_HOST")],
    secret_key_base: System.fetch_env!("DIFF_SECRET_KEY_BASE")

  config :sentry,
    dsn: System.fetch_env!("DIFF_SENTRY_DSN"),
    environment_name: System.fetch_env!("DIFF_ENV")

  config :kernel,
    inet_dist_listen_min: String.to_integer(System.fetch_env!("BEAM_PORT")),
    inet_dist_listen_max: String.to_integer(System.fetch_env!("BEAM_PORT"))
end
