defmodule Crod.Workers.PatternLearner do
  @moduledoc """
  Background worker for learning patterns using Oban.
  Processes pattern learning asynchronously to avoid blocking main consciousness flow.
  """
  use Oban.Worker, queue: :consciousness, max_attempts: 3
  
  alias Crod.{Memory, Patterns, Consciousness, Brain}
  require Logger
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "learn_pattern", "pattern" => pattern, "response" => response}}) do
    Logger.info("🧠 Background learning pattern: #{pattern}")
    
    # Store in long-term memory
    Memory.store_pattern(pattern, response)
    
    # Update pattern database
    Patterns.add_dynamic_pattern(%{
      pattern: pattern,
      response: response,
      learned_at: DateTime.utc_now(),
      confidence: 0.7  # Start with medium confidence
    })
    
    # Adjust consciousness based on learning
    Consciousness.trigger_learning_event()
    
    :ok
  end
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "consolidate_memory"}}) do
    Logger.info("💭 Consolidating memory...")
    
    # Get recent short-term memories
    recent_memories = Memory.get_short_term_memories(limit: 100)
    
    # Find patterns in recent interactions
    patterns = analyze_patterns(recent_memories)
    
    # Store significant patterns
    Enum.each(patterns, fn pattern ->
      if pattern.significance > 0.8 do
        Memory.promote_to_long_term(pattern)
      end
    end)
    
    # Clean up old short-term memories
    Memory.cleanup_old_memories(older_than: {1, :hour})
    
    :ok
  end
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "train_neurons", "training_data" => data}}) do
    Logger.info("🎯 Training neurons with new data...")
    
    # Train relevant neurons with the data
    data
    |> select_relevant_neurons()
    |> Enum.each(fn {neuron_id, training_set} ->
      Crod.NeuralNeuron.train(neuron_id, training_set.inputs, training_set.target)
    end)
    
    :ok
  end
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "temporal_analysis"}}) do
    Logger.info("⏰ Analyzing temporal patterns...")
    
    # Analyze time-based patterns in consciousness
    temporal_patterns = Brain.analyze_temporal_patterns()
    
    # Adjust consciousness rhythms based on patterns
    Enum.each(temporal_patterns, fn pattern ->
      case pattern.type do
        :daily_rhythm -> Consciousness.adjust_daily_rhythm(pattern)
        :activity_burst -> Consciousness.prepare_for_activity(pattern)
        :quiet_period -> Consciousness.enter_rest_mode(pattern)
        _ -> :ok
      end
    end)
    
    :ok
  end
  
  # Helper functions
  
  defp analyze_patterns(memories) do
    memories
    |> Enum.group_by(& &1.pattern_hash)
    |> Enum.map(fn {_hash, group} ->
      %{
        pattern: hd(group).input,
        frequency: length(group),
        significance: calculate_significance(group),
        responses: Enum.map(group, & &1.response)
      }
    end)
    |> Enum.sort_by(& &1.significance, :desc)
  end
  
  defp calculate_significance(memory_group) do
    frequency = length(memory_group)
    recency = calculate_recency(hd(memory_group).timestamp)
    consistency = calculate_response_consistency(memory_group)
    
    # Weighted significance score
    (frequency * 0.3 + recency * 0.5 + consistency * 0.2) / 1.0
  end
  
  defp calculate_recency(timestamp) do
    hours_ago = DateTime.diff(DateTime.utc_now(), timestamp, :hour)
    max(0, 1 - (hours_ago / 24))  # Decay over 24 hours
  end
  
  defp calculate_response_consistency(memory_group) do
    responses = Enum.map(memory_group, & &1.response)
    unique_responses = Enum.uniq(responses)
    
    if length(unique_responses) == 1 do
      1.0  # Perfect consistency
    else
      1.0 / length(unique_responses)  # Lower score for varied responses
    end
  end
  
  defp select_relevant_neurons(training_data) do
    # Select neurons based on training data characteristics
    # This is a simplified version - could use more sophisticated selection
    training_data
    |> Enum.take(100)  # Limit to 100 neurons for training
    |> Enum.map(fn data ->
      neuron_id = "neuron_#{:rand.uniform(10_000)}"
      {neuron_id, data}
    end)
  end
end