defmodule Diff.Hex.ChunkExtractorTest do
  use ExUnit.Case, async: true

  alias Diff.Hex.ChunkExtractor

  setup do
    content = """
    foo 1
    bar 2
    baz 3
    baf 4
    """

    path = System.tmp_dir!() |> Path.join("test_file")
    File.write!(path, content)

    on_exit(fn -> File.rm!(path) end)

    # some deafult params
    %{params: %{file_path: path, lines_to_read: 2, from_line: 1, direction: "down"}}
  end

  describe "validates direction" do
    test "down", %{params: params} do
      {:ok, %{errors: errors}} = ChunkExtractor.run(%{params | direction: "down"})
      assert [] = errors
    end

    test "up", %{params: params} do
      {:ok, %{errors: errors}} = ChunkExtractor.run(%{params | direction: "up"})
      assert [] = errors
    end

    test "error when direction is neither up nor down", %{params: params} do
      {:error, %{errors: errors}} = ChunkExtractor.run(%{params | direction: "left"})
      assert "direction must be either \"up\" or \"down\"" = Keyword.get(errors, :direction)
    end
  end

  describe "reads raw chunk from the file_path" do
    test "reads first 2 lines down", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | direction: "down"})
      assert "foo 1\nbar 2\n" = raw
    end

    test "reads first 2 lines up", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | direction: "up", from_line: 2})
      assert "foo 1\nbar 2" = raw
    end

    test "error when file doesn't exist", %{params: params} do
      {:error, %{errors: errors}} = ChunkExtractor.run(%{params | file_path: "non_existent"})
      assert Keyword.get(errors, :system) =~ ~r/non_existent: No such file/
    end

    test "error when arguments are not valid", %{params: params} do
      {:error, %{errors: errors}} = ChunkExtractor.run(%{params | from_line: -1})
      assert Keyword.get(errors, :system) =~ ~r/illegal offset/
    end

    test "reads 2 lines up from the middle", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | direction: "up", from_line: 3})
      assert "bar 2\nbaz 3" = raw
    end

    test "reads 2 lines down from the middle", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | direction: "down", from_line: 2})
      assert "bar 2\nbaz 3\n" = raw
    end
  end

  describe "parse_chunk" do
    test "parses raw chunk into list of structs", %{params: params} do
      {:ok, %{parsed: actual}} = ChunkExtractor.run(params)
      assert [%{line_text: "foo 1"}, %{line_text: "bar 2"}] = actual
    end

    test "sets line_numbers when direction is down", %{params: params} do
      {:ok, %{parsed: actual}} = ChunkExtractor.run(%{params | direction: "down", from_line: 2})
      assert [%{line_number: 2}, %{line_number: 3}] = actual
    end

    test "sets line_numbers when direction is up", %{params: params} do
      {:ok, %{parsed: actual}} = ChunkExtractor.run(%{params | direction: "up", from_line: 3})
      assert [%{line_number: 2}, %{line_number: 3}] = actual
    end
  end
end
