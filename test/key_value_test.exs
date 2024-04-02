defmodule KeyValueTest do
  use ExUnit.Case
  alias KeyValue.Storage
  # doctest KeyValue

  setup_all do
    Application.put_env(:key_value, :table_name, :storage_test)
    Application.put_env(:key_value, :clear_timeout, [type: :seconds, count: 1])

    on_exit fn ->
      Application.put_env(:key_value, :table_name, :storage)
      Application.put_env(:key_value, :clear_timeout, [type: :minutes, count: 5])
      File.rm("storage_test")
      :ok
    end
  end

  test "check process" do
    # Сохраняем в базу тестовую запись с ttl в секунду
    assert Storage.insert("test", "test value", 1) == :true

    # Убеждаемся, что запись сохранена
    [{key, _, _}] = Storage.one(Storage.open(), "test")
    assert key == "test"
    # Ждём секунду, что бы прошёл ttl
    :timer.sleep(1_000)
    Application.get_env(:key_value, :clear_timeout)
    # Запускаем сервер очистки
    start_supervised(KeyValue)
    # Ждём две секунды, что бы отработал сервер
    :timer.sleep(2_000)

    # Проверяем, что записи в БД нет
    res = Storage.one(Storage.open(), "test")
    assert (res == [])

    Storage.close()
  end
end
