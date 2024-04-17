defmodule KeyValue.StorageTest do
  use ExUnit.Case
  use Plug.Test

  alias KeyValue.Storage

  setup_all do
    on_exit fn ->
      File.rm("storage_test")
      :ok
    end
  end

  test "check get failed", do: assert Storage.get("test") == :error

  test "check insert" do
    assert Storage.insert("test", "test value", 15)
    assert Storage.insert("test", "test value", 15) == false
  end

  test "returns time in second", do: assert Storage.get_time() == :os.system_time(:seconds)

  test "check get", do: assert Storage.get("test") == %{"test" => "test value"}

  test "check update" do
    assert Storage.update("test", "test value 1", 15) == :ok
    assert Storage.get("test") == %{"test" => "test value 1"}
    assert Storage.update("test 1", "test value 1", 15) == :error
  end

  test "check delete" do
    assert Storage.delete("test") == :ok
  end

end
