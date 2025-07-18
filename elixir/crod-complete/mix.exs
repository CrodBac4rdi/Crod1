defmodule Crod.MixProject do
  use Mix.Project

  def project do
    [
      app: :crod,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Crod.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto]
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
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      # Additional dependencies for CROD
      {:websockex, "~> 0.4"},  # For WebSocket connections
      {:uuid, "~> 1.1"},        # For unique IDs
      {:httpoison, "~> 2.0"},   # For HTTP requests (docs fetcher)
      {:quantum, "~> 3.0"},     # For scheduled tasks
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:hermes_mcp, "~> 0.10.5"},  # Model Context Protocol implementation
      
      # Neural Enhancement
      {:nx, "~> 0.7"},
      {:axon, "~> 0.6"},
      # {:exla, "~> 0.7"},  # GPU acceleration (optional) - disabled for Alpine
      
      # Background Processing
      {:oban, "~> 2.17"},
      
      # Advanced Caching
      {:cachex, "~> 3.6"},
      
      # Stream Processing
      {:broadway, "~> 1.0"},
      
      # Event Sourcing (optional for now)
      # {:eventstore, "~> 1.4"},
      # {:commanded, "~> 1.4"},
      
      # GraphQL API (optional for now)
      # {:absinthe, "~> 1.7"},
      # {:absinthe_phoenix, "~> 2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind crod", "esbuild crod"],
      "assets.deploy": [
        "tailwind crod --minify",
        "esbuild crod --minify",
        "phx.digest"
      ]
    ]
  end
end
