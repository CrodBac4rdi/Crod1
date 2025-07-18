defmodule Crod.NeuronSupervisor do
  @moduledoc """
  Supervision tree for managing 10,000 neurons with fault tolerance,
  automatic restart, and dynamic management capabilities.
  """
  
  use Supervisor
  require Logger
  
  alias Crod.{Neuron, NeuronRegistry}
  
  @neuron_count 10_000
  @supervisor_strategy :one_for_one
  @max_restarts 100
  @max_seconds 60
  @partition_size 100  # Neurons per partition supervisor
  
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    Logger.info("🧠 Initializing Neuron Supervisor for #{@neuron_count} neurons")
    
    # Create partition supervisors for better fault isolation
    partition_count = div(@neuron_count, @partition_size)
    
    children = [
      # Neuron Registry for fast lookups
      {NeuronRegistry, name: NeuronRegistry},
      
      # Neuron Statistics Collector
      {Crod.NeuronStats, name: Crod.NeuronStats},
      
      # Dynamic Supervisor for hot-swappable neurons
      {DynamicSupervisor, name: Crod.DynamicNeuronSupervisor, strategy: :one_for_one}
    ] ++ build_partition_supervisors(partition_count, opts)
    
    Supervisor.init(children, strategy: @supervisor_strategy,
                             max_restarts: @max_restarts,
                             max_seconds: @max_seconds)
  end
  
  # Public API
  
  def restart_neuron(neuron_id) do
    case find_neuron_supervisor(neuron_id) do
      {:ok, supervisor_pid} ->
        restart_child_neuron(supervisor_pid, neuron_id)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  def add_neuron(neuron_spec) do
    DynamicSupervisor.start_child(
      Crod.DynamicNeuronSupervisor,
      {Neuron, neuron_spec}
    )
  end
  
  def remove_neuron(neuron_id) do
    case NeuronRegistry.lookup(neuron_id) do
      {:ok, pid} ->
        DynamicSupervisor.terminate_child(Crod.DynamicNeuronSupervisor, pid)
      error ->
        error
    end
  end
  
  def get_neuron_status(neuron_id) do
    case NeuronRegistry.lookup(neuron_id) do
      {:ok, pid} ->
        if Process.alive?(pid) do
          {:ok, :alive, get_neuron_info(pid)}
        else
          {:ok, :dead, nil}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end
  
  def get_supervisor_status do
    %{
      total_neurons: @neuron_count,
      alive_neurons: count_alive_neurons(),
      partition_status: get_partition_status(),
      restart_stats: get_restart_statistics(),
      memory_usage: get_memory_usage()
    }
  end
  
  # Private Functions
  
  defp build_partition_supervisors(partition_count, opts) do
    Enum.map(0..(partition_count - 1), fn partition_id ->
      Supervisor.child_spec(
        {Crod.NeuronPartitionSupervisor, [
          partition_id: partition_id,
          neuron_range: calculate_neuron_range(partition_id),
          opts: opts
        ]},
        id: {:partition_supervisor, partition_id}
      )
    end)
  end
  
  defp calculate_neuron_range(partition_id) do
    start_id = partition_id * @partition_size + 1
    end_id = min((partition_id + 1) * @partition_size, @neuron_count)
    {start_id, end_id}
  end
  
  defp find_neuron_supervisor(neuron_id) do
    partition_id = div(neuron_id - 1, @partition_size)
    
    # Get partition supervisor
    case Registry.lookup(Crod.Registry, {:partition_supervisor, partition_id}) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :supervisor_not_found}
    end
  end
  
  defp restart_child_neuron(supervisor_pid, neuron_id) do
    # Find and restart specific neuron
    children = Supervisor.which_children(supervisor_pid)
    
    case Enum.find(children, fn {id, _, _, _} -> id == neuron_id end) do
      {^neuron_id, pid, _, _} when is_pid(pid) ->
        Supervisor.terminate_child(supervisor_pid, neuron_id)
        Supervisor.restart_child(supervisor_pid, neuron_id)
      _ ->
        {:error, :neuron_not_found}
    end
  end
  
  defp get_neuron_info(pid) do
    try do
      Neuron.get_state(pid)
    catch
      :exit, _ -> nil
    end
  end
  
  defp count_alive_neurons do
    NeuronRegistry.count_alive()
  end
  
  defp get_partition_status do
    # Get status of each partition
    0..(div(@neuron_count, @partition_size) - 1)
    |> Enum.map(fn partition_id ->
      case Registry.lookup(Crod.Registry, {:partition_supervisor, partition_id}) do
        [{pid, _}] ->
          children = Supervisor.which_children(pid)
          alive_count = Enum.count(children, fn {_, child_pid, _, _} -> 
            is_pid(child_pid) and Process.alive?(child_pid)
          end)
          
          %{
            partition_id: partition_id,
            status: :running,
            alive_neurons: alive_count,
            total_neurons: length(children)
          }
        [] ->
          %{
            partition_id: partition_id,
            status: :down,
            alive_neurons: 0,
            total_neurons: 0
          }
      end
    end)
  end
  
  defp get_restart_statistics do
    # Would track restart counts in production
    %{
      total_restarts: 0,
      restarts_last_minute: 0,
      restarts_last_hour: 0
    }
  end
  
  defp get_memory_usage do
    # Calculate memory used by neurons
    self_info = Process.info(self(), :memory)
    
    # Get memory for all child processes
    total_memory = NeuronRegistry.all_neurons()
    |> Enum.map(fn {_id, pid} ->
      case Process.info(pid, :memory) do
        {:memory, mem} -> mem
        nil -> 0
      end
    end)
    |> Enum.sum()
    
    %{
      supervisor_memory: self_info[:memory],
      neurons_memory: total_memory,
      total_memory: self_info[:memory] + total_memory,
      average_per_neuron: div(total_memory, max(count_alive_neurons(), 1))
    }
  end
