defmodule DiffWeb.DiffComponentTest do
  use ExUnit.Case, async: true

  alias DiffWeb.DiffComponent

  defp render_component(diff, diff_id) do
    assigns = %{diff: diff, diff_id: diff_id}

    assigns
    |> DiffComponent.render()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp line(opts \\ []) do
    %GitDiff.Line{
      type: Keyword.get(opts, :type, :context),
      from_line_number: Keyword.get(opts, :from, 1),
      to_line_number: Keyword.get(opts, :to, 1),
      text: Keyword.get(opts, :text, " context line")
    }
  end

  defp chunk(lines) do
    %GitDiff.Chunk{
      header: "@@ -1,3 +1,3 @@",
      lines: lines
    }
  end

  describe "render/1" do
    test "changed file" do
      diff = %GitDiff.Patch{
        from: "lib/app.ex",
        to: "lib/app.ex",
        chunks: [chunk([line()])]
      }

      html = render_component(diff, "diff-0")

      assert html =~ "changed"
      assert html =~ "lib/app.ex"
      assert html =~ "diff-0-body"
    end

    test "added file" do
      diff = %GitDiff.Patch{
        from: nil,
        to: "lib/new.ex",
        chunks: [chunk([line(type: :add, from: "", to: 1, text: "+new line")])]
      }

      html = render_component(diff, "diff-1")

      assert html =~ "added"
      assert html =~ "lib/new.ex"
      assert html =~ "diff-1-body"
    end

    test "removed file" do
      diff = %GitDiff.Patch{
        from: "lib/old.ex",
        to: nil,
        chunks: [chunk([line(type: :remove, from: 1, to: "", text: "-old line")])]
      }

      html = render_component(diff, "diff-2")

      assert html =~ "removed"
      assert html =~ "lib/old.ex"
      assert html =~ "diff-2-body"
    end

    test "renamed file" do
      diff = %GitDiff.Patch{
        from: "lib/old_name.ex",
        to: "lib/new_name.ex",
        chunks: [chunk([line()])]
      }

      html = render_component(diff, "diff-3")

      assert html =~ "renamed"
      assert html =~ "lib/old_name.ex -&gt; lib/new_name.ex"
      assert html =~ "diff-3-body"
    end

    test "includes toggle icon and phx-click" do
      diff = %GitDiff.Patch{
        from: "lib/app.ex",
        to: "lib/app.ex",
        chunks: [chunk([line()])]
      }

      html = render_component(diff, "diff-0")

      assert html =~ "<svg"
      assert html =~ "phx-click"
    end

    test "renders multiple chunks and lines" do
      lines = [
        line(type: :context, from: 1, to: 1, text: " unchanged"),
        line(type: :remove, from: 2, to: "", text: "-removed"),
        line(type: :add, from: "", to: 2, text: "+added")
      ]

      diff = %GitDiff.Patch{
        from: "lib/app.ex",
        to: "lib/app.ex",
        chunks: [chunk(lines), chunk([line(from: 10, to: 10)])]
      }

      html = render_component(diff, "diff-0")

      assert html =~ "unchanged"
      assert html =~ "removed"
      assert html =~ "added"
    end
  end
end
