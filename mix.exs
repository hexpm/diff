defmodule Diff.MixProject do
  use Mix.Project

  def project do
    [
      app: :diff,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Diff.Application, []},
      extra_applications: [:logger, :inets, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:floki, "~> 0.37.0"},
      {:gettext, "~> 0.11"},
      {:git_diff, github: "ericmj/git_diff", branch: "ericmj/fix-modes"},
      {:goth, "~> 1.0"},
      {:hackney, "~> 1.15"},
      {:hex_core, "~> 0.11.0"},
      {:jason, "~> 1.0"},
      {:logster, "~> 1.0.0"},
      {:mox, "~> 1.0", only: :test},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "~> 1.6"},
      {:plug_cowboy, "~> 2.1"},
      {:sentry, "~> 10.8"}
    ]
  end

  defp releases() do
    [
      diff: [
        include_executables_for: [:unix],
        reboot_system_after_config: true
      ]
    ]
  end

  defp aliases() do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end
end