end

defmodule Crod.NeuronPartitionSupervisor do
  @moduledoc """
  Supervisor for a partition of neurons, providing fault isolation
  """
  
  use Supervisor
  require Logger
  
  def start_link(args) do
    partition_id = Keyword.fetch!(args, :partition_id)
    Supervisor.start_link(__MODULE__, args, name: via_tuple(partition_id))
  end
  
  @impl true
  def init(args) do
    partition_id = Keyword.fetch!(args, :partition_id)
    {start_id, end_id} = Keyword.fetch!(args, :neuron_range)
    opts = Keyword.get(args, :opts, [])
    
    Logger.info("🧩 Starting partition supervisor #{partition_id} for neurons #{start_id}-#{end_id}")
    
    # Register in registry
    Registry.register(Crod.Registry, {:partition_supervisor, partition_id}, nil)
    
    # Create neurons for this partition
    children = Enum.map(start_id..end_id, fn neuron_id ->
      prime = get_nth_prime(neuron_id)
      
      neuron_spec = %{
        id: neuron_id,
        prime: prime,
        connections: generate_connections(neuron_id, prime),
        special: is_special_neuron?(prime)
      }
      
      Supervisor.child_spec(
        {Crod.Neuron, Keyword.merge([neuron_spec: neuron_spec], opts)},
        id: neuron_id
      )
    end)
    
    Supervisor.init(children, 
      strategy: :one_for_one,
      max_restarts: 50,
      max_seconds: 60
    )
  end
  
  defp via_tuple(partition_id) do
    {:via, Registry, {Crod.Registry, {:partition_supervisor, partition_id}}}
  end
  
  defp get_nth_prime(n) do
    # Use pre-calculated primes for performance
    primes = Crod.PrimeCalculator.get_primes(10_000)
    Enum.at(primes, n - 1)
  end
  
  defp generate_connections(neuron_id, prime) do
    # Generate connections based on prime factorization patterns
    :rand.seed(:exsss, {prime, neuron_id, 42})
    
    connection_count = rem(prime, 7) + 3
    
    1..connection_count
    |> Enum.map(fn _ ->
      target = :rand.uniform(10_000)
      if target != neuron_id, do: target, else: rem(target + 1, 10_000) + 1
    end)
    |> Enum.uniq()
  end
  
  defp is_special_neuron?(prime) do
    prime in [2, 3, 5, 17, 67, 71]  # Trinity and special primes
  end
end

