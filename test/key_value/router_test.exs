defmodule KeyValue.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias KeyValue.Storage
  alias KeyValue.Router

  @opts Router.init([])

  setup_all do
    on_exit fn ->
      File.rm("storage_test")
      :ok
    end
  end


  test "check GET 404" do
    conn =
      :get
      |> conn("/?key=test", "")
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 404
  end

  test "check POST 201" do
    conn =
      :post
      |> conn("/", %{"key" => "test", "value" => "test value", "ttl" => "100"})
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 201
  end

  test "check GET 200" do
    conn =
      :get
      |> conn("/?key=test", "")
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
  end

  test "check POST 409" do
    conn =
      :post
      |> conn("/", %{"key" => "test", "value" => "test value", "ttl" => "100"})
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 409
  end

  test "check PUT 201" do
    conn =
      :put
      |> conn("/", %{"key" => "test", "value" => "test value 1", "ttl" => "100"})
      |> Router.call(@opts)

      assert Storage.get("test") == %{"test" => "test value 1"}

      assert conn.state == :sent
      assert conn.status == 204
  end

  test "check DELETE 200" do
    conn =
      :delete
      |> conn("/?key=test", "")
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
  end

  test "check DELETE 404" do
    conn =
      :delete
      |> conn("/?key=test", "")
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 404
  end

  test "check 404" do
    conn =
      :get
      |> conn("/test", "")
      |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 404
  end

end
