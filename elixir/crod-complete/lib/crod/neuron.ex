defmodule Crod.Neuron do
  @moduledoc """
  Individual neuron in the CROD neural network.
  Each neuron is a GenServer with a prime number identity.
  """
  use GenServer
  require Logger

  defstruct [
    :id,
    :prime,
    :cluster_id,
    :connections,
    :activation,
    :last_signal,
    :activation_history,
    :health_status,
    :start_time
  ]

  # Public API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def activate(pid, signal) do
    GenServer.call(pid, {:activate, signal}, 100)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Callbacks

  @impl true
  def init(config) do
    Logger.debug("⚡ Initializing neuron #{config.id}")
    
    state = %__MODULE__{
      id: config.id,
      prime: config.prime,
      cluster_id: Map.get(config, :cluster_id, :default),
      connections: config.connections || [],
      activation: 0.0,
      last_signal: 0.0,
      activation_history: [],
      health_status: :healthy,
      start_time: DateTime.utc_now()
    }

    # Register neuron in registry
    Registry.register(Crod.NeuronRegistry, config.id, state)

    {:ok, state}
  end

  @impl true
  def handle_call({:activate, signal}, _from, state) do
    # Calculate activation using tanh with prime number
    activation = :math.tanh(signal * state.prime / 100.0)
    # Mangel: Magic Number 100.0 sollte konfigurierbar sein
    # Verbesserung: Konfiguration ergänzen

    # Update history (keep last 10)
    history = [activation | state.activation_history] |> Enum.take(10)

    new_state = %{state |
      activation: activation,
      last_signal: signal,
      activation_history: history
    }
    {:reply, activation, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:health_check, _from, state) do
    health = %{
      id: state.id,
      cluster_id: state.cluster_id,
      health_status: state.health_status,
      uptime: DateTime.diff(DateTime.utc_now(), state.start_time, :second),
      activation_level: state.activation,
      connection_count: length(state.connections),
      last_signal: state.last_signal,
      activation_history_size: length(state.activation_history)
    }
    
    {:reply, health, state}
  end

  @impl true
  def handle_call(:get_cluster_id, _from, state) do
    {:reply, state.cluster_id, state}
  end

  # Hot code reload support
  @impl true
  def code_change(_old_vsn, state, _extra) do
    Logger.info("🔄 Neuron #{state.id} hot reloaded")
    {:ok, state}
  end
end
