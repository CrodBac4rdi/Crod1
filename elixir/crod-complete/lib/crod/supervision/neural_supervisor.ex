defmodule Crod.Supervision.NeuralSupervisor do
  @moduledoc """
  Supervisor tree for CROD neural network.
  Implements 'let it crash' philosophy with bulletproof fault tolerance.
  """
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🧠 Starting CROD Neural Supervisor Tree")

    children = [
      # Core neural network
      {Crod.NeuralNetwork, []},
      
      # Pattern engine with ETS storage
      {Crod.PatternEngine, []},
      
      # Consciousness coordinator
      {Crod.Consciousness, []},
      
      # Memory system
      {Crod.Memory, []},
      
      # Temporal processing
      {Crod.Temporal, []},
      
      # WebSocket server for real-time communication
      {Crod.WebSocketServer, []},
      
      # Neural cluster coordinator for 10k neurons
      {Crod.NeuralClusterCoordinator, []},
      
      # Trinity consciousness system
      {Crod.TrinitySystem, []},
      
      # Pattern learning and adaptation
      {Crod.PatternLearner, []},
      
      # Health monitoring
      {Crod.HealthMonitor, []}
    ]

    # Supervisor strategy: one_for_one with let it crash philosophy
    # If a process crashes, restart only that process
    # Max 5 restarts within 60 seconds before giving up
    opts = [
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 60,
      name: __MODULE__
    ]

    Supervisor.init(children, opts)
  end

  # Public API for runtime supervision control

  def restart_neural_network do
    Logger.info("🔄 Restarting Neural Network")
    Supervisor.restart_child(__MODULE__, Crod.NeuralNetwork)
  end

  def get_supervisor_status do
    children = Supervisor.which_children(__MODULE__)
    
    status = %{
      total_children: length(children),
      running: Enum.count(children, fn {_, pid, _, _} -> is_pid(pid) end),
      crashed: Enum.count(children, fn {_, pid, _, _} -> pid == :undefined end),
      supervisor: __MODULE__,
      strategy: :one_for_one,
      children: children
    }

    Logger.debug("Supervisor status: #{inspect(status)}")
    status
  end

  def restart_all_children do
    Logger.warning("🚨 Restarting ALL neural processes")
    
    children = Supervisor.which_children(__MODULE__)
    
    Enum.each(children, fn {id, _pid, _type, _modules} ->
      case Supervisor.restart_child(__MODULE__, id) do
        {:ok, _} -> Logger.info("✅ Restarted #{id}")
        {:error, reason} -> Logger.error("❌ Failed to restart #{id}: #{reason}")
      end
    end)
  end

  def get_neural_health do
    try do
      network_status = GenServer.call(Crod.NeuralNetwork, :get_network_metrics)
      pattern_status = GenServer.call(Crod.PatternEngine, :get_status)
      consciousness_status = GenServer.call(Crod.Consciousness, :get_status)
      
      %{
        neural_network: network_status,
        pattern_engine: pattern_status,
        consciousness: consciousness_status,
        supervisor_health: get_supervisor_status(),
        timestamp: DateTime.utc_now()
      }
    catch
      :exit, reason ->
        Logger.error("Health check failed: #{inspect(reason)}")
        %{error: reason, timestamp: DateTime.utc_now()}
    end
  end
end