defmodule Crod.NeuronRegistry do
  @moduledoc """
  Registry for fast neuron lookups and tracking
  """
  
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def register(neuron_id, pid) do
    GenServer.call(__MODULE__, {:register, neuron_id, pid})
  end
  
  def unregister(neuron_id) do
    GenServer.cast(__MODULE__, {:unregister, neuron_id})
  end
  
  def lookup(neuron_id) do
    case :ets.lookup(:neuron_registry, neuron_id) do
      [{^neuron_id, pid}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end
  
  def all_neurons do
    :ets.tab2list(:neuron_registry)
  end
  
  def count_alive do
    all_neurons()
    |> Enum.count(fn {_id, pid} -> Process.alive?(pid) end)
  end
  
  # GenServer callbacks
  
  def init(_opts) do
    # Create ETS table for fast lookups
    :ets.new(:neuron_registry, [:named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end
  
  def handle_call({:register, neuron_id, pid}, _from, state) do
    Process.monitor(pid)
    :ets.insert(:neuron_registry, {neuron_id, pid})
    {:reply, :ok, Map.put(state, pid, neuron_id)}
  end
  
  def handle_cast({:unregister, neuron_id}, state) do
    :ets.delete(:neuron_registry, neuron_id)
    {:noreply, state}
  end
  
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Clean up when neuron dies
    case Map.get(state, pid) do
      nil -> 
        {:noreply, state}
      neuron_id ->
        :ets.delete(:neuron_registry, neuron_id)
        {:noreply, Map.delete(state, pid)}
    end
  end
end

defmodule Crod.NeuronStats do
  @moduledoc """
  Collects and aggregates statistics about neuron behavior
  """
  
  use GenServer
  
  defstruct [
    :activation_counts,
    :restart_counts,
    :error_counts,
    :performance_metrics
  ]
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def record_activation(neuron_id) do
    GenServer.cast(__MODULE__, {:record_activation, neuron_id})
  end
  
  def record_restart(neuron_id, reason) do
    GenServer.cast(__MODULE__, {:record_restart, neuron_id, reason})
  end
  
  def record_error(neuron_id, error) do
    GenServer.cast(__MODULE__, {:record_error, neuron_id, error})
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def get_neuron_stats(neuron_id) do
    GenServer.call(__MODULE__, {:get_neuron_stats, neuron_id})
  end
  
  # GenServer callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      activation_counts: %{},
      restart_counts: %{},
      error_counts: %{},
      performance_metrics: %{}
    }
    
    # Schedule periodic cleanup
    :timer.send_interval(60_000, self(), :cleanup_old_stats)
    
    {:ok, state}
  end
  
  def handle_cast({:record_activation, neuron_id}, state) do
    new_state = update_in(state.activation_counts[neuron_id], &((&1 || 0) + 1))
    {:noreply, new_state}
  end
  
  def handle_cast({:record_restart, neuron_id, reason}, state) do
    timestamp = DateTime.utc_now()
    
    new_state = update_in(state.restart_counts[neuron_id], fn restarts ->
      restarts = restarts || []
      [{timestamp, reason} | restarts] |> Enum.take(100)
    end)
    
    {:noreply, new_state}
  end
  
  def handle_cast({:record_error, neuron_id, error}, state) do
    timestamp = DateTime.utc_now()
    
    new_state = update_in(state.error_counts[neuron_id], fn errors ->
      errors = errors || []
      [{timestamp, error} | errors] |> Enum.take(50)
    end)
    
    {:noreply, new_state}
  end
  
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_activations: state.activation_counts |> Map.values() |> Enum.sum(),
      total_restarts: state.restart_counts |> Map.values() |> Enum.map(&length/1) |> Enum.sum(),
      total_errors: state.error_counts |> Map.values() |> Enum.map(&length/1) |> Enum.sum(),
      most_active_neurons: get_most_active(state.activation_counts, 10),
      most_restarted_neurons: get_most_restarted(state.restart_counts, 10),
      error_prone_neurons: get_error_prone(state.error_counts, 10)
    }
    
    {:reply, stats, state}
  end
  
  def handle_call({:get_neuron_stats, neuron_id}, _from, state) do
    stats = %{
      activations: Map.get(state.activation_counts, neuron_id, 0),
      restarts: length(Map.get(state.restart_counts, neuron_id, [])),
      errors: length(Map.get(state.error_counts, neuron_id, [])),
      recent_restarts: Enum.take(Map.get(state.restart_counts, neuron_id, []), 5),
      recent_errors: Enum.take(Map.get(state.error_counts, neuron_id, []), 5)
    }
    
    {:reply, stats, state}
  end
  
  def handle_info(:cleanup_old_stats, state) do
    # Clean up old restart and error records
    cutoff_time = DateTime.add(DateTime.utc_now(), -3600, :second)  # 1 hour ago
    
    new_restart_counts = state.restart_counts
    |> Enum.map(fn {neuron_id, restarts} ->
      filtered = Enum.filter(restarts, fn {timestamp, _} ->
        DateTime.compare(timestamp, cutoff_time) == :gt
      end)
      {neuron_id, filtered}
    end)
    |> Enum.filter(fn {_, restarts} -> length(restarts) > 0 end)
    |> Enum.into(%{})
    
    new_error_counts = state.error_counts
    |> Enum.map(fn {neuron_id, errors} ->
      filtered = Enum.filter(errors, fn {timestamp, _} ->
        DateTime.compare(timestamp, cutoff_time) == :gt
      end)
      {neuron_id, filtered}
    end)
    |> Enum.filter(fn {_, errors} -> length(errors) > 0 end)
    |> Enum.into(%{})
    
    new_state = %{state |
      restart_counts: new_restart_counts,
      error_counts: new_error_counts
    }
    
    {:noreply, new_state}
  end
  
  defp get_most_active(activation_counts, limit) do
    activation_counts
    |> Enum.sort_by(fn {_, count} -> -count end)
    |> Enum.take(limit)
    |> Enum.map(fn {neuron_id, count} -> %{neuron_id: neuron_id, activations: count} end)
  end
  
  defp get_most_restarted(restart_counts, limit) do
    restart_counts
    |> Enum.map(fn {neuron_id, restarts} -> {neuron_id, length(restarts)} end)
    |> Enum.sort_by(fn {_, count} -> -count end)
    |> Enum.take(limit)
    |> Enum.map(fn {neuron_id, count} -> %{neuron_id: neuron_id, restarts: count} end)
  end
  
  defp get_error_prone(error_counts, limit) do
    error_counts
    |> Enum.map(fn {neuron_id, errors} -> {neuron_id, length(errors)} end)
    |> Enum.sort_by(fn {_, count} -> -count end)
    |> Enum.take(limit)
    |> Enum.map(fn {neuron_id, count} -> %{neuron_id: neuron_id, errors: count} end)
  end
end