import Config

config :diff,
  cache_version: String.to_integer(System.fetch_env!("DIFF_CACHE_VERSION")),
  bucket: System.fetch_env!("DIFF_BUCKET")

config :goth, json: System.fetch_env!("DIFF_GCP_CREDENTIALS")

config :rollbax, access_token: System.fetch_env!("DIFF_ROLLBAR_ACCESS_TOKEN")

config :kernel,
  inet_dist_listen_min: String.to_integer(System.fetch_env!("BEAM_PORT")),
  inet_dist_listen_max: String.to_integer(System.fetch_env!("BEAM_PORT"))
