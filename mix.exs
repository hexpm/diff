defmodule Diff.MixProject do
  use Mix.Project

  def project do
    [
      app: :diff,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
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
      extra_applications: [:logger, :runtime_tools]
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
      {:bandit, "~> 1.0"},
      {:bypass, "~> 2.1", only: :test},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:finch, "~> 0.22.0"},
      {:gettext, "~> 1.0"},
      {:git_diff, github: "ericmj/git_diff", branch: "ericmj/fix-modes"},
      {:goth, "~> 1.0"},
      {:hex_core, "~> 0.17.0"},
      {:jason, "~> 1.0"},
      {:logster, "~> 1.1.1"},
      {:makeup, "~> 1.2"},
      {:makeup_eex, "~> 2.0"},
      {:makeup_elixir, "~> 1.0"},
      {:makeup_erlang, "~> 1.0"},
      {:makeup_gleam, "~> 1.0"},
      {:makeup_html, "~> 0.2.0"},
      {:mox, "~> 1.0", only: :test},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "~> 1.6"},
      {:sentry, "~> 13.0"},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},
      {:floki, "~> 0.38.1", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
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
      setup: ["deps.get", "esbuild.install", "tailwind.install"],
      "assets.deploy": [
        "esbuild diff --minify",
        "tailwind default --minify",
        "phx.digest"
      ]
    ]
  end
end
