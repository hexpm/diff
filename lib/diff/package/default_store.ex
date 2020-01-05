defmodule Diff.Package.DefaultStore do
  @store_module Diff.Package.Store
  @behaviour @store_module

  @impl true
  def get_versions(key) do
    case :ets.lookup(@store_module, key) do
      [{_key, versions}] -> {:ok, versions}
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def get_names() do
    :ets.select(@store_module, [{{:"$1", :_}, [], [:"$1"]}])
  end
end
