import Config

# Порт для запуска
config :key_value, cowboy_port: 8080

config :key_value, table_name: :storage

config :key_value, clear_timeout: [type: :minutes, count: 5]

import_config "#{Mix.env}.exs"
