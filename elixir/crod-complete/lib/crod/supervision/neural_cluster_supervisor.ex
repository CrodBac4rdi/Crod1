defmodule Crod.Supervision.NeuralClusterSupervisor do
  @moduledoc """
  Supervisor for neural clusters - groups of neurons that work together.
  Provides fault tolerance and load balancing for neural processing.
  """
  use Supervisor
  require Logger

  @cluster_size 1000  # Number of neurons per cluster
  @max_clusters 10    # Maximum number of clusters

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("🧠 Starting NeuralClusterSupervisor")
    
    children = [
      # Single neuron supervisor that handles all clusters
      Crod.Supervision.NeuronSupervisor,
      
      # Neural cluster coordinator
      {Crod.NeuralClusterCoordinator, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Start a complete neural cluster with specified number of neurons.
  """
  def start_cluster(cluster_id, neuron_count \\ @cluster_size) do
    Logger.info("🧠 Starting neural cluster #{cluster_id} with #{neuron_count} neurons")
    
    # Generate prime numbers for neurons
    primes = generate_primes(neuron_count)
    
    # Start neurons in this cluster
    neurons = primes
    |> Enum.with_index()
    |> Enum.map(fn {prime, idx} ->
      config = %{
        id: "cluster_#{cluster_id}_neuron_#{idx}",
        prime: prime,
        cluster_id: cluster_id,
        connections: generate_connections(idx, neuron_count)
      }
      
      case Crod.Supervision.NeuronSupervisor.start_neuron(config) do
        {:ok, pid} -> {"cluster_#{cluster_id}_neuron_#{idx}", pid}
        {:error, reason} -> 
          Logger.error("❌ Failed to start neuron in cluster #{cluster_id}: #{inspect(reason)}")
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Map.new()
    
    Logger.info("⚡ Started #{map_size(neurons)} neurons in cluster #{cluster_id}")
    {:ok, neurons}
  end

  @doc """
  Stop a neural cluster.
  """
  def stop_cluster(cluster_id) do
    Logger.info("🔌 Stopping neural cluster #{cluster_id}")
    
    # Find all neurons in this cluster
    cluster_neurons = Crod.Supervision.NeuronSupervisor.list_neurons()
    |> Enum.filter(fn pid ->
      case Crod.Neuron.get_state(pid) do
        %{cluster_id: ^cluster_id} -> true
        _ -> false
      end
    end)
    
    # Stop all neurons in cluster
    Enum.each(cluster_neurons, &Crod.Supervision.NeuronSupervisor.stop_neuron/1)
    
    Logger.info("🔌 Stopped cluster #{cluster_id}")
  end

  @doc """
  Get cluster health status.
  """
  def cluster_health do
    clusters = 1..@max_clusters
    |> Enum.map(fn cluster_id ->
      neurons = get_cluster_neurons(cluster_id)
      neuron_count = length(neurons)
      
      # Check if neurons are responsive
      healthy_neurons = neurons
      |> Enum.count(fn pid ->
        case Process.alive?(pid) do
          true -> 
            case Crod.Neuron.get_state(pid) do
              %{} -> true
              _ -> false
            end
          false -> false
        end
      end)
      
      %{
        cluster_id: cluster_id,
        total_neurons: neuron_count,
        healthy_neurons: healthy_neurons,
        health_percentage: if(neuron_count > 0, do: (healthy_neurons / neuron_count * 100), else: 0)
      }
    end)
    
    %{
      clusters: clusters,
      total_clusters: @max_clusters,
      overall_health: calculate_overall_health(clusters)
    }
  end

  @doc """
  Balance load across clusters.
  """
  def balance_load do
    Logger.info("⚖️ Balancing load across neural clusters")
    
    # Get cluster statistics
    cluster_stats = 1..@max_clusters
    |> Enum.map(fn cluster_id ->
      neurons = get_cluster_neurons(cluster_id)
      {cluster_id, length(neurons)}
    end)
    
    # Find overloaded and underloaded clusters
    total_load = cluster_stats |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    avg_load = total_load / @max_clusters
    
    overloaded = cluster_stats |> Enum.filter(fn {_id, count} -> count > avg_load * 1.2 end)
    underloaded = cluster_stats |> Enum.filter(fn {_id, count} -> count < avg_load * 0.8 end)
    
    # Migrate neurons from overloaded to underloaded clusters
    perform_load_migration(overloaded, underloaded)
    
    Logger.info("⚖️ Load balancing completed")
  end

  # Private functions

  defp generate_primes(count) do
    Stream.iterate(2, &(&1 + 1))
    |> Stream.filter(&is_prime?/1)
    |> Enum.take(count)
  end

  defp is_prime?(n) when n < 2, do: false
  defp is_prime?(2), do: true
  defp is_prime?(n) do
    sqrt_n = :math.sqrt(n) |> Float.floor() |> trunc()
    !Enum.any?(2..sqrt_n, fn i -> rem(n, i) == 0 end)
  end

  defp generate_connections(idx, total) do
    # Each neuron connects to ~20 others in the same cluster
    for _ <- 1..20 do
      "cluster_#{idx}_neuron_#{:rand.uniform(total) - 1}"
    end
    |> Enum.uniq()
    |> Enum.reject(&(&1 == "cluster_#{idx}_neuron_#{idx}"))
  end

  defp get_cluster_neurons(cluster_id) do
    Crod.Supervision.NeuronSupervisor.list_neurons()
    |> Enum.filter(fn pid ->
      case Crod.Neuron.get_state(pid) do
        %{cluster_id: ^cluster_id} -> true
        _ -> false
      end
    end)
  end

  defp calculate_overall_health(clusters) do
    total_neurons = clusters |> Enum.map(& &1.total_neurons) |> Enum.sum()
    healthy_neurons = clusters |> Enum.map(& &1.healthy_neurons) |> Enum.sum()
    
    if total_neurons > 0 do
      healthy_neurons / total_neurons * 100
    else
      0
    end
  end

  defp perform_load_migration(overloaded, underloaded) do
    # Implementation for migrating neurons between clusters
    # This would involve moving neuron processes and updating their configurations
    Logger.info("🔄 Migrating neurons: #{length(overloaded)} overloaded, #{length(underloaded)} underloaded")
    
    # For now, just log the migration - actual implementation would be more complex
    Enum.each(overloaded, fn {cluster_id, count} ->
      Logger.info("📊 Cluster #{cluster_id} has #{count} neurons (overloaded)")
    end)
    
    Enum.each(underloaded, fn {cluster_id, count} ->
      Logger.info("📊 Cluster #{cluster_id} has #{count} neurons (underloaded)")
    end)
  end
end