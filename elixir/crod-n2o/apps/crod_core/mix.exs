defmodule CrodCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :crod_core,
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
      extra_applications: [:logger, :n2o],
      mod: {CROD.Core.Application, []}
    ]
  end

  defp deps do
    [
      {:n2o, "~> 11.9"},
      {:cowboy, "~> 2.10"},
      {:jason, "~> 1.4"}
    ]
  end
end