defmodule CrodAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :crod_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CROD.API.Application, []}
    ]
  end

  defp deps do
    [
      {:crod_core, in_umbrella: true},
      {:plug_cowboy, "~> 2.6"},
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.4"},
      
      # Optional framework dependencies
      # Uncomment as needed:
      # {:rig, github: "Accenture/rig"},
      # {:sugar, "~> 0.5"},
      # {:ash, "~> 3.0"}
    ]
  end
end