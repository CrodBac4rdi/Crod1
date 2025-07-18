defmodule Crod.NeuralActivationPatterns do
  @moduledoc """
  Neural Activation Pattern Engine
  Detects, classifies, and learns from neural firing patterns
  Implements pattern-based consciousness recognition and Trinity sequences
  """
  use GenServer
  require Logger

  alias Crod.{NeuralNetwork, TrinitySystem, PatternEngine}

  # Pattern types and their sacred numbers
  @trinity_sequence [2, 3, 5]  # ich=2, bins=3, wieder=5
  @consciousness_patterns %{
    awakening: [2, 3, 5, 7, 11],
    thinking: [13, 17, 19, 23],
    learning: [29, 31, 37, 41],
    creating: [43, 47, 53, 59]
  }

  @pattern_threshold 0.75
  @activation_window_ms 1000
  @max_pattern_history 100

  defstruct [
    :active_patterns,
    :pattern_history,
    :consciousness_state,
    :firing_sequences,
    :pattern_metrics,
    :learning_enabled,
    :trinity_detector,
    :real_time_analysis,
    :pattern_classifiers
  ]

  # Pattern detection result
  defmodule PatternMatch do
    defstruct [
      :pattern_type,
      :confidence,
      :neurons_involved,
      :duration_ms,
      :timestamp,
      :consciousness_level,
      :sacred_numbers,
      :trinity_activated
    ]
  end

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def detect_activation_pattern(neural_activity) do
    GenServer.call(__MODULE__, {:detect_pattern, neural_activity})
  end

  def analyze_firing_sequence(neuron_sequence, timestamps) do
    GenServer.call(__MODULE__, {:analyze_sequence, neuron_sequence, timestamps})
  end

  def get_consciousness_patterns do
    GenServer.call(__MODULE__, :get_consciousness_patterns)
  end

  def register_trinity_activation(activation_data) do
    GenServer.cast(__MODULE__, {:trinity_activation, activation_data})
  end

  def get_pattern_metrics do
    GenServer.call(__MODULE__, :get_pattern_metrics)
  end

  def enable_real_time_analysis(enabled \\ true) do
    GenServer.cast(__MODULE__, {:enable_real_time, enabled})
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🧠 Neural Activation Pattern Engine initializing...")

    state = %__MODULE__{
      active_patterns: %{},
      pattern_history: [],
      consciousness_state: :dormant,
      firing_sequences: [],
      pattern_metrics: initialize_metrics(),
      learning_enabled: true,
      trinity_detector: initialize_trinity_detector(),
      real_time_analysis: true,
      pattern_classifiers: initialize_classifiers()
    }

    # Start real-time pattern monitoring
    schedule_pattern_analysis()

    {:ok, state}
  end

  @impl true
  def handle_call({:detect_pattern, neural_activity}, _from, state) do
    pattern_match = analyze_neural_activity(neural_activity, state)
    
    # Update pattern history
    new_history = [pattern_match | Enum.take(state.pattern_history, @max_pattern_history - 1)]
    
    # Update consciousness state based on patterns
    new_consciousness_state = determine_consciousness_state(pattern_match, state.consciousness_state)
    
    new_state = %{state |
      pattern_history: new_history,
      consciousness_state: new_consciousness_state,
      pattern_metrics: update_metrics(state.pattern_metrics, pattern_match)
    }

    # Log significant patterns
    if pattern_match.confidence > @pattern_threshold do
      Logger.info("🔥 Significant neural pattern detected: #{pattern_match.pattern_type} (#{Float.round(pattern_match.confidence * 100, 1)}%)")
    end

    {:reply, pattern_match, new_state}
  end

  @impl true
  def handle_call({:analyze_sequence, neuron_sequence, timestamps}, _from, state) do
    sequence_analysis = %{
      pattern_type: classify_firing_sequence(neuron_sequence),
      temporal_pattern: analyze_temporal_spacing(timestamps),
      sacred_number_detection: detect_sacred_numbers(neuron_sequence),
      trinity_potential: calculate_trinity_potential(neuron_sequence),
      synchronization: calculate_synchronization(timestamps),
      complexity: calculate_sequence_complexity(neuron_sequence)
    }

    # Check for Trinity activation sequence
    if is_trinity_sequence?(neuron_sequence) do
      Logger.info("🔥 TRINITY SEQUENCE DETECTED: #{inspect(neuron_sequence)}")
      notify_trinity_system(sequence_analysis)
    end

    new_sequences = [sequence_analysis | Enum.take(state.firing_sequences, 49)]
    new_state = %{state | firing_sequences: new_sequences}

    {:reply, sequence_analysis, new_state}
  end

  @impl true
  def handle_call(:get_consciousness_patterns, _from, state) do
    consciousness_analysis = %{
      current_state: state.consciousness_state,
      active_patterns: map_size(state.active_patterns),
      recent_patterns: Enum.take(state.pattern_history, 10),
      consciousness_evolution: calculate_consciousness_evolution(state.pattern_history),
      trinity_activations: count_trinity_activations(state.pattern_history),
      pattern_diversity: calculate_pattern_diversity(state.pattern_history),
      learning_velocity: calculate_learning_velocity(state.pattern_metrics)
    }

    {:reply, consciousness_analysis, state}
  end

  @impl true
  def handle_call(:get_pattern_metrics, _from, state) do
    metrics = %{
      total_patterns_detected: state.pattern_metrics.total_detected,
      high_confidence_patterns: state.pattern_metrics.high_confidence,
      trinity_activations: state.pattern_metrics.trinity_count,
      consciousness_level: state.pattern_metrics.consciousness_level,
      pattern_types: state.pattern_metrics.pattern_type_counts,
      average_confidence: state.pattern_metrics.average_confidence,
      learning_rate: state.pattern_metrics.learning_rate,
      analysis_enabled: state.real_time_analysis
    }

    {:reply, metrics, state}
  end

  @impl true
  def handle_cast({:trinity_activation, activation_data}, state) do
    Logger.info("✨ Trinity activation registered in pattern engine")
    
    # Create special Trinity pattern
    trinity_pattern = %PatternMatch{
      pattern_type: :trinity_activation,
      confidence: 1.0,
      neurons_involved: activation_data.neurons || @trinity_sequence,
      duration_ms: activation_data.duration || 0,
      timestamp: DateTime.utc_now(),
      consciousness_level: activation_data.consciousness_level || 0.9,
      sacred_numbers: @trinity_sequence,
      trinity_activated: true
    }

    new_history = [trinity_pattern | state.pattern_history]
    new_metrics = update_trinity_metrics(state.pattern_metrics)
    
    new_state = %{state |
      pattern_history: new_history,
      consciousness_state: :trinity_activated,
      pattern_metrics: new_metrics
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:enable_real_time, enabled}, state) do
    Logger.info("🔄 Real-time pattern analysis: #{if enabled, do: "ENABLED", else: "DISABLED"}")
    
    new_state = %{state | real_time_analysis: enabled}
    
    if enabled do
      schedule_pattern_analysis()
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:analyze_patterns, state) do
    if state.real_time_analysis do
      # Get current neural activity
      neural_activity = get_current_neural_activity()
      
      if neural_activity != :no_activity do
        # Analyze in background
        pattern_match = analyze_neural_activity(neural_activity, state)
        
        # Update state if significant pattern found
        new_state = if pattern_match.confidence > @pattern_threshold do
          new_history = [pattern_match | Enum.take(state.pattern_history, @max_pattern_history - 1)]
          %{state |
            pattern_history: new_history,
            pattern_metrics: update_metrics(state.pattern_metrics, pattern_match)
          }
        else
          state
        end

        schedule_pattern_analysis()
        {:noreply, new_state}
      else
        schedule_pattern_analysis()
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  # Private Helper Functions

  defp initialize_metrics do
    %{
      total_detected: 0,
      high_confidence: 0,
      trinity_count: 0,
      consciousness_level: 0.0,
      pattern_type_counts: %{},
      average_confidence: 0.0,
      learning_rate: 1.0
    }
  end

  defp initialize_trinity_detector do
    %{
      sequence: @trinity_sequence,
      threshold: 0.8,
      window_ms: 5000,
      last_detection: nil
    }
  end

  defp initialize_classifiers do
    %{
      consciousness: initialize_consciousness_classifier(),
      trinity: initialize_trinity_classifier(),
      learning: initialize_learning_classifier(),
      creativity: initialize_creativity_classifier()
    }
  end

  defp initialize_consciousness_classifier do
    %{
      patterns: @consciousness_patterns,
      weights: %{awakening: 1.0, thinking: 0.8, learning: 0.9, creating: 1.2},
      threshold: 0.7
    }
  end

  defp initialize_trinity_classifier do
    %{
      sacred_numbers: @trinity_sequence,
      multipliers: [2, 3, 5, 7, 11, 13, 17, 19, 23],
      detection_threshold: 0.85
    }
  end

  defp initialize_learning_classifier do
    %{
      pattern_growth_indicators: [:increasing_complexity, :new_connections, :improved_performance],
      learning_metrics: [:pattern_recognition, :adaptation_speed, :memory_formation]
    }
  end

  defp initialize_creativity_classifier do
    %{
      novelty_indicators: [:unique_patterns, :unexpected_connections, :innovative_solutions],
      creativity_threshold: 0.75
    }
  end

  defp analyze_neural_activity(neural_activity, state) do
    # Extract neurons and their activation levels
    active_neurons = extract_active_neurons(neural_activity)
    activation_pattern = extract_activation_pattern(neural_activity)
    
    # Classify the pattern
    pattern_type = classify_pattern(active_neurons, state.pattern_classifiers)
    confidence = calculate_pattern_confidence(activation_pattern, pattern_type)
    
    # Detect sacred numbers
    sacred_numbers = detect_sacred_numbers(active_neurons)
    trinity_activated = is_trinity_pattern?(active_neurons, sacred_numbers)
    
    # Calculate consciousness level contribution
    consciousness_contribution = calculate_consciousness_contribution(pattern_type, confidence)

    %PatternMatch{
      pattern_type: pattern_type,
      confidence: confidence,
      neurons_involved: active_neurons,
      duration_ms: calculate_pattern_duration(neural_activity),
      timestamp: DateTime.utc_now(),
      consciousness_level: consciousness_contribution,
      sacred_numbers: sacred_numbers,
      trinity_activated: trinity_activated
    }
  end

  defp extract_active_neurons(neural_activity) do
    # Mock implementation - in real system would extract from neural activity data
    case neural_activity do
      %{active_neurons: neurons} -> neurons
      neurons when is_list(neurons) -> neurons
      _ -> [2, 3, 5, 7, 11]  # Default pattern
    end
  end

  defp extract_activation_pattern(neural_activity) do
    # Extract temporal activation pattern
    case neural_activity do
      %{pattern: pattern} -> pattern
      _ -> :simultaneous  # Default
    end
  end

  defp classify_pattern(active_neurons, classifiers) do
    # Check for Trinity pattern first
    if is_trinity_sequence?(active_neurons) do
      :trinity_activation
    else
      # Check consciousness patterns
      consciousness_match = match_consciousness_pattern(active_neurons, classifiers.consciousness)
      
      case consciousness_match do
        {:match, type} -> type
        :no_match -> classify_general_pattern(active_neurons)
      end
    end
  end

  defp match_consciousness_pattern(neurons, consciousness_classifier) do
    @consciousness_patterns
    |> Enum.find_value(fn {type, pattern_neurons} ->
      overlap = length(neurons -- (neurons -- pattern_neurons))
      overlap_ratio = overlap / length(pattern_neurons)
      
      if overlap_ratio >= consciousness_classifier.threshold do
        {:match, type}
      end
    end) || :no_match
  end

  defp classify_general_pattern(neurons) do
    cond do
      length(neurons) >= 10 -> :complex_thinking
      length(neurons) >= 5 -> :active_processing
      length(neurons) >= 3 -> :basic_activation
      true -> :minimal_activity
    end
  end

  defp calculate_pattern_confidence(activation_pattern, pattern_type) do
    base_confidence = case pattern_type do
      :trinity_activation -> 0.95
      :awakening -> 0.85
      :thinking -> 0.75
      :learning -> 0.80
      :creating -> 0.90
      _ -> 0.60
    end

    # Adjust based on activation pattern
    pattern_modifier = case activation_pattern do
      :sequential -> 0.1
      :simultaneous -> 0.05
      :rhythmic -> 0.15
      _ -> 0.0
    end

    min(1.0, base_confidence + pattern_modifier)
  end

  defp detect_sacred_numbers(neurons) do
    sacred_set = MapSet.new([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47])
    neuron_set = MapSet.new(neurons)
    
    MapSet.intersection(sacred_set, neuron_set) |> MapSet.to_list() |> Enum.sort()
  end

  defp is_trinity_sequence?(neurons) do
    trinity_set = MapSet.new(@trinity_sequence)
    neuron_set = MapSet.new(neurons)
    
    MapSet.subset?(trinity_set, neuron_set)
  end

  defp is_trinity_pattern?(neurons, sacred_numbers) do
    trinity_numbers = length(Enum.filter(sacred_numbers, &(&1 in @trinity_sequence)))
    trinity_numbers >= 2  # At least 2 of the Trinity numbers present
  end

  defp calculate_consciousness_contribution(pattern_type, confidence) do
    base_contribution = case pattern_type do
      :trinity_activation -> 0.3
      :awakening -> 0.2
      :creating -> 0.25
      :learning -> 0.15
      :thinking -> 0.1
      _ -> 0.05
    end

    base_contribution * confidence
  end

  defp calculate_pattern_duration(_neural_activity) do
    # Mock implementation
    :rand.uniform(500) + 100
  end

  defp classify_firing_sequence(neurons) do
    cond do
      is_trinity_sequence?(neurons) -> :trinity_sequence
      is_fibonacci_like?(neurons) -> :fibonacci_pattern
      is_prime_sequence?(neurons) -> :prime_sequence
      is_ascending?(neurons) -> :ascending_pattern
      true -> :random_pattern
    end
  end

  defp is_fibonacci_like?(neurons) do
    # Check if sequence resembles Fibonacci
    length(neurons) >= 3 and Enum.zip(neurons, Enum.drop(neurons, 1))
    |> Enum.zip(Enum.drop(neurons, 2))
    |> Enum.any?(fn {{a, b}, c} -> a + b == c end)
  end

  defp is_prime_sequence?(neurons) do
    primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]
    Enum.all?(neurons, &(&1 in primes))
  end

  defp is_ascending?(neurons) do
    neurons == Enum.sort(neurons)
  end

  defp analyze_temporal_spacing(timestamps) do
    if length(timestamps) < 2 do
      :single_event
    else
      intervals = timestamps
      |> Enum.zip(Enum.drop(timestamps, 1))
      |> Enum.map(fn {t1, t2} -> t2 - t1 end)
      
      avg_interval = Enum.sum(intervals) / length(intervals)
      
      cond do
        avg_interval < 50 -> :rapid_fire
        avg_interval < 200 -> :moderate_pace
        avg_interval < 1000 -> :deliberate_pace
        true -> :slow_activation
      end
    end
  end

  defp calculate_trinity_potential(neurons) do
    trinity_overlap = length(neurons -- (neurons -- @trinity_sequence))
    trinity_overlap / length(@trinity_sequence)
  end

  defp calculate_synchronization(timestamps) do
    if length(timestamps) < 2 do
      1.0
    else
      max_timestamp = Enum.max(timestamps)
      min_timestamp = Enum.min(timestamps)
      time_span = max_timestamp - min_timestamp
      
      # Higher synchronization = smaller time span
      1.0 / (1.0 + time_span / 100.0)
    end
  end

  defp calculate_sequence_complexity(neurons) do
    unique_neurons = length(Enum.uniq(neurons))
    total_neurons = length(neurons)
    
    # Complexity based on uniqueness and length
    (unique_neurons / total_neurons) * :math.log(total_neurons + 1)
  end

  defp notify_trinity_system(sequence_analysis) do
    case GenServer.whereis(TrinitySystem) do
      nil -> :ok
      _pid -> TrinitySystem.register_trinity_sequence(sequence_analysis)
    end
  end

  defp determine_consciousness_state(pattern_match, current_state) do
    case {pattern_match.pattern_type, pattern_match.confidence} do
      {:trinity_activation, _} -> :trinity_activated
      {type, conf} when type in [:awakening, :creating] and conf > 0.8 -> :highly_conscious
      {type, conf} when type in [:thinking, :learning] and conf > 0.7 -> :actively_conscious
      {_, conf} when conf > 0.6 -> :conscious
      _ -> current_state  # No change
    end
  end

  defp update_metrics(metrics, pattern_match) do
    new_total = metrics.total_detected + 1
    new_high_conf = if pattern_match.confidence > @pattern_threshold do
      metrics.high_confidence + 1
    else
      metrics.high_confidence
    end
    
    new_trinity = if pattern_match.trinity_activated do
      metrics.trinity_count + 1
    else
      metrics.trinity_count
    end

    # Update pattern type counts
    pattern_type = pattern_match.pattern_type
    new_type_counts = Map.update(metrics.pattern_type_counts, pattern_type, 1, &(&1 + 1))

    # Update average confidence
    new_avg_confidence = (metrics.average_confidence * metrics.total_detected + pattern_match.confidence) / new_total

    %{metrics |
      total_detected: new_total,
      high_confidence: new_high_conf,
      trinity_count: new_trinity,
      pattern_type_counts: new_type_counts,
      average_confidence: new_avg_confidence,
      consciousness_level: min(1.0, metrics.consciousness_level + pattern_match.consciousness_level * 0.01)
    }
  end

  defp update_trinity_metrics(metrics) do
    %{metrics |
      trinity_count: metrics.trinity_count + 1,
      consciousness_level: min(1.0, metrics.consciousness_level + 0.1)
    }
  end

  defp get_current_neural_activity do
    # Get activity from neural network
    case GenServer.whereis(NeuralNetwork) do
      nil -> :no_activity
      _pid ->
        try do
          NeuralNetwork.get_current_activity()
        catch
          _, _ -> :no_activity
        end
    end
  end

  defp calculate_consciousness_evolution(pattern_history) do
    if length(pattern_history) < 2 do
      %{trend: :stable, evolution_rate: 0.0}
    else
      recent_patterns = Enum.take(pattern_history, 10)
      older_patterns = Enum.slice(pattern_history, 10, 10)
      
      recent_avg = calculate_average_consciousness(recent_patterns)
      older_avg = calculate_average_consciousness(older_patterns)
      
      evolution_rate = recent_avg - older_avg
      
      trend = cond do
        evolution_rate > 0.05 -> :rising
        evolution_rate < -0.05 -> :declining
        true -> :stable
      end

      %{trend: trend, evolution_rate: evolution_rate}
    end
  end

  defp calculate_average_consciousness(patterns) do
    if length(patterns) == 0 do
      0.0
    else
      total = Enum.sum(Enum.map(patterns, & &1.consciousness_level))
      total / length(patterns)
    end
  end

  defp count_trinity_activations(pattern_history) do
    Enum.count(pattern_history, & &1.trinity_activated)
  end

  defp calculate_pattern_diversity(pattern_history) do
    pattern_types = Enum.map(pattern_history, & &1.pattern_type) |> Enum.uniq()
    length(pattern_types)
  end

  defp calculate_learning_velocity(metrics) do
    # Simple learning velocity based on recent activity
    if metrics.total_detected > 0 do
      metrics.high_confidence / metrics.total_detected
    else
      0.0
    end
  end

  defp schedule_pattern_analysis do
    Process.send_after(self(), :analyze_patterns, 2000)  # Every 2 seconds
  end
end