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

  describe "/GET /diff/:package/:versions/expand/:from_line/:direction" do
    setup :verify_on_exit!

    test "requires file_name query param", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/1/down")
      assert %{"error" => "missing query parameter: file_name"} = json_response(conn, 400)
    end

    test "doesn't accept direction other that up or down", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/1/left?file_name=mix.exs")
      assert %{"errors" => %{"direction" => error}} = json_response(conn, 400)
      assert error =~ ~r/direction must be either \"up\" or \"down\"/
    end

    test "doesn't accept negative from_line", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/-2/up?file_name=mix.exs")
      assert json_response(conn, 400)
    end

    test "returns chunk of the file", %{conn: conn} do
      conn = get(conn, "/diff/phoenix/1.4.5/expand/2/up?file_name=mix.exs")
      assert %{"chunk" => chunk} = json_response(conn, 200)

      assert [
               %{"line_text" => "defmodule Phoenix.MixProject do"},
               %{"line_text" => "  use Mix.Project"}
             ] = chunk

      assert 2 = length(chunk)
    end
  end
end
