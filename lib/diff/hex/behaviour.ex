defmodule Diff.Hex.Behaviour do
  @callback diff(package :: String.t(), from :: String.t(), to :: String.t()) ::
              {:ok, Enumerable.t()} | :error
end
