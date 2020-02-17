defmodule Diff.Storage.GCS do
  require Logger

  @behaviour Diff.Storage

  @gs_xml_url "https://storage.googleapis.com"
  @oauth_scope "https://www.googleapis.com/auth/devstorage.read_write"

  def get(package, from_version, to_version) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version),
         url = url(key(package, from_version, to_version, hash)),
         {:ok, 200, _headers, stream} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.get_stream(url, headers()) end) do
      {:ok, stream}
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

  def put(package, from_version, to_version, stream) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version),
         url = url(key(package, from_version, to_version, hash)),
         {:ok, 200, _headers, _body} <-
           Diff.HTTP.retry("gs", fn -> Diff.HTTP.put_stream(url, headers(), stream) end) do
      :ok
    else
      {:ok, status, _headers, _body} ->
        Logger.error("Failed to put diff to storage. Status #{status}")
        {:error, :not_found}

      error ->
        Logger.error("Failed to put diff to storage. Reason #{inspect(error)}")
        error
    end
  end

  defp headers() do
    {:ok, token} = Goth.Token.for_scope(@oauth_scope)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  def combined_checksum(package, from, to) do
    with {:ok, checksums} <- Diff.Hex.get_checksums(package, [from, to]) do
      {:ok, :erlang.phash2({Application.get_env(:diff, :cache_version), checksums})}
    end
  end

  defp key(package, from_version, to_version, hash) do
    "diffs/#{package}-#{from_version}-#{to_version}-#{hash}.html"
  end

  defp url(key) do
    "#{@gs_xml_url}/#{bucket()}/#{key}"
  end

  defp bucket() do
    Application.get_env(:diff, :bucket)
  end
end
