defmodule CrodN2O.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        crod: [
          applications: [
            crod_core: :permanent,
            crod_neural: :permanent,
            crod_api: :permanent,
            crod_ui: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      # Core N2O dependency
      {:n2o, "~> 11.9"},
      {:nitro, "~> 9.9"},
      
      # Development tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end