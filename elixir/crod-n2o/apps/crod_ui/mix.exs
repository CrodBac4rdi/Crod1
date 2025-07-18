defmodule CrodUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :crod_ui,
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
      mod: {CROD.UI.Application, []}
    ]
  end

  defp deps do
    [
      {:crod_core, in_umbrella: true},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:nitro, "~> 9.9"},
      {:n2o, "~> 11.9"}
    ]
  end
end