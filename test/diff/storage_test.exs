defmodule Diff.StorageTest do
  use ExUnit.Case

  test "cache key keeps default format and separates ignore whitespace diffs" do
    original_cache_version = Application.get_env(:diff, :cache_version)
    Application.put_env(:diff, :cache_version, 2)

    on_exit(fn -> Application.put_env(:diff, :cache_version, original_cache_version) end)

    checksums = ["from-checksum", "to-checksum"]

    assert Diff.Storage.cache_key(checksums, []) == {2, checksums}
    assert Diff.Storage.cache_key(checksums, ignore_whitespace: true) != {2, checksums}
  end
end
