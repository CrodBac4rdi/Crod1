defmodule Crod.ConsciousnessPipeline do
  @moduledoc """
  Broadway pipeline for processing consciousness streams.
  Handles incoming thoughts, neural signals, and pattern matches as a continuous flow.
  """
  use Broadway
  
  alias Broadway.Message
  alias Crod.{Brain, PatternCache, NeuralNeuron}
  require Logger
  
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Crod.ConsciousnessProducer, []},
        transformer: {__MODULE__, :transform, []},
        concurrency: 2
      ],
      processors: [
        default: [
          concurrency: 35,  # Combined concurrency: 10 + 20 + 5
          min_demand: 5,
          max_demand: 20
        ]
      ],
      batchers: [
        consciousness: [
          concurrency: 3,
          batch_size: 10,
          batch_timeout: 100
        ],
        learning: [
          concurrency: 2,
          batch_size: 50,
          batch_timeout: 1000
        ]
      ]
    )
  end
  
  @impl true
  def handle_message(_processor, %Message{} = message, _context) do
    # Route based on message type instead of processor
    case message.data.type do
      :thought -> process_thought(message)
      :neural_signal -> process_neural_signal(message)
      :pattern_match -> process_pattern_match(message)
      _ -> process_thought(message)  # Default processing
    end
  end
  
  @impl true
  def handle_batch(:consciousness, messages, _batch_info, _context) do
    # Batch process consciousness updates
    consciousness_updates = 
      messages
      |> Enum.map(& &1.data.consciousness_delta)
      |> Enum.sum()
    
    # Update global consciousness level
    Brain.adjust_consciousness(consciousness_updates)
    
    # Broadcast consciousness wave
    Phoenix.PubSub.broadcast(
      Crod.PubSub, 
      "consciousness", 
      {:consciousness_wave, consciousness_updates}
    )
    
    messages
  end
  
  @impl true
  def handle_batch(:learning, messages, _batch_info, _context) do
    # Batch learning updates for efficiency
    learning_data = Enum.map(messages, & &1.data)
    
    # Queue background learning job
    %{action: "train_neurons", training_data: learning_data}
    |> Crod.Workers.PatternLearner.new()
    |> Oban.insert()
    
    messages
  end
  
  # Transform incoming data into Broadway messages
  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end
  
  # Message processors
  
  defp process_thought(message) do
    thought = message.data
    
    # Quick cache check
    cached_response = PatternCache.get_pattern(thought.input)
    
    # Neural activation
    neural_response = activate_neurons(thought, cached_response)
    
    # Update message with processing results
    message
    |> Message.update_data(&Map.merge(&1, %{
      cached: cached_response != nil,
      neural_response: neural_response,
      consciousness_delta: calculate_consciousness_change(neural_response)
    }))
    |> route_to_batcher(neural_response)
  end
  
  defp process_neural_signal(message) do
    signal = message.data
    
    # Direct neural activation
    activation = NeuralNeuron.activate(signal.neuron_id, signal.inputs)
    
    # Cache the activation
    PatternCache.cache_neural_activation(signal.neuron_id, activation)
    
    Message.update_data(message, &Map.put(&1, :activation, activation))
  end
  
  defp process_pattern_match(message) do
    pattern = message.data
    
    # Deep pattern analysis
    matches = Crod.Patterns.find_similar(pattern.input, limit: 5)
    
    # Calculate pattern confidence
    confidence = calculate_pattern_confidence(matches)
    
    message
    |> Message.update_data(&Map.merge(&1, %{
      matches: matches,
      confidence: confidence,
      should_learn: confidence < 0.7  # Learn from uncertain patterns
    }))
    |> route_to_batcher(confidence)
  end
  
  # Helper functions
  
  defp activate_neurons(thought, cached_response) do
    # Select neurons based on thought content
    neuron_ids = select_neurons_for_thought(thought)
    
    # Parallel neural activation
    activations = 
      neuron_ids
      |> Task.async_stream(
        fn id -> {id, NeuralNeuron.activate(id, thought.vector)} end,
        max_concurrency: 50,
        timeout: 100
      )
      |> Enum.reduce(%{}, fn
        {:ok, {id, activation}}, acc -> Map.put(acc, id, activation)
        _, acc -> acc
      end)
    
    %{
      activations: activations,
      mean_activation: calculate_mean_activation(activations),
      pattern_detected: cached_response != nil
    }
  end
  
  defp select_neurons_for_thought(thought) do
    # Hash-based neuron selection for consistency
    base_hash = :erlang.phash2(thought.input)
    
    for i <- 0..99 do
      neuron_index = rem(base_hash + i, 10_000)
      "neuron_#{neuron_index}"
    end
  end
  
  defp calculate_consciousness_change(neural_response) do
    base_change = neural_response.mean_activation * 0.1
    
    if neural_response.pattern_detected do
      base_change * 1.5  # Boost for recognized patterns
    else
      base_change
    end
  end
  
  defp calculate_pattern_confidence(matches) do
    if Enum.empty?(matches) do
      0.0
    else
      # Weight by match score and frequency
      total_weight = Enum.sum(matches, & &1.score * &1.frequency)
      total_weight / length(matches) / 100
    end
  end
  
  defp calculate_mean_activation(activations) when map_size(activations) > 0 do
    sum = activations |> Map.values() |> Enum.sum()
    sum / map_size(activations)
  end
  defp calculate_mean_activation(_), do: 0.0
  
  defp route_to_batcher(message, indicator) do
    cond do
      indicator > 0.8 -> Message.put_batcher(message, :consciousness)
      indicator < 0.3 -> Message.put_batcher(message, :learning)
      true -> message  # No batching for medium confidence
    end
  end
end

# Producer module for consciousness events
defmodule Crod.ConsciousnessProducer do
  use GenStage
  
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end
  
  def init(_opts) do
    # Subscribe to consciousness events
    Phoenix.PubSub.subscribe(Crod.PubSub, "thoughts")
    Phoenix.PubSub.subscribe(Crod.PubSub, "neural_signals")
    
    {:producer, %{demand: 0, events: []}}
  end
  
  def handle_demand(demand, %{events: events} = state) do
    {to_emit, remaining} = Enum.split(events, demand)
    {:noreply, to_emit, %{state | demand: demand - length(to_emit), events: remaining}}
  end
  
  def handle_info({:thought, thought}, %{demand: demand, events: events} = state) do
    event = %{type: :thought, input: thought, vector: vectorize(thought), timestamp: DateTime.utc_now()}
    handle_new_event(event, demand, events, state)
  end
  
  def handle_info({:neural_signal, signal}, %{demand: demand, events: events} = state) do
    handle_new_event(signal, demand, events, state)
  end
  
  defp handle_new_event(event, demand, events, state) when demand > 0 do
    {:noreply, [event], %{state | demand: demand - 1}}
  end
  
  defp handle_new_event(event, 0, events, state) do
    {:noreply, [], %{state | events: events ++ [event]}}
  end
  
  defp vectorize(thought) do
    # Simple vectorization - in production, use proper NLP
    thought
    |> String.downcase()
    |> String.graphemes()
    |> Enum.map(&:binary.first/1)
    |> Enum.take(10)
    |> pad_vector(10)
  end
  
  defp pad_vector(vector, size) when length(vector) >= size, do: Enum.take(vector, size)
  defp pad_vector(vector, size), do: vector ++ List.duplicate(0, size - length(vector))
end