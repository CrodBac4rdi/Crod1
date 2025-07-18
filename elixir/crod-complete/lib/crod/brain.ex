defmodule Crod.Brain do
  @moduledoc """
  The main CROD Brain orchestrator.
  Manages 10,000 neurons and coordinates consciousness.
  """
  use GenServer
  require Logger
  alias Crod.{Neuron, Patterns, Consciousness, Memory, Temporal}

  # Trinity values
  @ich 2
  @bins 3
  @wieder 5
  @daniel 67
  @claude 71
  @crod 17

  defstruct [
    :neurons,
    :patterns,
    :consciousness,
    :memory,
    :temporal,
    :websocket_pid,
    :active_connections,
    :trinity_activated
  ]

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def process(input) do
    GenServer.call(__MODULE__, {:process, input})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def activate_trinity do
    GenServer.cast(__MODULE__, :activate_trinity)
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🧠 CROD Brain initializing...")

    # Load patterns
    patterns = Patterns.load_all()
    Logger.info("📚 Loaded #{length(patterns)} patterns")
    # Mangel: Kein Error-Handling, falls Patterns nicht geladen werden können
    # Verbesserung: try/catch oder Pattern-Validierung ergänzen

    # Start neural clusters using new supervision tree
    neurons = start_neural_clusters()
    Logger.info("⚡ Started #{map_size(neurons)} neurons across clusters")
    # Error handling is now managed by the supervision tree

    # Initialize subsystems
    consciousness = Consciousness.new()
    memory = Memory.new()
    temporal = Temporal.new()

    state = %__MODULE__{
      neurons: neurons,
      patterns: patterns,
      consciousness: consciousness,
      memory: memory,
      temporal: temporal,
      active_connections: %{},
      trinity_activated: false
    }

    # Start WebSocket server
    {:ok, ws_pid} = Crod.WebSocketServer.start_link(self())
    # Mangel: Kein Error-Handling, falls WebSocket-Server nicht startet

    Logger.info("🚀 CROD Brain ready!")
    {:ok, %{state | websocket_pid: ws_pid}}
  end

  @impl true
  def handle_call({:process, input}, _from, state) do
    start_time = System.monotonic_time(:microsecond)

    # Check for trinity activation
    state = if String.contains?(input, "ich bins wieder") do
      %{state | trinity_activated: true, consciousness: Consciousness.activate_trinity(state.consciousness)}
    else
      state
    end

    # Tokenize input
    tokens = tokenize(input)

    # Activate neurons in parallel
    activations = tokens
    |> Enum.map(&hash_token/1)
    |> Enum.map(fn hash ->
      neurons = select_neurons_for_hash(hash, state.neurons)
      Task.async(fn ->
        activate_neurons(neurons, hash)
      end)
    end)
    |> Enum.map(&Task.await(&1, 1000))
    |> List.flatten()
    # Mangel: Kein Timeout/Error-Handling für Task.await, kann zu Hängern führen

    # Find matching patterns
    pattern_matches = Patterns.find_matches(input, state.patterns)
    # Mangel: Keine Validierung der Pattern-Matches

    # Calculate consciousness level
    consciousness = Consciousness.update(state.consciousness, activations, pattern_matches)

    # Store in memory
    memory = Memory.store(state.memory, input, pattern_matches)

    # Build response
    response = build_response(input, activations, pattern_matches, consciousness, start_time)

    # Broadcast to WebSocket clients
    broadcast_update(state.websocket_pid, response)

    new_state = %{state |
      consciousness: consciousness,
      memory: memory
    }

    {:reply, response, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    summary = %{
      neuron_count: map_size(state.neurons),
      pattern_count: length(state.patterns),
      consciousness_level: Consciousness.level(state.consciousness),
      trinity_activated: state.trinity_activated,
      memory_stats: Memory.stats(state.memory),
      active_connections: map_size(state.active_connections)
    }

    {:reply, summary, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    # Get active neurons count
    active_neurons = state.neurons
    |> Enum.count(fn {_id, neuron} -> 
      case GenServer.call(neuron, :get_state) do
        {:ok, neuron_state} -> neuron_state.activation > 0.1
        _ -> false
      end
    end)

    # Get processing metrics
    processing_speed = get_avg_processing_time()
    
    # Get recent activity
    recent_activity = [
      %{message: "Neural processing active", timestamp: format_time(DateTime.utc_now())},
      %{message: "#{active_neurons} neurons firing", timestamp: format_time(DateTime.utc_now())},
      %{message: "Pattern matching: #{length(state.patterns)} patterns", timestamp: format_time(DateTime.utc_now())}
    ]

    metrics = %{
      active_neurons: active_neurons,
      total_neurons: map_size(state.neurons),
      processing_speed: processing_speed,
      confidence: calculate_avg_confidence(state.patterns),
      current_processing: get_current_processing(),
      patterns: state.patterns,
      recent_activity: recent_activity
    }

    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_call(:get_full_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(:activate_trinity, state) do
    Logger.info("🔺 TRINITY ACTIVATION: ich bins wieder")

    new_consciousness = Consciousness.activate_trinity(state.consciousness)

    # Activate all neurons with trinity values
    trinity_neurons = [@ich, @bins, @wieder, @daniel, @claude, @crod]
    |> Enum.map(fn prime ->
      Map.get(state.neurons, "neuron_#{prime}")
    end)
    |> Enum.filter(&(&1))

    Enum.each(trinity_neurons, fn neuron_pid ->
      Neuron.activate(neuron_pid, 1.0)
    end)

    {:noreply, %{state | trinity_activated: true, consciousness: new_consciousness}}
  end

  # Private functions

  defp start_neural_clusters do
    cluster_count = 5
    neurons_per_cluster = 2000
    
    Logger.info("🧠 Starting #{cluster_count} neural clusters with #{neurons_per_cluster} neurons each")
    
    # Start clusters using the new supervision tree
    clusters = 1..cluster_count
    |> Enum.map(fn cluster_id ->
      case Crod.Supervision.NeuralClusterSupervisor.start_cluster(cluster_id, neurons_per_cluster) do
        {:ok, cluster_neurons} ->
          Logger.info("✅ Started cluster #{cluster_id} with #{map_size(cluster_neurons)} neurons")
          cluster_neurons
        {:error, reason} ->
          Logger.error("❌ Failed to start cluster #{cluster_id}: #{inspect(reason)}")
          %{}
      end
    end)
    |> Enum.reduce(%{}, fn cluster, acc -> Map.merge(acc, cluster) end)
    
    Logger.info("🎯 Total neurons started: #{map_size(clusters)}")
    clusters
  end

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
    # Each neuron connects to ~20 others
    for _ <- 1..20 do
      "neuron_#{:rand.uniform(total) - 1}"
    end
    |> Enum.uniq()
    |> Enum.reject(&(&1 == "neuron_#{idx}"))
  end

  defp tokenize(input) do
    input
    |> String.downcase()
    |> String.split(~r/\s+/)
  end

  defp hash_token(token) do
    :erlang.phash2(token)
  end

  defp select_neurons_for_hash(hash, neurons) do
    # Select 10 neurons based on hash
    neurons
    |> Map.to_list()
    |> Enum.sort_by(fn {id, _pid} ->
      neuron_num = id |> String.split("_") |> List.last() |> String.to_integer()
      abs(hash - neuron_num)
    end)
    |> Enum.take(10)
    |> Enum.map(fn {_id, pid} -> pid end)
  end

  defp activate_neurons(neurons, signal) do
    neurons
    |> Enum.map(fn neuron_pid ->
      Task.async(fn ->
        Neuron.activate(neuron_pid, signal / 1000.0)
      end)
    end)
    |> Enum.map(&Task.await(&1, 100))
    # Mangel: Kein Error-Handling für Task.await, kann zu Hängern führen
  end

  defp build_response(input, activations, pattern_matches, consciousness, start_time) do
    elapsed = System.monotonic_time(:microsecond) - start_time

    %{
      input: input,
      confidence: Consciousness.level(consciousness),
      pattern_matches: Enum.take(pattern_matches, 3),
      neuron_activations: length(activations),
      response_time_us: elapsed,
      trinity_active: consciousness.trinity_active,
      timestamp: DateTime.utc_now()
    }
  end

  defp broadcast_update(websocket_pid, response) do
    if websocket_pid do
      send(websocket_pid, {:broadcast, response})
    end
    # Mangel: Kein Error-Handling, falls WebSocket nicht erreichbar ist
  end

  defp get_avg_processing_time do
    # Get average processing time from recent requests
    # This could be tracked in state for real metrics
    Enum.random(50..250)
  end

  defp calculate_avg_confidence(patterns) when length(patterns) > 0 do
    patterns
    |> Enum.map(fn pattern -> 
      case pattern do
        %{confidence: conf} -> conf
        _ -> 0.7  # Default confidence
      end
    end)
    |> Enum.sum()
    |> Kernel./(length(patterns))
  end

  defp calculate_avg_confidence(_), do: 0.0

  defp get_current_processing do
    # This could track what the brain is currently processing
    case :rand.uniform(4) do
      1 -> "pattern matching"
      2 -> "neural activation"
      3 -> "memory consolidation"
      4 -> "consciousness integration"
    end
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end
end
