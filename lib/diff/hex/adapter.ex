defmodule Diff.Hex.Adapter do
  @behaviour :hex_http

  @max_redirects 5
  @redirect_statuses [301, 302, 303, 307, 308]

  @impl true
  def request(method, uri, req_headers, req_body, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    headers = prepare_headers(req_headers, content_type)
    do_request(method, to_string(uri), headers, payload, @max_redirects)
  end

  @impl true
  def request_to_file(method, uri, req_headers, req_body, filename, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    headers = prepare_headers(req_headers, content_type)
    do_request_to_file(method, to_string(uri), headers, payload, filename, @max_redirects)
  end

  defp do_request(_method, _uri, _headers, _body, 0), do: {:error, :too_many_redirects}

  defp do_request(method, uri, headers, body, redirects_left) do
    req = Finch.build(method, uri, headers, body)

    case Finch.request(req, Diff.Finch) do
      {:ok, %Finch.Response{status: status, headers: resp_headers}}
      when status in @redirect_statuses ->
        case follow(status, method, body, uri, resp_headers, redirects_left) do
          {:follow, m, u, b, left} -> do_request(m, u, headers, b, left)
          :no_location -> {:ok, {status, Map.new(resp_headers), <<>>}}
        end

      {:ok, %Finch.Response{status: status, headers: resp_headers, body: resp_body}} ->
        {:ok, {status, Map.new(resp_headers), resp_body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp do_request_to_file(_m, _u, _h, _b, _f, 0), do: {:error, :too_many_redirects}

  defp do_request_to_file(method, uri, headers, body, filename, redirects_left) do
    req = Finch.build(method, uri, headers, body)
    acc = %{status: nil, headers: [], file: nil}

    case Finch.stream(req, Diff.Finch, acc, &stream_collect(&1, &2, filename)) do
      {:ok, %{status: status, headers: resp_headers, file: file}}
      when status in @redirect_statuses ->
        if file, do: File.close(file)

        case follow(status, method, body, uri, resp_headers, redirects_left) do
          {:follow, m, u, b, left} -> do_request_to_file(m, u, headers, b, filename, left)
          :no_location -> {:ok, {status, Map.new(resp_headers)}}
        end

      {:ok, %{status: status, headers: resp_headers, file: file}} ->
        if file, do: File.close(file)
        {:ok, {status, Map.new(resp_headers)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stream_collect({:status, status}, acc, _filename), do: %{acc | status: status}
  defp stream_collect({:headers, hs}, acc, _filename), do: %{acc | headers: hs}

  defp stream_collect({:data, _chunk}, %{status: status} = acc, _filename)
       when status in @redirect_statuses,
       do: acc

  defp stream_collect({:data, chunk}, %{status: 200, file: nil} = acc, filename) do
    {:ok, file} = File.open(filename, [:write, :binary])
    :ok = IO.binwrite(file, chunk)
    %{acc | file: file}
  end

  defp stream_collect({:data, chunk}, %{status: 200, file: file} = acc, _filename) do
    :ok = IO.binwrite(file, chunk)
    acc
  end

  defp stream_collect({:data, _chunk}, acc, _filename), do: acc

  defp follow(status, method, body, original_uri, resp_headers, redirects_left) do
    case find_header(resp_headers, "location") do
      nil ->
        :no_location

      location ->
        {new_method, new_body} = if status == 303, do: {:get, ""}, else: {method, body}
        new_uri = resolve_uri(location, original_uri)
        {:follow, new_method, new_uri, new_body, redirects_left - 1}
    end
  end

  defp find_header(headers, name) do
    case Enum.find(headers, fn {k, _v} -> String.downcase(k) == name end) do
      {_, value} -> value
      nil -> nil
    end
  end

  defp resolve_uri("http://" <> _ = absolute, _original), do: absolute
  defp resolve_uri("https://" <> _ = absolute, _original), do: absolute

  defp resolve_uri(relative, original) do
    original |> URI.parse() |> URI.merge(relative) |> to_string()
  end

  defp prepare_headers(req_headers, content_type) do
    if content_type do
      Map.put(req_headers, "content-type", content_type)
    else
      req_headers
    end
    |> Enum.to_list()
  end

  defp deconstruct_body(:undefined), do: {nil, ""}
  defp deconstruct_body(body), do: body
end
