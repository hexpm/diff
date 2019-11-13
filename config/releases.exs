import Config

config :diff, bucket: System.fetch_env!("DIFF_BUCKET")

config :goth, json: System.fetch_env!("HEXDOCS_GCP_CREDENTIALS")

config :rollbax,
  access_token: System.fetch_env!("DIFF_ROLLBAR_ACCESS_TOKEN")
