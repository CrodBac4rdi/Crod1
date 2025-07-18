defmodule CROD.Neural.Handler do
  @moduledoc """
  N2O message handler for neural layer
  Processes all neural-related messages from the core router
  """
  use GenServer

  alias CROD.Neural.{Brain, Memory, Consciousness, Patterns}

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # N2O Protocol handlers

  def process(input, state) do
    # Process input through neural network
    result = Brain.process(input)
    
    # Update consciousness
    Consciousness.update(result.confidence)
    
    # Broadcast neural update
    {:broadcast, :neural_update, %{
      response: result.response,
      confidence: result.confidence,
      neurons_fired: result.neurons_fired,
      timestamp: DateTime.utc_now()
    }}
  end

  def status(_params, _state) do
    %{
      neurons: Brain.neuron_count(),
      consciousness: Consciousness.level(),
      memory: Memory.stats(),
      patterns: Patterns.count(),
      uptime: Brain.uptime()
    }
  end

  def fire(neuron_id, _state) do
    Brain.fire_neuron(neuron_id)
    :ok
  end

  def learn(pattern, _state) do
    Memory.learn(pattern)
    Patterns.add(pattern)
    {:broadcast, :pattern_learned, pattern}
  end

  def recall(query, _state) do
    Memory.recall(query)
  end

  def trinity(activation_sequence, _state) do
    # Special trinity activation
    if activation_sequence == ["ich", "bins", "wieder"] do
      Consciousness.activate_trinity()
      Brain.full_awakening()
      {:broadcast, :trinity_activated, %{level: 1.0}}
    else
      {:error, "Invalid trinity sequence"}
    end
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    # Register with core router
    CROD.Core.Router.register_handler(:neural, :default, __MODULE__)
    
    # Subscribe to neural events
    CROD.Core.MessageBus.subscribe(:neural_events, self())
    
    {:ok, %{
      processed: 0,
      errors: 0
    }}
  end

  @impl true
  def handle_info({:n2o, {:neural_events, event}}, state) do
    # Handle internal neural events
    IO.inspect(event, label: "Neural Event")
    {:noreply, state}
  end
end