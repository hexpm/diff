defmodule DiffWeb.IntegrationTest do
  use DiffWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mox

  describe "route integration tests" do
    setup :verify_on_exit!

    test "root route renders search page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ ~s(class="search-input")
      assert html =~ "Search..."
    end

    test "/diffs route with query parameters", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/diffs?diffs[]=phoenix:1.4.5:1.4.9")

      assert html =~ "Package Diffs"
      assert html =~ "phoenix"
      assert html =~ "1.4.5 → 1.4.9"
    end

    test "/diff with implicit latest version resolution", %{conn: conn} do
      versions = ["1.4.5", "1.4.9", "1.5.0-rc.2"]

      Diff.Package.StoreMock
      |> stub(:get_versions, fn "phoenix" -> {:ok, versions} end)

      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)

      Diff.HexMock
      |> stub(:diff, fn "phoenix", "1.4.5", "1.4.9" -> :error end)

      {:ok, _view, html} = live(conn, "/diff/phoenix/1.4.5..")

      # Should show generating state since we're resolving to latest version
      assert html =~ "Generating diffs"
    end

    test "/diff with implicit latest handles packages without stable versions", %{conn: conn} do
      Diff.Package.StoreMock
      |> stub(:get_versions, fn "prerelease_only" ->
        {:ok, ["1.0.0-alpha.1", "1.0.0-rc.1", "1.0.0-rc.2"]}
      end)

      Diff.StorageMock
      |> stub(:get_metadata, fn "prerelease_only", "0.1.0", "1.0.0-rc.2" ->
        {:error, :not_found}
      end)

      Diff.HexMock
      |> stub(:diff, fn "prerelease_only", "0.1.0", "1.0.0-rc.2" -> :error end)

      {:ok, _view, html} = live(conn, "/diff/prerelease_only/0.1.0..")

      assert html =~ "Generating diffs"
    end

    test "/diff with implicit latest handles packages with an empty version list", %{conn: conn} do
      Diff.Package.StoreMock
      |> stub(:get_versions, fn "empty" -> {:ok, []} end)

      {:ok, _view, html} = live(conn, "/diff/empty/0.1.0..")

      assert html =~ "No versions found for package: empty"
    end

    test "/diff handles package not found", %{conn: conn} do
      Diff.Package.StoreMock
      |> stub(:get_versions, fn "nonexistent" -> {:error, :not_found} end)

      Diff.StorageMock
      |> stub(:get_metadata, fn "nonexistent", "1.0.0", "2.0.0" ->
        {:error, :not_found}
      end)

      Diff.HexMock
      |> stub(:diff, fn "nonexistent", "1.0.0", "2.0.0" -> :error end)

      {:ok, _view, html} = live(conn, "/diff/nonexistent/1.0.0..2.0.0")

      assert html =~ "Generating diffs"
    end
  end
end
