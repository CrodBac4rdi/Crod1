defmodule CROD.Neural.Neuron do
  @moduledoc """
  Individual neuron process that communicates via N2O
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    # Subscribe to neural network via N2O
    CROD.Core.MessageBus.subscribe({:neuron, opts[:id]}, self())
    
    {:ok, %{
      id: opts[:id],
      prime: opts[:prime],
      activation: 0.0,
      threshold: 0.7,
      connections: [],
      fire_count: 0
    }}
  end

  @impl true
  def handle_info({:n2o, {:fire, strength}}, state) do
    new_activation = min(1.0, state.activation + strength)
    
    if new_activation >= state.threshold do
      # Neuron fires!
      propagate_signal(state.connections, new_activation)
      
      # Notify consciousness via N2O
      CROD.Core.MessageBus.publish(:neural_fire, %{
        neuron_id: state.id,
        strength: new_activation,
        prime: state.prime
      })
      
      {:noreply, %{state | 
        activation: 0.0, 
        fire_count: state.fire_count + 1
      }}
    else
      {:noreply, %{state | activation: new_activation}}
    end
  end

  @impl true
  def handle_info({:n2o, {:connect, target_id}}, state) do
    {:noreply, %{state | connections: [target_id | state.connections]}}
  end

  # Private functions

  defp propagate_signal(connections, strength) do
    Enum.each(connections, fn target_id ->
      CROD.Core.MessageBus.publish({:neuron, target_id}, {:fire, strength * 0.8})
    end)
  end
end