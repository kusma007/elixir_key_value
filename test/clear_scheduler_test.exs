defmodule ClearSchedulerTest do
  use ExUnit.Case
  alias KeyValue.ClearScheduler
  alias KeyValue.Storage
  # doctest KeyValue

  setup_all do
    on_exit fn ->
      File.rm("storage_test")
      :ok
    end
  end

  test "check process" do
    # Сохраняем в базу тестовую запись с ttl в секунду
    assert Storage.insert("test", "test value", 1) == :true

    # Убеждаемся, что запись сохранена
    {:ok, result} = Storage.open_close fn table_name ->
      [{key, _, _}] = Storage.one(table_name, "test")
      key
    end
    assert result == "test"
    # Ждём секунду, что бы прошёл ttl
    :timer.sleep(1_000)
    Application.get_env(:key_value, :clear_timeout)
    # Запускаем сервер очистки
    start_supervised(ClearScheduler)
    # Ждём две секунды, что бы отработал сервер
    :timer.sleep(2_000)

    # Проверяем, что записи в БД нет
    {:ok, result} = Storage.open_close fn table_name ->
      Storage.one(table_name, "test")
    end
    assert (result == [])

  end
end
