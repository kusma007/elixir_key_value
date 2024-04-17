import Config


config :key_value, table_name: :storage_test

config :key_value, clear_timeout: [type: :seconds, count: 1]
