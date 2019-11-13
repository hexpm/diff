import Config

config :diff, bucket: System.fetch_env!("DIFF_BUCKET")

config :goth, json: System.fetch_env!("HEXDOCS_GCP_CREDENTIALS")
