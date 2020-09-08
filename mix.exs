defmodule Diff.MixProject do
  use Mix.Project

  def project do
    [
      app: :diff,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      {:phoenix, "~> 1.5.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:goth, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.1"},
      {:phoenix_live_view, "~> 0.6"},
      {:hex_core, "~> 0.6.1"},
      {:rollbax, "~> 0.11.0"},
      {:logster, "~> 1.0"},
      {:git_diff, github: "hexpm/git_diff", branch: "emj/stream"},
      {:hackney, "~> 1.15"},
      {:floki, "~> 0.28.0"},
      {:mox, "~> 0.5.1", only: :test}
    ]
  end

  defp releases() do
    [
      diff: [
        include_executables_for: [:unix]
      ]
    ]
  end

  defp aliases() do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end
end
