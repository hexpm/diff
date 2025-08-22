defmodule DiffWeb.DiffLiveViewTest do
  use DiffWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mox
  import ExUnit.CaptureLog

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

  describe "DiffLiveView diff generation" do
    test "successfully generates and processes diffs in parallel", %{conn: conn} do
      # Setup mock stream data that simulates parallel processing
      mock_stream = [
        {:ok,
         {"diff --git a/lib/app.ex b/lib/app.ex\n--- a/lib/app.ex\n+++ b/lib/app.ex\n@@ -1,3 +1,4 @@\n+# New line\n defmodule App do",
          "/tmp/from", "/tmp/to"}},
        {:ok,
         {"diff --git a/lib/config.ex b/lib/config.ex\n--- a/lib/config.ex\n+++ b/lib/config.ex\n@@ -5,2 +5,3 @@\n-  old_config: true\n+  new_config: false\n+  extra_config: :value",
          "/tmp/from", "/tmp/to"}},
        {:too_large, "very_large_file.txt"}
      ]

      # Mock Diff.Hex to return our test stream
      Diff.HexMock
      |> expect(:diff, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, mock_stream}
      end)

      # Mock storage operations for parallel processing
      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)
      |> expect(:put_diff, 3, fn "phoenix", "1.4.5", "1.4.9", diff_id, data ->
        # Verify diff data structure
        assert diff_id =~ ~r/diff-\d+/
        decoded = Jason.decode!(data)
        assert is_map(decoded)
        :ok
      end)
      |> expect(:put_metadata, fn "phoenix", "1.4.5", "1.4.9", metadata ->
        # Verify aggregated metadata from parallel processing
        assert metadata.total_diffs == 3
        assert metadata.files_changed == 3
        assert metadata.total_additions > 0
        assert metadata.total_deletions > 0
        :ok
      end)
      |> stub(:list_diffs, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, ["diff-0", "diff-1", "diff-2"]}
      end)
      |> stub(:get_diff, fn "phoenix", "1.4.5", "1.4.9", _diff_id ->
        {:ok,
         Jason.encode!(%{
           "diff" => "test diff",
           "path_from" => "/tmp/from",
           "path_to" => "/tmp/to"
         })}
      end)

      capture_log(fn ->
        {:ok, view, _html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

        # Wait for generation and loading to complete
        :timer.sleep(200)
        final_html = render(view)

        # Should show the metadata from parallel processing
        assert final_html =~ "3 files changed"
        # additions
        assert final_html =~ "+3"
        # deletions
        assert final_html =~ "-1"
      end)
    end

    test "handles errors in parallel diff processing", %{conn: conn} do
      # Mock stream with some errors
      mock_stream = [
        {:ok, {"diff content", "/tmp/from", "/tmp/to"}},
        {:error, {:git_diff, "git command failed"}},
        {:too_large, "large_file.bin"}
      ]

      Diff.HexMock
      |> expect(:diff, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, mock_stream}
      end)

      # Mock storage - only successful elements should be stored
      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)
      |> expect(:put_diff, 2, fn "phoenix", "1.4.5", "1.4.9", _diff_id, _data ->
        :ok
      end)
      |> expect(:put_metadata, fn "phoenix", "1.4.5", "1.4.9", metadata ->
        # Only 2 diffs should be stored (error one skipped)
        assert metadata.total_diffs == 2
        assert metadata.files_changed == 2
        :ok
      end)
      |> stub(:list_diffs, fn "phoenix", "1.4.5", "1.4.9" ->
        # Skip error element
        {:ok, ["diff-0", "diff-2"]}
      end)
      |> stub(:get_diff, fn "phoenix", "1.4.5", "1.4.9", _diff_id ->
        {:ok,
         Jason.encode!(%{
           "diff" => "test diff",
           "path_from" => "/tmp/from",
           "path_to" => "/tmp/to"
         })}
      end)

      capture_log(fn ->
        {:ok, view, _html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

        :timer.sleep(200)
        final_html = render(view)

        # Should still succeed with partial results
        # Only successful files
        assert final_html =~ "2 files changed"
      end)
    end

    test "handles hex diff failure", %{conn: conn} do
      Diff.HexMock
      |> expect(:diff, fn "phoenix", "1.4.5", "1.4.9" ->
        :error
      end)

      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)

      {:ok, view, _html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

      :timer.sleep(100)
      final_html = render(view)

      assert final_html =~ "Failed to generate diff"
    end

    test "handles storage failure during parallel processing", %{conn: conn} do
      mock_stream = [
        {:ok, {"diff content", "/tmp/from", "/tmp/to"}}
      ]

      Diff.HexMock
      |> expect(:diff, fn "phoenix", "1.4.5", "1.4.9" ->
        {:ok, mock_stream}
      end)

      Diff.StorageMock
      |> stub(:get_metadata, fn "phoenix", "1.4.5", "1.4.9" ->
        {:error, :not_found}
      end)
      |> expect(:put_diff, fn "phoenix", "1.4.5", "1.4.9", _diff_id, _data ->
        {:error, :storage_failed}
      end)
      |> expect(:put_metadata, fn "phoenix", "1.4.5", "1.4.9", metadata ->
        # Should still try to store metadata even with failed individual diffs
        # No successful diffs
        assert metadata.total_diffs == 0
        :ok
      end)

      capture_log(fn ->
        {:ok, view, _html} = live(conn, "/diff/phoenix/1.4.5..1.4.9")

        :timer.sleep(100)
        final_html = render(view)

        # Should handle storage failures gracefully
        refute final_html =~ "Failed to generate diff"
      end)
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
