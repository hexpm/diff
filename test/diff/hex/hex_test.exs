defmodule Diff.HexTest do
  use ExUnit.Case, async: true

  setup do
    metadata = %{"name" => "foo", "version" => "0.1.0"}

    foo = """
    foo 1
    bar 2
    baz 3
    """

    bar = """
    defmodule Foo do
      defstruct bar: nil
    end
    """

    files = [{'foo', foo}, {'bar', bar}]
    {:ok, %{tarball: tarball}} = :hex_tarball.create(metadata, files)
    path = "tmp/diff-test"
    File.mkdir_p!(path)

    on_exit(fn ->
      File.rm_rf!(path)
    end)

    %{tarball: tarball, files: files, path: path}
  end

  describe "unpack_tarball" do
    test "by default upacks all files", context do
      %{tarball: tarball, files: files, path: path} = context
      :ok = Diff.Hex.unpack_tarball(tarball, path)

      actual =
        path
        |> File.ls!()
        |> MapSet.new()

      expected =
        files
        |> Enum.map(fn {name, _content} -> to_string(name) end)
        |> MapSet.new()

      assert MapSet.subset?(expected, actual)
    end

    test "unpacks only files listed in the second argument", context do
      %{tarball: tarball, path: path} = context
      :ok = Diff.Hex.unpack_tarball(tarball, ["foo"], path)

      actual =
        path
        |> File.ls!()
        |> MapSet.new()

      assert MapSet.member?(actual, "foo")
      refute MapSet.member?(actual, "bar")
    end
  end
end
