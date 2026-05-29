defmodule Diff.HTTPTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "get/2" do
    test "returns status, headers, body on 200", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-thing", "bar")
        |> Plug.Conn.resp(200, "hello")
      end)

      assert {:ok, 200, headers, "hello"} =
               Diff.HTTP.get("http://localhost:#{bypass.port}/foo", [{"accept", "*/*"}])

      assert {"x-thing", "bar"} in headers
    end

    test "passes request headers through", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        assert Plug.Conn.get_req_header(conn, "x-test") == ["sent"]
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, 204, _, ""} =
               Diff.HTTP.get("http://localhost:#{bypass.port}/foo", [{"x-test", "sent"}])
    end

    test "returns error tuple when server unreachable" do
      assert {:error, _} = Diff.HTTP.get("http://localhost:1/never", [])
    end
  end

  describe "put/3" do
    test "sends body and returns response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/blob", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "payload"
        Plug.Conn.resp(conn, 201, "ok")
      end)

      assert {:ok, 201, _, "ok"} =
               Diff.HTTP.put("http://localhost:#{bypass.port}/blob", [], "payload")
    end
  end
end
