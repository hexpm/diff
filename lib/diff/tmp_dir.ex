defmodule Diff.TmpDir do
  use GenServer

  @table __MODULE__

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def tmp_file(prefix) do
    path = path(prefix)
    File.touch!(path)
    track(path)
    path
  end

  def tmp_dir(prefix) do
    path = path(prefix)
    File.mkdir_p!(path)
    track(path)
    path
  end

  defp path(prefix) do
    random = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join(base_dir(), prefix <> "-" <> random)
  end

  defp base_dir() do
    dir = Path.join(System.tmp_dir!(), "diff")
    File.mkdir_p!(dir)
    dir
  end

  defp track(path) do
    pid = self()
    :ets.insert(@table, {pid, path})
    GenServer.cast(__MODULE__, {:monitor, pid})
  end

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    :ets.new(@table, [:named_table, :duplicate_bag, :public])
    {:ok, %{monitors: MapSet.new()}}
  end

  @impl true
  def handle_cast({:monitor, pid}, state) do
    if pid in state.monitors do
      {:noreply, state}
    else
      Process.monitor(pid)
      {:noreply, %{state | monitors: MapSet.put(state.monitors, pid)}}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    cleanup_pid(pid)
    {:noreply, %{state | monitors: MapSet.delete(state.monitors, pid)}}
  end

  @impl true
  def terminate(_reason, _state) do
    :ets.foldl(
      fn {_pid, path}, :ok ->
        File.rm_rf(path)
        :ok
      end,
      :ok,
      @table
    )
  end

  defp cleanup_pid(pid) do
    entries = :ets.lookup(@table, pid)

    Enum.each(entries, fn {_pid, path} ->
      File.rm_rf(path)
    end)

    :ets.delete(@table, pid)
  end
end
