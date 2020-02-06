defmodule Diff.Storage do
  @type package :: String.t()
  @type from_version :: String.t()
  @type to_version :: String.t()
  @type diff :: Enum.t()

  @callback get(package, from_version, to_version) :: {:ok, diff} | {:error, term}
  @callback put(package, from_version, to_version, diff) :: :ok | {:error, term}

  defp impl(), do: Application.get_env(:diff, :storage_impl)

  def get(package, from_version, to_version) do
    impl().get(package, from_version, to_version)
  end

  def put(package, from_version, to_version, diff) do
    impl().put(package, from_version, to_version, diff)
  end
end
