defmodule DiffWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DiffWeb.ConnCase
      alias DiffWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint DiffWeb.Endpoint
    end
  end

  @doc """
  Retries `fun` every `interval_ms` until it passes or `timeout_ms` is exhausted.
  Raises the last assertion error if the timeout is reached.
  """
  def assert_eventually(fun, timeout_ms \\ 1000, interval_ms \\ 50) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_assert_eventually(fun, deadline, interval_ms)
  end

  defp do_assert_eventually(fun, deadline, interval_ms) do
    fun.()
  rescue
    e in ExUnit.AssertionError ->
      if System.monotonic_time(:millisecond) < deadline do
        Process.sleep(interval_ms)
        do_assert_eventually(fun, deadline, interval_ms)
      else
        reraise e, __STACKTRACE__
      end
  end

  setup _tags do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_private(:phoenix_router, DiffWeb.Router)
      |> Plug.Conn.put_private(:phoenix_endpoint, DiffWeb.Endpoint)
      |> Phoenix.ConnTest.init_test_session(%{})

    {:ok, conn: conn}
  end
end
