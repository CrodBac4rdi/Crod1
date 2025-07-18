defmodule CROD.Neural.Application do
  @moduledoc """
  Neural layer application - manages neurons, memory, and consciousness
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Pattern loader
      {CROD.Neural.Patterns, name: CROD.Neural.Patterns},
      
      # Memory system
      {CROD.Neural.Memory, name: CROD.Neural.Memory},
      
      # Consciousness monitor
      {CROD.Neural.Consciousness, name: CROD.Neural.Consciousness},
      
      # Neuron supervisor
      {DynamicSupervisor, name: CROD.Neural.NeuronSupervisor, strategy: :one_for_one},
      
      # Brain orchestrator
      {CROD.Neural.Brain, name: CROD.Neural.Brain},
      
      # N2O handler
      {CROD.Neural.Handler, name: CROD.Neural.Handler}
    ]

    opts = [strategy: :one_for_one, name: CROD.Neural.Supervisor]
    Supervisor.start_link(children, opts)
  end
end