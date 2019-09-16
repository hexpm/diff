defmodule Diff.Package.Supervisor do
  use Supervisor

  alias Diff.Package.{Store, Updater}

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], [])
  end

  @impl true
  def init(_opts) do
    children = [
      {Store, []},
      {Updater, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
