defmodule DiffWeb.DiffLiveViewTest do
  use DiffWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  describe "DiffLiveView single diff" do
    test "mounts successfully with valid package and versions", %{conn: conn} do
      metadata = %{
        total_diffs: 3,
        total_additions: 45,
        total_deletions: 12,
        files_changed: 8
      }

      diffs_ids = ["diffs-0", "diffs-1", "diffs-2"]

      # Mock diffs content - simplified diff format
      diff_content =
        Jason.encode!(%{
          "diff" =>
            "diff --git a/test.ex b/test.ex\n--- a/test.ex\n+++ b/test.ex\n@@ -1,3 +1,4 @@\n+new line\n old line",
          "path_from" => "/tmp/from",
          "path_to" => "/tmp/to"
        })

      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, metadata}
      end)
      |> stub(:list_diffs, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, diffs_ids}
      end)
      |> stub(:get_diff, fn "phoenix", "1.4.5", "1.4.9", _diff_id ->
        {:ok, diff_content}
      end)

      {:ok, _view, html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

      assert html =~ "phoenix"
      assert html =~ "1.4.5"
      assert html =~ "1.4.9"
      assert html =~ "files changed"
      assert html =~ "8"
      assert html =~ "+45"
      assert html =~ "-12"
    end

    test "shows generating state when metadata not found", %{conn: conn} do
      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)

      {:ok, _view, html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

      # Should show generating state when metadata is not found
      assert html =~ "Generating diffs"
    end

    test "handles invalid version format", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/diff/phoenix/invalid..version..format")
      assert html =~ "Invalid version format"
    end
  end

  describe "DiffLiveView diffs list" do
    test "shows list of diffs", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/diffs?diffs[]=phoenix:1.4.5:1.4.9&diffs[]=plug:1.0.0:1.1.0")

      assert html =~ "Package Diffs"
      assert html =~ "phoenix"
      assert html =~ "1.4.5 → 1.4.9"
      assert html =~ "plug"
      assert html =~ "1.0.0 → 1.1.0"
      assert html =~ "/diff/phoenix/1.4.5..1.4.9"
      assert html =~ "/diff/plug/1.0.0..1.1.0"
    end

    test "handles empty diffs list", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/diffs")
      assert html =~ "No diffs provided"
    end

    test "filters invalid diffs", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/diffs?diffs[]=phoenix:1.4.5:1.4.9&diffs[]=invalid")

      assert html =~ "Package Diffs"
      assert html =~ "phoenix"
      assert html =~ "1.4.5 → 1.4.9"
      refute html =~ "invalid"
    end
  end
end
