defmodule Diff.Package.Store do
  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    :ets.new(__MODULE__, [:named_table, :public])
    {:ok, []}
  end

  def get_versions(key) do
    case :ets.lookup(__MODULE__, key) do
      [{_key, versions}] -> {:ok, versions}
      _ -> {:error, :not_found}
    end
  end

  def get_names() do
    :ets.select(__MODULE__, [{{:"$1", :_}, [], [:"$1"]}])
  end

  def fill(new_entries) do
    old_entries = :ets.tab2list(__MODULE__)
    changed = new_entries -- old_entries

    for entry <- changed do
      :ets.insert(__MODULE__, entry)
    end
  end
end
