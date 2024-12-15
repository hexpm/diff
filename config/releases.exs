import Config

config :diff,
  host: System.fetch_env!("DIFF_HOST"),
  hexpm_host: System.fetch_env!("DIFF_HEXPM_HOST"),
  cache_version: String.to_integer(System.fetch_env!("DIFF_CACHE_VERSION")),
  bucket: System.fetch_env!("DIFF_BUCKET")

config :goth, json: System.fetch_env!("DIFF_GCP_CREDENTIALS")

config :sentry,
  dsn: System.fetch_env!("DIFF_SENTRY_DSN"),
  environment_name: System.fetch_env!("DIFF_ENV")

config :kernel,
  inet_dist_listen_min: String.to_integer(System.fetch_env!("BEAM_PORT")),
  inet_dist_listen_max: String.to_integer(System.fetch_env!("BEAM_PORT"))
