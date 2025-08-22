defmodule Diff.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

    # List all child processes to be supervised
    children = [
      goth_spec(),
      {Task.Supervisor, name: Diff.Tasks},
      {Phoenix.PubSub, name: Diff.PubSub},
      Diff.Package.Supervisor,
      DiffWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Diff.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DiffWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def sentry_before_send(%Sentry.Event{original_exception: exception} = event) do
    cond do
      Plug.Exception.status(exception) < 500 -> nil
      Sentry.DefaultEventFilter.exclude_exception?(exception, event.source) -> nil
      true -> event
    end
  end

  if Mix.env() == :prod do
    defp goth_spec() do
      credentials =
        "DIFF_GCP_CREDENTIALS"
        |> System.fetch_env!()
        |> Jason.decode!()

      options = [scope: "https://www.googleapis.com/auth/devstorage.read_write"]
      {Goth, name: Diff.Goth, source: {:service_account, credentials, options}}
    end
  else
    defp goth_spec() do
      {Task, fn -> :ok end}
    end
  end
end
