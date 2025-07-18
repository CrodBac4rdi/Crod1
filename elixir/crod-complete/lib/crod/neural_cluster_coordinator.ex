defmodule Crod.NeuralClusterCoordinator do
  @moduledoc """
  Coordinates between neural clusters and manages cluster-to-cluster communication.
  Handles load balancing, inter-cluster messaging, and cluster health monitoring.
  """
  use GenServer
  require Logger

  @cluster_count 5
  @health_check_interval 5000  # 5 seconds

  defstruct [
    :clusters,
    :cluster_health,
    :message_queue,
    :load_stats,
    :last_health_check
  ]

  # Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_cluster_status do
    GenServer.call(__MODULE__, :get_cluster_status)
  end

  def send_inter_cluster_message(from_cluster, to_cluster, message) do
    GenServer.cast(__MODULE__, {:inter_cluster_message, from_cluster, to_cluster, message})
  end

  def balance_clusters do
    GenServer.call(__MODULE__, :balance_clusters)
  end

  def get_optimal_cluster_for_task(task_type) do
    GenServer.call(__MODULE__, {:get_optimal_cluster, task_type})
  end

  # Callbacks

  @impl true
  def init(_) do
    Logger.info("🧠 Starting NeuralClusterCoordinator")
    
    # Schedule periodic health checks
    Process.send_after(self(), :health_check, @health_check_interval)
    
    state = %__MODULE__{
      clusters: %{},
      cluster_health: %{},
      message_queue: [],
      load_stats: %{},
      last_health_check: DateTime.utc_now()
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call(:get_cluster_status, _from, state) do
    status = %{
      clusters: state.clusters,
      health: state.cluster_health,
      load_stats: state.load_stats,
      last_health_check: state.last_health_check,
      message_queue_size: length(state.message_queue)
    }
    
    {:reply, status, state}
  end

  @impl true
  def handle_call(:balance_clusters, _from, state) do
    Logger.info("⚖️ Balancing neural clusters")
    
    # Get current load statistics
    load_stats = collect_load_statistics()
    
    # Identify overloaded and underloaded clusters
    {overloaded, underloaded} = identify_load_imbalance(load_stats)
    
    # Perform load balancing
    balance_result = perform_cluster_balancing(overloaded, underloaded)
    
    new_state = %{state | load_stats: load_stats}
    
    {:reply, balance_result, new_state}
  end

  @impl true
  def handle_call({:get_optimal_cluster, task_type}, _from, state) do
    optimal_cluster = find_optimal_cluster(task_type, state.cluster_health, state.load_stats)
    {:reply, optimal_cluster, state}
  end

  @impl true
  def handle_cast({:inter_cluster_message, from_cluster, to_cluster, message}, state) do
    Logger.debug("📨 Inter-cluster message: #{from_cluster} -> #{to_cluster}")
    
    # Add message to queue
    new_message = %{
      from: from_cluster,
      to: to_cluster,
      message: message,
      timestamp: DateTime.utc_now()
    }
    
    new_queue = [new_message | state.message_queue] |> Enum.take(1000)  # Keep last 1000 messages
    
    # Process the message
    process_inter_cluster_message(new_message)
    
    {:noreply, %{state | message_queue: new_queue}}
  end

  @impl true
  def handle_info(:health_check, state) do
    Logger.debug("🏥 Performing cluster health check")
    
    # Check health of all clusters
    cluster_health = perform_health_check()
    
    # Update cluster registry
    clusters = update_cluster_registry(cluster_health)
    
    # Schedule next health check
    Process.send_after(self(), :health_check, @health_check_interval)
    
    new_state = %{state | 
      cluster_health: cluster_health,
      clusters: clusters,
      last_health_check: DateTime.utc_now()
    }
    
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:process_message_queue, state) do
    # Process pending inter-cluster messages
    {processed, remaining} = Enum.split(state.message_queue, 10)  # Process 10 messages at a time
    
    Enum.each(processed, &process_inter_cluster_message/1)
    
    if length(remaining) > 0 do
      Process.send_after(self(), :process_message_queue, 100)
    end
    
    {:noreply, %{state | message_queue: remaining}}
  end

  # Private functions

  defp perform_health_check do
    1..@cluster_count
    |> Enum.map(fn cluster_id ->
      health = check_cluster_health(cluster_id)
      {cluster_id, health}
    end)
    |> Map.new()
  end

  defp check_cluster_health(cluster_id) do
    try do
      # Get cluster neurons
      neurons = get_cluster_neurons(cluster_id)
      total_neurons = length(neurons)
      
      # Check neuron responsiveness
      healthy_neurons = neurons
      |> Enum.count(fn pid ->
        case Process.alive?(pid) do
          true -> 
            case GenServer.call(pid, :get_state, 1000) do
              %{} -> true
              _ -> false
            end
          false -> false
        end
      end)
      
      # Calculate metrics
      health_percentage = if total_neurons > 0, do: (healthy_neurons / total_neurons * 100), else: 0
      
      %{
        cluster_id: cluster_id,
        total_neurons: total_neurons,
        healthy_neurons: healthy_neurons,
        health_percentage: health_percentage,
        status: if(health_percentage > 80, do: :healthy, else: :degraded),
        last_check: DateTime.utc_now()
      }
    rescue
      e ->
        Logger.error("❌ Health check failed for cluster #{cluster_id}: #{inspect(e)}")
        %{
          cluster_id: cluster_id,
          status: :error,
          error: inspect(e),
          last_check: DateTime.utc_now()
        }
    end
  end

  defp get_cluster_neurons(_cluster_id) do
    # This would interface with the actual neuron supervisor
    # For now, return empty list
    []
  end

  defp collect_load_statistics do
    1..@cluster_count
    |> Enum.map(fn cluster_id ->
      load = calculate_cluster_load(cluster_id)
      {cluster_id, load}
    end)
    |> Map.new()
  end

  defp calculate_cluster_load(cluster_id) do
    # Calculate CPU usage, memory usage, active connections, etc.
    %{
      cluster_id: cluster_id,
      cpu_usage: :rand.uniform() * 100,  # Mock data
      memory_usage: :rand.uniform() * 100,
      active_connections: :rand.uniform(1000),
      processing_queue_size: :rand.uniform(100)
    }
  end

  defp identify_load_imbalance(load_stats) do
    total_cpu = load_stats |> Map.values() |> Enum.map(& &1.cpu_usage) |> Enum.sum()
    avg_cpu = total_cpu / @cluster_count
    
    overloaded = load_stats
    |> Enum.filter(fn {_id, stats} -> stats.cpu_usage > avg_cpu * 1.3 end)
    |> Enum.map(&elem(&1, 0))
    
    underloaded = load_stats
    |> Enum.filter(fn {_id, stats} -> stats.cpu_usage < avg_cpu * 0.7 end)
    |> Enum.map(&elem(&1, 0))
    
    {overloaded, underloaded}
  end

  defp perform_cluster_balancing(overloaded, underloaded) do
    Logger.info("⚖️ Balancing: #{length(overloaded)} overloaded, #{length(underloaded)} underloaded")
    
    # For now, just log the balancing action
    # In real implementation, this would migrate neurons or adjust resources
    
    %{
      overloaded_clusters: overloaded,
      underloaded_clusters: underloaded,
      actions_taken: [],
      timestamp: DateTime.utc_now()
    }
  end

  defp find_optimal_cluster(task_type, cluster_health, load_stats) do
    # Find cluster with best health and lowest load for the task type
    best_cluster = 1..@cluster_count
    |> Enum.map(fn cluster_id ->
      health = Map.get(cluster_health, cluster_id, %{health_percentage: 0})
      load = Map.get(load_stats, cluster_id, %{cpu_usage: 100})
      
      # Calculate suitability score
      suitability = calculate_cluster_suitability(cluster_id, task_type, health, load)
      
      {cluster_id, suitability}
    end)
    |> Enum.max_by(&elem(&1, 1))
    |> elem(0)
    
    Logger.debug("🎯 Optimal cluster for #{task_type}: #{best_cluster}")
    best_cluster
  end

  defp calculate_cluster_suitability(cluster_id, task_type, health, load) do
    # Base suitability on health and load
    health_score = Map.get(health, :health_percentage, 0)
    load_score = 100 - Map.get(load, :cpu_usage, 100)
    
    # Adjust based on task type
    task_modifier = case task_type do
      :pattern_matching -> if cluster_id <= 2, do: 1.2, else: 1.0
      :memory_processing -> if cluster_id in [3, 4], do: 1.2, else: 1.0
      :neural_computation -> if cluster_id == 5, do: 1.2, else: 1.0
      _ -> 1.0
    end
    
    (health_score * 0.6 + load_score * 0.4) * task_modifier
  end

  defp process_inter_cluster_message(message) do
    Logger.debug("📬 Processing message: #{inspect(message)}")
    
    # Route message to appropriate cluster
    # In real implementation, this would send the message to the target cluster
    
    # For now, just log the message processing
    Logger.debug("📨 Message processed: #{message.from} -> #{message.to}")
  end

  defp update_cluster_registry(cluster_health) do
    # Update the registry of active clusters
    cluster_health
    |> Enum.map(fn {cluster_id, health} ->
      {cluster_id, %{
        id: cluster_id,
        status: Map.get(health, :status, :unknown),
        last_updated: DateTime.utc_now(),
        health_percentage: Map.get(health, :health_percentage, 0)
      }}
    end)
    |> Map.new()
  end
end