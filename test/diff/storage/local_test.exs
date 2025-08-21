defmodule Diff.Storage.LocalTest do
  use ExUnit.Case

  alias Diff.Storage.Local

  setup do
    # Use a temporary directory for tests
    tmp_dir = System.tmp_dir!() |> Path.join("diff_test_#{:rand.uniform(10000)}")
    File.mkdir_p!(tmp_dir)

    Application.put_env(:diff, :tmp_dir, tmp_dir)
    Application.put_env(:diff, :cache_version, 1)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    %{tmp_dir: tmp_dir}
  end

  describe "diff storage" do
    test "stores and retrieves diffs", %{tmp_dir: _tmp_dir} do
      diff_html = "<div class='diff-content'>Test diff</div>"

      # Store the diff
      assert :ok = Local.put_diff("phoenix", "1.4.5", "1.4.9", "diff-0", diff_html)

      # Retrieve the diff
      assert {:ok, ^diff_html} = Local.get_diff("phoenix", "1.4.5", "1.4.9", "diff-0")
    end

    test "handles non-existent diffs" do
      assert {:error, :not_found} = Local.get_diff("phoenix", "1.4.5", "1.4.9", "nonexistent")
    end

    test "lists stored diffs" do
      diffs = [
        {"diff-0", "<div>diff 0</div>"},
        {"diff-1", "<div>diff 1</div>"},
        {"diff-2", "<div>diff 2</div>"}
      ]

      # Store diffs
      for {diff_id, content} <- diffs do
        assert :ok = Local.put_diff("phoenix", "1.4.5", "1.4.9", diff_id, content)
      end

      # Store metadata (required for list_diffs to work)
      metadata = %{
        total_diffs: 3,
        total_additions: 10,
        total_deletions: 5,
        files_changed: 3
      }

      assert :ok = Local.put_metadata("phoenix", "1.4.5", "1.4.9", metadata)

      # List diffs
      assert {:ok, diff_ids} = Local.list_diffs("phoenix", "1.4.5", "1.4.9")
      assert Enum.sort(diff_ids) == ["diff-0", "diff-1", "diff-2"]
    end

    test "handles empty diff directory" do
      assert {:ok, []} = Local.list_diffs("phoenix", "1.4.5", "1.4.9")
    end
  end

  describe "metadata storage" do
    test "stores and retrieves metadata" do
      metadata = %{
        total_diffs: 5,
        total_additions: 123,
        total_deletions: 45,
        files_changed: 8
      }

      # Store metadata
      assert :ok = Local.put_metadata("phoenix", "1.4.5", "1.4.9", metadata)

      # Retrieve metadata
      assert {:ok, ^metadata} = Local.get_metadata("phoenix", "1.4.5", "1.4.9")
    end

    test "handles non-existent metadata" do
      assert {:error, :not_found} = Local.get_metadata("phoenix", "1.4.5", "1.4.9")
    end
  end
end
