# R: Тут в целом все ок, каноническая релазиация костыльного шедулера
#    обычно так и делают, когда надо шедулер без лишней мути.
#
#    Единственное что название модуля все таки надо было сделать типа KeyValue.ClearScheduler
#    а модуль KeyValue оставить как точка входа для либы.
#    То есть обычно делают так, заводят какую то иерархию модулей, типа A.B, A.C, A.B.C, etc...
#    а все публичное API засовывают в модуль A, что бы тот, кто будет пользоваться либой
#    не парился и не писал alias A.B.C.D, а сразу делал A.function_name(...)
#
#    Еще можно было бы добавить @impl true, указывая тем самым, что ты следуешь
#    спеке behaivor-а, но это на любителя, можно не указывать, ничего страшного не
#    случится
#
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
  # R:                                 | тут скорее всего просто integer или number,
  #                                    v так как будет зависить от конфига
  @spec init(any()) :: {:ok, any(), 300_000}
  def init(state), do: {:ok, state, get_timeout()}

  @doc """
  Функция срабатывает при отправке сообщения серверу напрямую
  И выполняет очистку хранилища по установленому timeout в конфиге
  """
  def handle_info(:timeout, state) do
    Storage.clear_ttl()
    # R:                 | Вот такие вещи обычно "приянто" делать через атрибут модуля
    #                    | атрибуты модуля "раскрываются" в момент компиляции, но мне
    #                    v подход с функцией нравится больше, проще будет в будущем накинуть логики
    {:noreply, state, get_timeout()}
  end

  # Получение количества секунд таймаута между обращением к серверу
  # R: Вот с этим можно было бы не париться, так как конфигурации можно использовать функции.
  #    То есть я к тому, что сразу в конфиге пишем:
  #      config :key_value, clear_timeout: :timer.minutes(5)
  #    а тут не делаем лишней логики
  defp get_timeout() do
    clear_timeout = Application.get_env(:key_value, :clear_timeout)

    case clear_timeout do
      [type: :minutes, count: count] -> :timer.minutes(count)
      [type: :seconds, count: count] -> :timer.seconds(count)
      # R: Дефолтный параметр можно было бы сразу указать в get_env
      #      clear_timeout = Application.get_env(:key_value, :clear_timeout, :timer.minutes(5))
      _ -> :timer.minutes(5)
    end

  end
end
