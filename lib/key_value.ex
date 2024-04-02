defmodule KeyValue do
  @moduledoc """

    Шкедулер для авто очистки хранилища просроченных записей
  """

  alias KeyValue.Storage

  use GenServer

  @doc """
  Запуск и линковка нашей очереди.
  Это вспомогательный метод.
  """
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc """
  Функция обратного вызова для GenServer.init/1
  """
  @spec init(any()) :: {:ok, any(), 300_000}
  def init(state), do: {:ok, state, get_timeout()}

  @doc """
  Функция срабатывает при отправке сообщения серверу напрямую
  И выполняет очистку хранилища по установленому timeout в конфиге
  """
  def handle_info(:timeout, state) do
    Storage.clear_ttl()
    {:noreply, state, get_timeout()}
  end

  # Получение количества секунд таймаута между обращением к серверу
  defp get_timeout() do
    clear_timeout = Application.get_env(:key_value, :clear_timeout)

    case clear_timeout do
      [type: :minutes, count: count] -> :timer.minutes(count)
      [type: :seconds, count: count] -> :timer.seconds(count)
      _ -> :timer.minutes(5)
    end

  end
end
