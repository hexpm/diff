defmodule DiffWeb.PageControllerTest do
  use DiffWeb.ConnCase
  import Mox

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end

  describe "GET /diff/:package/:versions" do
    setup :verify_on_exit!

    test "does not accept implicit from", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/%20..")
      assert html_response(conn, 400) =~ "Bad request"
    end

    test "accepts implicit to", %{conn: conn} do
      versions = ["1.4.5", "1.4.9", "1.5.0-rc.2"]
      diff = "p403n1xd1ff"

      expect(Diff.Package.StoreMock, :get_versions, fn "phoenix" -> {:ok, versions} end)
      expect(Diff.StorageMock, :get, fn "phoenix", "1.4.5", "1.4.9" -> {:ok, [diff]} end)

      conn = get(conn, "diff/phoenix/1.4.5")
      assert html_response(conn, 200) =~ diff
    end
  end

  describe "GET /diffs" do
    setup :verify_on_exit!

    test "does not accept an empty list of diffs", %{conn: conn} do
      conn = get(conn, "/diffs")
      assert html_response(conn, 400) =~ "Bad request"
    end

    test "shows all diffs in list", %{conn: conn} do
      diff = "/diff/phoenix/1.4.5..1.4.9"
      conn = get(conn, "diffs?diffs[]=phoenix:1.4.5:1.4.9")
      assert html_response(conn, 200) =~ diff
    end
  end

  describe "/GET /diff/:package/:versions/expand/:from/:to/:right_line" do
    setup :verify_on_exit!

    test "requires file_name query param", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/1/1/1")
      assert %{"error" => "missing query parameter: file_name"} = json_response(conn, 400)
    end

    test "doesn't accept when to_line is less than from_line", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/2/1/1?file_name=mix.exs")
      assert json_response(conn, 400)
    end

    test "returns chunk of the file", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/1/4/1?file_name=mix.exs")
      assert %{"chunk" => chunk} = json_response(conn, 200)
      assert chunk =~ "defmodule Phoenix.MixProject do"
    end
  end
end
