defmodule CrodNeural.MixProject do
  use Mix.Project

  def project do
    [
      app: :crod_neural,
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
      mod: {CROD.Neural.Application, []}
    ]
  end

  defp deps do
    [
      {:crod_core, in_umbrella: true},
      {:libgraph, "~> 0.16"}
    ]
  end
end