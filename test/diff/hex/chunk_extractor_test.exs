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
    %{
      params: %{file_path: path, right_line: 1, from_line: 1, to_line: 2}
    }
  end

  describe "reads raw chunk from the file_path" do
    test "reads first 2 lines down", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | from_line: 1, to_line: 2})
      assert "foo 1\nbar 2\n" = raw
    end

    test "error when file doesn't exist", %{params: params} do
      {:error, %{errors: errors}} = ChunkExtractor.run(%{params | file_path: "non_existent"})
      assert Keyword.get(errors, :system) =~ ~r/non_existent: No such file/
    end

    test "returns from 1 when from_line is negative", %{params: params} do
      {:ok, %{parsed: actual}} =
        ChunkExtractor.run(%{params | from_line: -2, right_line: -2, to_line: 2})

      assert [
               %{from_line_number: 1, to_line_number: 1},
               %{from_line_number: 2, to_line_number: 2}
             ] = actual
    end

    test "error when arguments are not valid", %{params: params} do
      {:error, %{errors: errors}} = ChunkExtractor.run(%{params | from_line: -4, to_line: -3})
      assert Keyword.get(errors, :param) == "from_line parameter must be less than to_line"
    end

    test "reads 2 lines from the middle", %{params: params} do
      {:ok, %{raw: raw}} = ChunkExtractor.run(%{params | from_line: 2, to_line: 4})
      assert "bar 2\nbaz 3\nbaf 4\n" = raw
    end
  end

  describe "parse_chunk" do
    test "parses raw chunk into list of structs", %{params: params} do
      {:ok, %{parsed: actual}} = ChunkExtractor.run(params)
      assert [%{text: " foo 1"}, %{text: " bar 2"}] = actual
    end

    test "sets line_numbers", %{params: params} do
      {:ok, %{parsed: actual}} =
        ChunkExtractor.run(%{params | from_line: 2, right_line: 1, to_line: 3})

      assert [
               %{from_line_number: 2, to_line_number: 1},
               %{from_line_number: 3, to_line_number: 2}
             ] = actual
    end
  end
end
