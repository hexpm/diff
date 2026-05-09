defmodule Diff.Storage do
  @type package :: String.t()
  @type from_version :: String.t()
  @type to_version :: String.t()
  @type diff_id :: String.t()
  @type diff_html :: String.t()
  @type diff_options :: Keyword.t()
  @type diff_metadata :: %{
          total_diffs: non_neg_integer(),
          total_additions: non_neg_integer(),
          total_deletions: non_neg_integer(),
          files_changed: non_neg_integer()
        }

  # New diff-level storage callbacks
  @callback get_diff(package, from_version, to_version, diff_id) ::
              {:ok, diff_html} | {:error, term}
  @callback get_diff(package, from_version, to_version, diff_id, diff_options) ::
              {:ok, diff_html} | {:error, term}
  @callback put_diff(package, from_version, to_version, diff_id, diff_html) ::
              :ok | {:error, term}
  @callback put_diff(package, from_version, to_version, diff_id, diff_html, diff_options) ::
              :ok | {:error, term}
  @callback list_diffs(package, from_version, to_version) :: {:ok, [diff_id]} | {:error, term}
  @callback list_diffs(package, from_version, to_version, diff_options) ::
              {:ok, [diff_id]} | {:error, term}

  # Metadata storage callbacks
  @callback get_metadata(package, from_version, to_version) ::
              {:ok, diff_metadata} | {:error, term}
  @callback get_metadata(package, from_version, to_version, diff_options) ::
              {:ok, diff_metadata} | {:error, term}
  @callback put_metadata(package, from_version, to_version, diff_metadata) :: :ok | {:error, term}
  @callback put_metadata(package, from_version, to_version, diff_metadata, diff_options) ::
              :ok | {:error, term}

  defp impl(), do: Application.get_env(:diff, :storage_impl)

  def get_diff(package, from_version, to_version, diff_id, opts \\ []) do
    impl().get_diff(package, from_version, to_version, diff_id, opts)
  end

  def put_diff(package, from_version, to_version, diff_id, diff_html, opts \\ []) do
    impl().put_diff(package, from_version, to_version, diff_id, diff_html, opts)
  end

  def list_diffs(package, from_version, to_version, opts \\ []) do
    impl().list_diffs(package, from_version, to_version, opts)
  end

  def get_metadata(package, from_version, to_version, opts \\ []) do
    impl().get_metadata(package, from_version, to_version, opts)
  end

  def put_metadata(package, from_version, to_version, metadata, opts \\ []) do
    impl().put_metadata(package, from_version, to_version, metadata, opts)
  end

  def cache_key(checksums, opts) do
    base_key = {Application.get_env(:diff, :cache_version), checksums}

    case cache_options(opts) do
      [] -> base_key
      options -> {base_key, options}
    end
  end

  defp cache_options(opts) do
    opts
    |> Keyword.take([:ignore_whitespace])
    |> Enum.reject(fn {_key, value} -> value in [false, nil] end)
  end
end
