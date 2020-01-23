defmodule Diff.MixProject do
  use Mix.Project

  def project do
    [
      app: :diff,
      version: "0.1.0",
      elixir: "~> 1.5",
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
      {:phoenix, "~> 1.4.10"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:goth, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_live_view, "~> 0.5"},
      {:hex_core, "~> 0.6.1"},
      {:rollbax, "~> 0.11.0"},
      {:logster, "~> 1.0"},
      {:git_diff, "~> 0.6"},
      {:hackney, "~> 1.15"},
      {:floki, "~> 0.24.0"},
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
      setup: ["deps.get", &setup_npm/1]
    ]
  end

  defp setup_npm(_) do
    cmd("npm", ["install"], cd: "assets")
  end

  defp cmd(cmd, args, opts) do
    opts = Keyword.merge([into: IO.stream(:stdio, :line), stderr_to_stdout: true], opts)
    {_, result} = System.cmd(cmd, args, opts)

    if result != 0 do
      raise "Non-zero result (#{result}) from: #{cmd} #{Enum.map_join(args, " ", &inspect/1)}"
    end
  end
end
