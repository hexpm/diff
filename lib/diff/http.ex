defmodule Diff.HTTP do
  @max_retry_times 5
  @base_sleep_time 100

  require Logger

  def get(url, headers) do
    req = Finch.build(:get, url, headers)

    case Finch.request(req, Diff.Finch) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def put(url, headers, body) do
    req = Finch.build(:put, url, headers, body)

    case Finch.request(req, Diff.Finch) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, exception} ->
        {:error, exception}
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
    Logger.warning("#{service} API ERROR: #{inspect(reason)}")

    if times + 1 < @max_retry_times do
      sleep = trunc(:math.pow(3, times) * @base_sleep_time)
      :timer.sleep(sleep)
      retry(fun, service, times + 1)
    else
      {:error, reason}
    end
  end
end
