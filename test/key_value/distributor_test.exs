defmodule KeyValue.DistributorTest do
  use ExUnit.Case
  use Plug.Test

  alias KeyValue.Distributor

  setup_all do
    Application.put_env(:key_value, :table_name, :storage_test)

    on_exit fn ->
      Application.put_env(:key_value, :table_name, :storage)
      File.rm("storage_test")
      :ok
    end
  end

  test "check GET 404", do: assert Distributor.to_storage("GET", %{"key" => "test"}) == {404}

  test "check POST" do
    assert Distributor.to_storage("POST", %{"key" => "test", "value" => "test value", "ttl" => "100"}) == {201}
    assert Distributor.to_storage("POST", %{"key" => "test", "value" => "test value", "ttl" => "100"}) == {409}
  end

  test "check GET 200", do: assert Distributor.to_storage("GET", %{"key" => "test"}) == {200, %{"test" => "test value"}}

  test "check PUT" do
    assert Distributor.to_storage("PUT", %{"key" => "test", "value" => "test value 1", "ttl" => "100"}) == {204}
    assert Distributor.to_storage("PUT", %{"key" => "test 1", "value" => "test value 1", "ttl" => "100"}) == {404}
  end

  test "check DELETE" do
    assert Distributor.to_storage("DELETE", %{"key" => "test"}) == {200}
    assert Distributor.to_storage("DELETE", %{"key" => "test 1"}) == {404}
  end

end
