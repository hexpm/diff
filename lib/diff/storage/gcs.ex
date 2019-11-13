defmodule Diff.Storage.GCS do
  @behaviour Diff.Storage

  @gs_xml_url "https://storage.googleapis.com"
  @oauth_scope "https://www.googleapis.com/auth/devstorage.read_write"

  def get(package, from_version, to_version) do
    url = url(key(package, from_version, to_version))

    case Diff.HTTP.retry("gs", fn -> Diff.HTTP.get(url, headers()) end) do
      {:ok, 200, _headers, body} -> {:ok, body}
      {:ok, 404, _headers, _body} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def put(package, from_version, to_version, body) do
    url = url(key(package, from_version, to_version))

    case Diff.HTTP.retry("gs", fn -> Diff.HTTP.put(url, headers(), body) end) do
      {:ok, 200, _headers, _body} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp headers() do
    {:ok, token} = Goth.Token.for_scope(@oauth_scope)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  defp key(package, from_version, to_version) do
    "diffs/#{package}-#{from_version}-#{to_version}.tgz"
  end

  defp url(key) do
    "#{@gs_xml_url}/#{bucket()}/#{key}"
  end

  defp bucket() do
    Application.get_env(:diff, :bucket)
  end
end
