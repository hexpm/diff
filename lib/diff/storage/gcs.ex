defmodule Diff.Storage.GCS do
  require Logger

  @behaviour Diff.Storage

  @gs_xml_url "https://storage.googleapis.com"

  def get_diff(package, from_version, to_version, diff_id, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         url = url(diff_key(package, from_version, to_version, hash, diff_id)),
         {:ok, 200, _headers, body} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.get(url, headers()) end) do
      {:ok, body}
    else
      {:ok, 404, _headers, _body} ->
        {:error, :not_found}

      {:ok, status, _headers, _body} ->
        Logger.error("Failed to get diff from storage. Status #{status}")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get diff from storage. Reason #{inspect(reason)}")
        {:error, :not_found}
    end
  end

  def put_diff(package, from_version, to_version, diff_id, diff_data, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         url = url(diff_key(package, from_version, to_version, hash, diff_id)),
         {:ok, 200, _headers, _body} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.put(url, headers(), diff_data) end) do
      :ok
    else
      {:ok, status, _headers, _body} ->
        Logger.error("Failed to put diff to storage. Status #{status}")
        {:error, :storage_error}

      error ->
        Logger.error("Failed to put diff to storage. Reason #{inspect(error)}")
        error
    end
  end

  def list_diffs(package, from_version, to_version, opts \\ []) do
    case get_metadata(package, from_version, to_version, opts) do
      {:ok, %{total_diffs: total_diffs}} ->
        diff_ids = diff_ids(total_diffs)
        {:ok, diff_ids}

      {:error, :not_found} ->
        {:ok, []}

      error ->
        error
    end
  end

  def get_metadata(package, from_version, to_version, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         url = url(metadata_key(package, from_version, to_version, hash)),
         {:ok, 200, _headers, body} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.get(url, headers()) end) do
      case Jason.decode(body, keys: :atoms) do
        {:ok, metadata} -> {:ok, metadata}
        {:error, _} -> {:error, :invalid_metadata}
      end
    else
      {:ok, 404, _headers, _body} ->
        {:error, :not_found}

      {:ok, status, _headers, _body} ->
        Logger.error("Failed to get metadata from storage. Status #{status}")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get metadata from storage. Reason #{inspect(reason)}")
        {:error, :not_found}
    end
  end

  def put_metadata(package, from_version, to_version, metadata, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         url = url(metadata_key(package, from_version, to_version, hash)),
         {:ok, json} <- Jason.encode(metadata),
         {:ok, 200, _headers, _body} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.put(url, headers(), json) end) do
      :ok
    else
      {:ok, status, _headers, _body} ->
        Logger.error("Failed to put metadata to storage. Status #{status}")
        {:error, :storage_error}

      {:error, %Jason.EncodeError{}} ->
        Logger.error("Failed to encode metadata as JSON")
        {:error, :invalid_metadata}

      error ->
        Logger.error("Failed to put metadata to storage. Reason #{inspect(error)}")
        error
    end
  end

  defp headers() do
    token = Goth.fetch!(Diff.Goth)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  def combined_checksum(package, from, to, opts \\ []) do
    with {:ok, checksums} <- Diff.Hex.get_checksums(package, [from, to]) do
      {:ok, :erlang.phash2(Diff.Storage.cache_key(checksums, opts))}
    end
  end

  defp diff_ids(0), do: []

  defp diff_ids(total_diffs) do
    0..(total_diffs - 1) |> Enum.map(&"diff-#{&1}")
  end

  defp diff_key(package, from_version, to_version, hash, diff_id) do
    "diffs/#{package}-#{from_version}-#{to_version}-#{hash}-#{diff_id}.json"
  end

  defp metadata_key(package, from_version, to_version, hash) do
    "metadata/#{package}-#{from_version}-#{to_version}-#{hash}.json"
  end

  defp url(key) do
    "#{@gs_xml_url}/#{bucket()}/#{key}"
  end

  defp bucket() do
    Application.get_env(:diff, :bucket)
  end
end
