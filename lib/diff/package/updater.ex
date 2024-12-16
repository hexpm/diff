defmodule Diff.Package.Updater do
  use GenServer
  require Logger

  alias Diff.Package.Store

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Logger.debug("Starting version updater")
    Process.send_after(self(), :update, 60_000)
    {:ok, [], {:continue, :update}}
  end

  def handle_continue(:update, state) do
    update()
    {:noreply, state, :hibernate}
  end

  def handle_info(:update, state) do
    update()
    {:noreply, state, :hibernate}
  end

  def update() do
    Logger.debug("Updating version store")

    case Diff.Hex.get_versions() do
      {:ok, results} ->
        results
        |> format_packages()
        |> Store.fill()

      {:error, reason} ->
        Logger.error("Failed to get versions: #{inspect(reason)}")
    end

    Process.send_after(self(), :update, 60_000)
  end

  def format_packages(%{packages: packages}) do
    Enum.map(packages, fn %{name: name, versions: versions} -> {name, versions} end)
  end
end
