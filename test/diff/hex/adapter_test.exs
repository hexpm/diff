defmodule Diff.Hex.AdapterTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, base: "http://localhost:#{bypass.port}"}
  end

  describe "request/5" do
    test "returns status, headers map, body on 200", %{bypass: bypass, base: base} do
      Bypass.expect_once(bypass, "GET", "/p", fn conn ->
        conn |> Plug.Conn.put_resp_header("x-foo", "1") |> Plug.Conn.resp(200, "hi")
      end)

      assert {:ok, {200, headers, "hi"}} =
               Diff.Hex.Adapter.request(:get, base <> "/p", %{}, :undefined, %{})

      assert headers["x-foo"] == "1"
    end

    test "returns 404 with body", %{bypass: bypass, base: base} do
      Bypass.expect_once(bypass, "GET", "/p", fn conn -> Plug.Conn.resp(conn, 404, "nope") end)

      assert {:ok, {404, _headers, "nope"}} =
               Diff.Hex.Adapter.request(:get, base <> "/p", %{}, :undefined, %{})
    end

    test "follows a 302 to a new path", %{bypass: bypass, base: base} do
      Bypass.expect(bypass, fn
        %{request_path: "/a"} = conn ->
          conn |> Plug.Conn.put_resp_header("location", "/b") |> Plug.Conn.resp(302, "")

        %{request_path: "/b"} = conn ->
          Plug.Conn.resp(conn, 200, "final")
      end)

      assert {:ok, {200, _headers, "final"}} =
               Diff.Hex.Adapter.request(:get, base <> "/a", %{}, :undefined, %{})
    end

    test "follows an absolute Location", %{bypass: bypass, base: base} do
      Bypass.expect(bypass, fn
        %{request_path: "/a"} = conn ->
          conn
          |> Plug.Conn.put_resp_header("location", "#{base}/b")
          |> Plug.Conn.resp(301, "")

        %{request_path: "/b"} = conn ->
          Plug.Conn.resp(conn, 200, "done")
      end)

      assert {:ok, {200, _, "done"}} =
               Diff.Hex.Adapter.request(:get, base <> "/a", %{}, :undefined, %{})
    end

    test "returns too_many_redirects after exceeding limit", %{bypass: bypass, base: base} do
      Bypass.expect(bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("location", "#{base}#{conn.request_path}")
        |> Plug.Conn.resp(302, "")
      end)

      assert {:error, :too_many_redirects} =
               Diff.Hex.Adapter.request(:get, base <> "/loop", %{}, :undefined, %{})
    end
  end

  describe "request_to_file/6" do
    test "streams 200 body to file", %{bypass: bypass, base: base} do
      filename =
        Path.join(System.tmp_dir!(), "adapter_test_#{System.unique_integer([:positive])}.bin")

      on_exit(fn -> File.rm(filename) end)

      Bypass.expect_once(bypass, "GET", "/tar", fn conn ->
        Plug.Conn.resp(conn, 200, "tarball-bytes")
      end)

      assert {:ok, {200, _headers}} =
               Diff.Hex.Adapter.request_to_file(:get, base <> "/tar", %{}, :undefined, filename, %{})

      assert File.read!(filename) == "tarball-bytes"
    end

    test "does not write file on non-200 status", %{bypass: bypass, base: base} do
      filename =
        Path.join(System.tmp_dir!(), "adapter_test_#{System.unique_integer([:positive])}.bin")

      on_exit(fn -> File.rm(filename) end)

      Bypass.expect_once(bypass, "GET", "/tar", fn conn ->
        Plug.Conn.resp(conn, 404, "missing")
      end)

      assert {:ok, {404, _headers}} =
               Diff.Hex.Adapter.request_to_file(:get, base <> "/tar", %{}, :undefined, filename, %{})

      refute File.exists?(filename)
    end

    test "follows redirect then streams to file", %{bypass: bypass, base: base} do
      filename =
        Path.join(System.tmp_dir!(), "adapter_test_#{System.unique_integer([:positive])}.bin")

      on_exit(fn -> File.rm(filename) end)

      Bypass.expect(bypass, fn
        %{request_path: "/r"} = conn ->
          conn |> Plug.Conn.put_resp_header("location", "/t") |> Plug.Conn.resp(302, "")

        %{request_path: "/t"} = conn ->
          Plug.Conn.resp(conn, 200, "after-redirect")
      end)

      assert {:ok, {200, _headers}} =
               Diff.Hex.Adapter.request_to_file(:get, base <> "/r", %{}, :undefined, filename, %{})

      assert File.read!(filename) == "after-redirect"
    end
  end
end
