defmodule Diff.Hex.Adapter do
  @behaviour :hex_http

  @opts [follow_redirect: true, max_redirect: 5]

  @impl true
  def request(method, uri, req_headers, req_body, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    req_headers = prepare_headers(req_headers, content_type)
    resp = :hackney.request(method, uri, req_headers, payload, @opts)

    with {:ok, status, resp_headers, client_ref} <- resp,
         {:ok, resp_body} <- :hackney.body(client_ref) do
      resp_headers = Map.new(resp_headers)
      {:ok, {status, resp_headers, resp_body}}
    end
  end

  @impl true
  def request_to_file(method, uri, req_headers, req_body, filename, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    req_headers = prepare_headers(req_headers, content_type)

    case :hackney.request(method, uri, req_headers, payload, @opts) do
      {:ok, 200, resp_headers, ref} ->
        resp_headers = Map.new(resp_headers)

        case File.open(filename, [:write, :binary], &stream_body_to_file(ref, &1)) do
          {:ok, :ok} -> {:ok, {200, resp_headers}}
          {:ok, {:error, _} = error} -> error
          {:error, reason} -> {:error, reason}
        end

      {:ok, status, resp_headers, ref} ->
        :hackney.skip_body(ref)
        resp_headers = Map.new(resp_headers)
        {:ok, {status, resp_headers}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stream_body_to_file(ref, file) do
    case :hackney.stream_body(ref) do
      {:ok, data} ->
        :ok = IO.binwrite(file, data)
        stream_body_to_file(ref, file)

      :done ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_headers(req_headers, content_type) do
    if content_type do
      req_headers
      |> Map.put("content-type", content_type)
    else
      req_headers
    end
    |> Enum.to_list()
  end

  defp deconstruct_body(:undefined), do: {nil, ""}
  defp deconstruct_body(body), do: body
end
