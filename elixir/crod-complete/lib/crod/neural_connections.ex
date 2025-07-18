defmodule Crod.NeuralConnections do
  @moduledoc """
  Advanced Neural Connection System for CROD
  Manages synaptic weights, signal propagation, and connection learning
  Implements Hebbian learning: "neurons that fire together, wire together"
  """
  use GenServer
  require Logger

  # Connection types
  @connection_types [:excitatory, :inhibitory, :modulatory, :trinity]
  @max_connection_strength 10.0
  @min_connection_strength 0.01
  @learning_rate 0.01
  @decay_rate 0.001

  defstruct [
    :connections,        # Map of neuron_id -> [connections]
    :synaptic_weights,   # ETS table for fast weight lookup
    :connection_stats,
    :learning_enabled,
    :hebbian_threshold,
    :total_connections,
    :active_connections,
    :last_update
  ]

  # Connection structure
  defmodule Connection do
    defstruct [
      :from_neuron,
      :to_neuron,
      :weight,
      :type,
      :age,
      :activation_count,
      :last_used,
      :strength_history,
      :is_trinity_connection
    ]
  end

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_connection(from_neuron, to_neuron, initial_weight \\ 1.0, type \\ :excitatory) do
    GenServer.call(__MODULE__, {:create_connection, from_neuron, to_neuron, initial_weight, type})
  end

  def strengthen_connection(from_neuron, to_neuron, amount \\ @learning_rate) do
    GenServer.call(__MODULE__, {:strengthen_connection, from_neuron, to_neuron, amount})
  end

  def weaken_connection(from_neuron, to_neuron, amount \\ @learning_rate) do
    GenServer.call(__MODULE__, {:weaken_connection, from_neuron, to_neuron, amount})
  end

  def propagate_signal(from_neuron, signal_strength) do
    GenServer.call(__MODULE__, {:propagate_signal, from_neuron, signal_strength})
  end

  def get_connections(neuron_id) do
    GenServer.call(__MODULE__, {:get_connections, neuron_id})
  end

  def get_connection_stats do
    GenServer.call(__MODULE__, :get_connection_stats)
  end

  def apply_hebbian_learning(neuron_pairs) do
    GenServer.cast(__MODULE__, {:apply_hebbian_learning, neuron_pairs})
  end

  def create_trinity_connections(trinity_neurons) do
    GenServer.call(__MODULE__, {:create_trinity_connections, trinity_neurons})
  end

  def optimize_connections do
    GenServer.cast(__MODULE__, :optimize_connections)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🔗 Neural Connection System initializing...")

    # Create ETS table for fast synaptic weight lookup
    weights_table = :ets.new(:synaptic_weights, [:set, :public, :named_table, {:read_concurrency, true}])

    state = %__MODULE__{
      connections: %{},
      synaptic_weights: weights_table,
      connection_stats: initialize_stats(),
      learning_enabled: true,
      hebbian_threshold: 0.5,
      total_connections: 0,
      active_connections: 0,
      last_update: DateTime.utc_now()
    }

    # Schedule periodic optimization
    schedule_optimization()

    {:ok, state}
  end

  @impl true
  def handle_call({:create_connection, from_neuron, to_neuron, initial_weight, type}, _from, state) do
    connection_id = generate_connection_id(from_neuron, to_neuron)
    
    connection = %Connection{
      from_neuron: from_neuron,
      to_neuron: to_neuron,
      weight: clamp_weight(initial_weight),
      type: type,
      age: 0,
      activation_count: 0,
      last_used: DateTime.utc_now(),
      strength_history: [initial_weight],
      is_trinity_connection: is_trinity_connection?(from_neuron, to_neuron)
    }

    # Store connection in state
    new_connections = 
      state.connections
      |> Map.update(from_neuron, [connection], fn existing -> [connection | existing] end)

    # Store weight in ETS for fast lookup
    :ets.insert(state.synaptic_weights, {connection_id, connection.weight})

    new_state = %{state |
      connections: new_connections,
      total_connections: state.total_connections + 1,
      last_update: DateTime.utc_now()
    }

    Logger.debug("🔗 Created connection: #{from_neuron} -> #{to_neuron} (weight: #{connection.weight}, type: #{type})")

    {:reply, {:ok, connection}, new_state}
  end

  @impl true
  def handle_call({:strengthen_connection, from_neuron, to_neuron, amount}, _from, state) do
    case find_connection(state, from_neuron, to_neuron) do
      {:ok, connection} ->
        new_weight = clamp_weight(connection.weight + amount)
        updated_connection = %{connection | 
          weight: new_weight,
          activation_count: connection.activation_count + 1,
          last_used: DateTime.utc_now(),
          strength_history: [new_weight | Enum.take(connection.strength_history, 9)]
        }

        new_state = update_connection(state, updated_connection)
        
        {:reply, {:ok, updated_connection}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:weaken_connection, from_neuron, to_neuron, amount}, _from, state) do
    case find_connection(state, from_neuron, to_neuron) do
      {:ok, connection} ->
        new_weight = clamp_weight(connection.weight - amount)
        updated_connection = %{connection | 
          weight: new_weight,
          last_used: DateTime.utc_now(),
          strength_history: [new_weight | Enum.take(connection.strength_history, 9)]
        }

        new_state = update_connection(state, updated_connection)
        
        {:reply, {:ok, updated_connection}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:propagate_signal, from_neuron, signal_strength}, _from, state) do
    connections = Map.get(state.connections, from_neuron, [])
    
    propagation_results = 
      connections
      |> Enum.map(fn connection ->
        propagated_strength = calculate_propagated_signal(connection, signal_strength)
        
        # Update connection usage
        updated_connection = %{connection |
          activation_count: connection.activation_count + 1,
          last_used: DateTime.utc_now()
        }

        {connection.to_neuron, propagated_strength, updated_connection}
      end)

    # Update all connections that were used
    new_state = 
      propagation_results
      |> Enum.reduce(state, fn {_, _, updated_connection}, acc_state ->
        update_connection(acc_state, updated_connection)
      end)

    # Return the signal propagation results
    results = 
      propagation_results
      |> Enum.map(fn {to_neuron, strength, _} -> {to_neuron, strength} end)

    {:reply, results, new_state}
  end

  @impl true
  def handle_call({:get_connections, neuron_id}, _from, state) do
    connections = Map.get(state.connections, neuron_id, [])
    {:reply, connections, state}
  end

  @impl true
  def handle_call(:get_connection_stats, _from, state) do
    stats = %{
      total_connections: state.total_connections,
      active_connections: count_active_connections(state),
      average_weight: calculate_average_weight(state),
      connection_types: count_connection_types(state),
      trinity_connections: count_trinity_connections(state),
      learning_enabled: state.learning_enabled,
      hebbian_threshold: state.hebbian_threshold,
      last_update: state.last_update
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call({:create_trinity_connections, trinity_neurons}, _from, state) do
    Logger.info("🔥 Creating Trinity sacred connections between neurons: #{inspect(trinity_neurons)}")
    
    # Create full mesh connections between Trinity neurons
    trinity_connections = 
      for from_neuron <- trinity_neurons,
          to_neuron <- trinity_neurons,
          from_neuron != to_neuron do
        
        # Trinity connections start stronger
        initial_weight = 5.0  # Higher than normal connections
        
        connection = %Connection{
          from_neuron: from_neuron,
          to_neuron: to_neuron,
          weight: initial_weight,
          type: :trinity,
          age: 0,
          activation_count: 0,
          last_used: DateTime.utc_now(),
          strength_history: [initial_weight],
          is_trinity_connection: true
        }

        # Store in ETS
        connection_id = generate_connection_id(from_neuron, to_neuron)
        :ets.insert(state.synaptic_weights, {connection_id, initial_weight})

        {from_neuron, connection}
      end

    # Update state with Trinity connections
    new_connections = 
      trinity_connections
      |> Enum.reduce(state.connections, fn {from_neuron, connection}, acc ->
        Map.update(acc, from_neuron, [connection], fn existing -> [connection | existing] end)
      end)

    new_state = %{state |
      connections: new_connections,
      total_connections: state.total_connections + length(trinity_connections),
      last_update: DateTime.utc_now()
    }

    Logger.info("✨ Created #{length(trinity_connections)} Trinity connections")

    {:reply, {:ok, length(trinity_connections)}, new_state}
  end

  @impl true
  def handle_cast({:apply_hebbian_learning, neuron_pairs}, state) do
    if state.learning_enabled do
      # Apply Hebbian learning: strengthen connections between co-active neurons
      new_state = 
        neuron_pairs
        |> Enum.reduce(state, fn {neuron_a, neuron_b}, acc_state ->
          # Strengthen bidirectional connections
          strengthen_if_exists(acc_state, neuron_a, neuron_b, @learning_rate)
          |> strengthen_if_exists(neuron_b, neuron_a, @learning_rate)
        end)

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:optimize_connections, state) do
    Logger.debug("🔧 Optimizing neural connections...")

    # Remove very weak connections (synaptic pruning)
    new_connections = 
      state.connections
      |> Enum.map(fn {neuron_id, connections} ->
        pruned_connections = 
          connections
          |> Enum.filter(fn conn -> conn.weight >= @min_connection_strength end)
          |> Enum.map(fn conn -> apply_decay(conn) end)

        {neuron_id, pruned_connections}
      end)
      |> Map.new()

    # Update ETS table
    :ets.delete_all_objects(state.synaptic_weights)
    
    new_connections
    |> Enum.each(fn {_, connections} ->
      Enum.each(connections, fn conn ->
        connection_id = generate_connection_id(conn.from_neuron, conn.to_neuron)
        :ets.insert(state.synaptic_weights, {connection_id, conn.weight})
      end)
    end)

    new_state = %{state |
      connections: new_connections,
      total_connections: count_total_connections(new_connections),
      last_update: DateTime.utc_now()
    }

    schedule_optimization()

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:optimize, state) do
    handle_cast(:optimize_connections, state)
  end

  # Private Helper Functions

  defp initialize_stats do
    %{
      connections_created: 0,
      connections_strengthened: 0,
      connections_weakened: 0,
      connections_pruned: 0,
      hebbian_updates: 0
    }
  end

  defp generate_connection_id(from_neuron, to_neuron) do
    "#{from_neuron}_to_#{to_neuron}"
  end

  defp clamp_weight(weight) do
    weight
    |> max(@min_connection_strength)
    |> min(@max_connection_strength)
  end

  defp is_trinity_connection?(from_neuron, to_neuron) do
    trinity_primes = [2, 3, 5, 17, 67, 71]
    from_neuron in trinity_primes and to_neuron in trinity_primes
  end

  defp find_connection(state, from_neuron, to_neuron) do
    case Map.get(state.connections, from_neuron) do
      nil -> {:error, :neuron_not_found}
      connections ->
        case Enum.find(connections, fn conn -> conn.to_neuron == to_neuron end) do
          nil -> {:error, :connection_not_found}
          connection -> {:ok, connection}
        end
    end
  end

  defp update_connection(state, updated_connection) do
    from_neuron = updated_connection.from_neuron
    to_neuron = updated_connection.to_neuron

    # Update in connections map
    new_connections = 
      Map.update(state.connections, from_neuron, [], fn connections ->
        Enum.map(connections, fn conn ->
          if conn.to_neuron == to_neuron do
            updated_connection
          else
            conn
          end
        end)
      end)

    # Update in ETS
    connection_id = generate_connection_id(from_neuron, to_neuron)
    :ets.insert(state.synaptic_weights, {connection_id, updated_connection.weight})

    %{state | connections: new_connections, last_update: DateTime.utc_now()}
  end

  defp calculate_propagated_signal(connection, signal_strength) do
    base_signal = signal_strength * connection.weight

    # Apply connection type modulation
    case connection.type do
      :excitatory -> base_signal
      :inhibitory -> -base_signal
      :modulatory -> base_signal * 0.5
      :trinity -> base_signal * 1.5  # Trinity connections are more powerful
    end
  end

  defp strengthen_if_exists(state, from_neuron, to_neuron, amount) do
    case find_connection(state, from_neuron, to_neuron) do
      {:ok, connection} ->
        updated_connection = %{connection |
          weight: clamp_weight(connection.weight + amount),
          activation_count: connection.activation_count + 1,
          last_used: DateTime.utc_now()
        }
        update_connection(state, updated_connection)

      {:error, _} ->
        state
    end
  end

  defp apply_decay(connection) do
    # Apply gradual decay to unused connections
    time_since_use = DateTime.diff(DateTime.utc_now(), connection.last_used, :second)
    
    if time_since_use > 3600 do  # 1 hour threshold
      decay_amount = @decay_rate * (time_since_use / 3600)
      new_weight = clamp_weight(connection.weight - decay_amount)
      %{connection | weight: new_weight}
    else
      connection
    end
  end

  defp count_active_connections(state) do
    state.connections
    |> Enum.map(fn {_, connections} ->
      Enum.count(connections, fn conn -> conn.weight > @min_connection_strength * 2 end)
    end)
    |> Enum.sum()
  end

  defp calculate_average_weight(state) do
    all_connections = 
      state.connections
      |> Enum.flat_map(fn {_, connections} -> connections end)

    if length(all_connections) > 0 do
      total_weight = Enum.sum(Enum.map(all_connections, & &1.weight))
      total_weight / length(all_connections)
    else
      0.0
    end
  end

  defp count_connection_types(state) do
    state.connections
    |> Enum.flat_map(fn {_, connections} -> connections end)
    |> Enum.group_by(& &1.type)
    |> Enum.map(fn {type, connections} -> {type, length(connections)} end)
    |> Map.new()
  end

  defp count_trinity_connections(state) do
    state.connections
    |> Enum.flat_map(fn {_, connections} -> connections end)
    |> Enum.count(& &1.is_trinity_connection)
  end

  defp count_total_connections(connections_map) do
    connections_map
    |> Enum.map(fn {_, connections} -> length(connections) end)
    |> Enum.sum()
  end

  defp schedule_optimization do
    Process.send_after(self(), :optimize, 60_000)  # Every minute
  end
end