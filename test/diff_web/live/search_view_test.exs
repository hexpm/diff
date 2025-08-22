defmodule DiffWeb.SearchLiveViewTest do
  use DiffWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mox

  describe "search view" do
    setup :verify_on_exit!

    test "connected mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ ~s(class="search-input")
    end

    test "searching for packages that don't exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      Diff.Package.StoreMock
      |> expect(:get_names, fn -> ["phoenix"] end)
      |> expect(:get_versions, fn _key -> {:error, :not_found} end)
      |> allow(self(), view.pid)

      send(view.pid, {:search, "p"})
      rendered = render(view)
      refute rendered =~ ~s(<select name="from")
      refute rendered =~ ~s(<select name="to")

      refute rendered =~
               ~s(<button class="diff-button" type="button" phx-click="go">Diff</button>)

      assert rendered =~ ~s(Did you mean:)
      assert rendered =~ ~s(Package p not found.)
    end

    test "searching for packages that do exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      Diff.Package.StoreMock
      |> expect(:get_names, fn -> ["phoenix", "phoenix_live_view"] end)
      |> expect(:get_versions, fn "phoenix" -> {:ok, ["1.4.10", "1.4.11"]} end)
      |> allow(self(), view.pid)

      send(view.pid, {:search, "phoenix"})
      rendered = render(view)
      assert rendered =~ ~s(<select name="from")
      assert rendered =~ ~s(<option selected="" value="1.4.10">1.4.10</option>)
      assert rendered =~ ~s(<select name="to")
      assert rendered =~ ~s(<option selected="" value="1.4.11">1.4.11</option>)
      assert rendered =~ ~s(Did you mean:)

      assert rendered =~
               ~s(<button class="diff-button" type="button" phx-click="go">Diff</button>)

      refute rendered =~ ~s(Package phoenix not found.)
    end

    test "clicking diff", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      Diff.Package.StoreMock
      |> expect(:get_names, fn -> ["phoenix"] end)
      |> expect(:get_versions, fn "phoenix" -> {:ok, ["1.4.10", "1.4.11"]} end)
      |> allow(self(), view.pid)

      send(view.pid, {:search, "phoenix"})

      assert render_click(view, "go", %{result: "phoenix", to: "1.4.11", from: "1.4.10"}) ==
               {:error, {:redirect, %{to: "/diff/phoenix/1.4.10..1.4.11", status: 302}}}
    end

    test "no duplicates for suggestions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      Diff.Package.StoreMock
      |> expect(:get_names, fn -> ["html_sanitize_ex"] end)
      |> expect(:get_versions, fn
        "html_sanitize_ex" -> {:ok, ["1.4.0"]}
        "html_sa" -> {:error, :not_found}
      end)
      |> allow(self(), view.pid)

      send(view.pid, {:search, "html_sa"})
      rendered = render(view)
      assert [_] = :binary.matches(rendered, "html_sanitize_ex</span>")
    end
  end
end
