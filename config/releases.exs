import Config

config :rollbax,
  access_token: System.fetch_env!("DIFF_ROLLBAR_ACCESS_TOKEN")
