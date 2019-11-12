defmodule Diff.HTTP do
  @max_retry_times 5
  @base_sleep_time 100

  require Logger

  def get(url, headers) do
    :hackney.get(url, headers)
    |> read_response()
  end

  def put(url, headers, body) do
    :hackney.put(url, headers, body)
    |> read_response()
  end

  defp read_response(result) do
    with {:ok, status, headers, ref} <- result,
         {:ok, body} <- :hackney.body(ref) do
      {:ok, status, headers, body}
    end
  end

  def retry(service, fun) do
    retry(fun, service, 0)
  end

  defp retry(fun, service, times) do
    case fun.() do
      {:ok, status, _headers, _body} when status in 500..599 ->
        do_retry(fun, service, times, "status #{status}")

      {:error, reason} ->
        do_retry(fun, service, times, reason)

      result ->
        result
    end
  end

  defp do_retry(fun, service, times, reason) do
    Logger.warn("#{service} API ERROR: #{inspect(reason)}")

    if times + 1 < @max_retry_times do
      sleep = trunc(:math.pow(3, times) * @base_sleep_time)
      :timer.sleep(sleep)
      retry(fun, service, times + 1)
    else
      {:error, reason}
    end
  end
end
