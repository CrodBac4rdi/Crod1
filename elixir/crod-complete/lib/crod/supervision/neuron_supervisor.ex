defmodule Crod.Supervision.NeuronSupervisor do
  @moduledoc """
  Supervisor for individual neurons in the CROD neural network.
  Handles fault tolerance and restart strategies for neurons.
  """
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("🧠 Starting NeuronSupervisor")
    
    # Dynamic supervisor that can start/stop neurons on demand
    children = [
      {DynamicSupervisor, name: Crod.Supervision.DynamicNeuronSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Start a new neuron with given configuration.
  Returns {:ok, pid} on success, {:error, reason} on failure.
  """
  def start_neuron(config) do
    child_spec = {
      Crod.Neuron,
      config
    }
    
    case DynamicSupervisor.start_child(Crod.Supervision.DynamicNeuronSupervisor, child_spec) do
      {:ok, pid} ->
        Logger.debug("⚡ Started neuron #{config.id} with PID #{inspect(pid)}")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("❌ Failed to start neuron #{config.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Stop a specific neuron by PID.
  """
  def stop_neuron(pid) when is_pid(pid) do
    case DynamicSupervisor.terminate_child(Crod.Supervision.DynamicNeuronSupervisor, pid) do
      :ok ->
        Logger.debug("🔌 Stopped neuron #{inspect(pid)}")
        :ok
      {:error, reason} ->
        Logger.error("❌ Failed to stop neuron #{inspect(pid)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get count of active neurons.
  """
  def active_neuron_count do
    DynamicSupervisor.count_children(Crod.Supervision.DynamicNeuronSupervisor)
  end

  @doc """
  List all active neuron PIDs.
  """
  def list_neurons do
    DynamicSupervisor.which_children(Crod.Supervision.DynamicNeuronSupervisor)
    |> Enum.map(fn {_id, pid, _type, _modules} -> pid end)
  end

  @doc """
  Restart all neurons (graceful restart).
  """
  def restart_all_neurons do
    Logger.info("🔄 Restarting all neurons...")
    
    # Get current neurons
    current_neurons = list_neurons()
    
    # Stop all neurons
    Enum.each(current_neurons, &stop_neuron/1)
    
    # Wait a bit for cleanup
    Process.sleep(100)
    
    Logger.info("🔄 All neurons restarted")
  end

  @doc """
  Health check for neuron supervisor.
  """
  def health_check do
    try do
      count = active_neuron_count()
      %{
        status: :healthy,
        active_neurons: count.active,
        total_workers: count.workers,
        supervisor_pid: self()
      }
    rescue
      e ->
        Logger.error("❌ NeuronSupervisor health check failed: #{inspect(e)}")
        %{
          status: :unhealthy,
          error: inspect(e),
          supervisor_pid: self()
        }
    end
  end
end