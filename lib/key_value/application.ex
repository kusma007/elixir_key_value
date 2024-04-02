defmodule KeyValue.Application do
  @moduledoc """

  Основной модуль приложения
  Запускает сервер, который будет доступен по адресу http://127.0.0.1:{{cowboy_port}}/
  :cowboy_port устанавливается в файле config/config.exs
  """

  use Application
  require Logger

  @impl true
  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: KeyValue.Router, options: [port: cowboy_port()]}, # Запуск сервера http
      # KeyValue # Запуск шкедулера для авто очистки записей из хранилища
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KeyValue.Supervisor]

    # Выводим в консоль информацию, что приложение запустилось
    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  # Фнукция возвращает номер порта из конфига
  defp cowboy_port, do: Application.get_env(:key_value, :cowboy_port, 8080)
end
