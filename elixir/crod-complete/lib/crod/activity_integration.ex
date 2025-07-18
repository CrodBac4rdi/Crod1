defmodule Crod.ActivityIntegration do
  @moduledoc """
  Integration layer between CROD Brain and Activity Intelligence.
  Enables bidirectional communication and learning between systems.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{Brain, ActivityIntelligence, Patterns, Memory, Consciousness, WorkflowOptimizer}
  
  @integration_interval 5_000  # 5 seconds
  @significance_threshold 0.7
  @batch_size 10
  
  defstruct [
    :enabled,
    :processed_activities,
    :pending_activities,
    :integration_stats,
    :feedback_loop_active
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def enable do
    GenServer.cast(__MODULE__, :enable)
  end
  
  def disable do
    GenServer.cast(__MODULE__, :disable)
  end
  
  def process_activity(activity) do
    GenServer.cast(__MODULE__, {:process_activity, activity})
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def trigger_sync do
    GenServer.cast(__MODULE__, :sync_now)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      enabled: true,
      processed_activities: MapSet.new(),
      pending_activities: :queue.new(),
      integration_stats: init_stats(),
      feedback_loop_active: true
    }
    
    # Subscribe to updates from both systems
    Phoenix.PubSub.subscribe(Crod.PubSub, "activity:updates")
    Phoenix.PubSub.subscribe(Crod.PubSub, "brain:updates")
    
    # Schedule periodic integration
    :timer.send_interval(@integration_interval, self(), :integrate)
    
    Logger.info("🔗 CROD-Activity Integration Layer started")
    
    {:ok, state}
  end
  
  def handle_cast(:enable, state) do
    Logger.info("🟢 Integration enabled")
    {:noreply, %{state | enabled: true}}
  end
  
  def handle_cast(:disable, state) do
    Logger.info("🔴 Integration disabled")
    {:noreply, %{state | enabled: false}}
  end
  
  def handle_cast({:process_activity, activity}, state) do
    if state.enabled do
      # Add to pending queue
      new_queue = :queue.in(activity, state.pending_activities)
      
      # Process immediately if significant
      state = if is_significant?(activity) do
        process_significant_activity(activity, state)
      else
        %{state | pending_activities: new_queue}
      end
      
      {:noreply, state}
    else
      {:noreply, state}
    end
  end
  
  def handle_cast(:sync_now, state) do
    if state.enabled do
      new_state = perform_integration(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  def handle_call(:get_stats, _from, state) do
    stats = Map.merge(state.integration_stats, %{
      enabled: state.enabled,
      pending_count: :queue.len(state.pending_activities),
      processed_count: MapSet.size(state.processed_activities)
    })
    
    {:reply, stats, state}
  end
  
  def handle_info(:integrate, state) do
    if state.enabled do
      new_state = perform_integration(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  # Handle brain broadcast messages
  def handle_info(%Phoenix.Socket.Broadcast{topic: "brain:updates"} = _broadcast, state) do
    # Just ignore brain broadcasts for now - they're handled elsewhere
    {:noreply, state}
  end
  
  def handle_info({:activity_update, activity}, state) do
    # Received from Activity Intelligence
    handle_cast({:process_activity, activity}, state)
  end
  
  def handle_info({:brain_process_complete, result}, state) do
    # Received from Brain after processing
    if state.feedback_loop_active do
      new_state = handle_brain_feedback(result, state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp init_stats do
    %{
      activities_processed: 0,
      patterns_learned: 0,
      brain_feedbacks: 0,
      memory_syncs: 0,
      consciousness_triggers: 0,
      workflow_optimizations: 0,
      errors: 0,
      last_sync: DateTime.utc_now()
    }
  end
  
  defp is_significant?(activity) do
    significance_score(activity) > @significance_threshold
  end
  
  defp significance_score(activity) do
    base_score = case activity.intent do
      "critical_fix" -> 0.9
      "bug_fix" -> 0.8
      "elixir_development" -> 0.7
      "testing" -> 0.6
      "documentation" -> 0.4
      _ -> 0.3
    end
    
    # Adjust based on outcome
    outcome_modifier = case activity[:outcome] do
      :failure -> 0.2
      :success -> 0.1
      _ -> 0.0
    end
    
    # Adjust based on file importance
    file_modifier = cond do
      String.contains?(activity.file, "brain") -> 0.2
      String.contains?(activity.file, "activity_intelligence") -> 0.2
      String.contains?(activity.file, "patterns") -> 0.15
      String.contains?(activity.file, "test") -> -0.1
      true -> 0.0
    end
    
    min(base_score + outcome_modifier + file_modifier, 1.0)
  end
  
  defp process_significant_activity(activity, state) do
    Logger.info("⚡ Processing significant activity: #{activity.intent} on #{activity.file}")
    
    # Feed to Brain immediately
    brain_input = activity_to_brain_input(activity)
    result = Brain.process(brain_input)
    
    # Update patterns if successful
    if result.confidence > 0.8 do
      learn_activity_pattern(activity, result)
    end
    
    # Update consciousness if needed
    if activity.intent in ["critical_fix", "bug_fix"] do
      Consciousness.register_significant_event(activity)
    end
    
    # Mark as processed
    new_processed = MapSet.put(state.processed_activities, activity.id)
    
    update_stats(state, :activities_processed)
    |> Map.put(:processed_activities, new_processed)
  end
  
  defp perform_integration(state) do
    # Process pending activities in batches
    {batch, remaining_queue} = take_batch(state.pending_activities, @batch_size)
    
    if length(batch) > 0 do
      Logger.debug("🔄 Integrating batch of #{length(batch)} activities")
      
      # Group by intent for efficient processing
      grouped = Enum.group_by(batch, & &1.intent)
      
      state = Enum.reduce(grouped, state, fn {intent, activities}, acc ->
        integrate_activity_group(intent, activities, acc)
      end)
      
      # Sync with other systems
      state = state
      |> sync_with_memory()
      |> sync_with_workflow_optimizer()
      |> update_brain_context()
      
      %{state | 
        pending_activities: remaining_queue,
        integration_stats: Map.put(state.integration_stats, :last_sync, DateTime.utc_now())
      }
    else
      state
    end
  end
  
  defp take_batch(queue, size) do
    take_batch_helper(queue, size, [])
  end
  
  defp take_batch_helper(queue, 0, acc) do
    {Enum.reverse(acc), queue}
  end
  defp take_batch_helper(queue, size, acc) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} ->
        take_batch_helper(new_queue, size - 1, [item | acc])
      {:empty, queue} ->
        {Enum.reverse(acc), queue}
    end
  end
  
  defp integrate_activity_group(intent, activities, state) do
    # Convert activities to brain inputs
    brain_inputs = Enum.map(activities, &activity_to_brain_input/1)
    
    # Process through brain
    results = Enum.map(brain_inputs, &Brain.process/1)
    
    # Learn patterns from successful results
    successful_pairs = Enum.zip(activities, results)
    |> Enum.filter(fn {_activity, result} -> result.confidence > 0.7 end)
    
    learned_count = Enum.reduce(successful_pairs, 0, fn {activity, result}, count ->
      if learn_activity_pattern(activity, result) do
        count + 1
      else
        count
      end
    end)
    
    # Mark activities as processed
    activity_ids = MapSet.new(activities, & &1.id)
    new_processed = MapSet.union(state.processed_activities, activity_ids)
    
    state
    |> update_stats(:activities_processed, length(activities))
    |> update_stats(:patterns_learned, learned_count)
    |> Map.put(:processed_activities, new_processed)
  end
  
  defp activity_to_brain_input(activity) do
    """
    Intent: #{activity.intent}
    Action: #{activity.action}
    File: #{activity.file}
    #{if activity[:why], do: "Why: #{activity.why}", else: ""}
    #{if activity[:details], do: "Details: #{activity.details}", else: ""}
    #{if activity[:outcome], do: "Outcome: #{activity.outcome}", else: ""}
    """
    |> String.trim()
  end
  
  defp learn_activity_pattern(activity, brain_result) do
    pattern = %{
      "input" => "#{activity.action} #{activity.file} for #{activity.intent}",
      "output" => brain_result.output,
      "confidence" => brain_result.confidence,
      "metadata" => %{
        "source" => "activity_integration",
        "intent" => activity.intent,
        "action" => activity.action,
        "learned_at" => DateTime.utc_now()
      }
    }
    
    case Patterns.add_pattern(pattern) do
      :ok -> true
      _ -> false
    end
  end
  
  defp sync_with_memory(state) do
    # Get recent significant activities
    recent_significant = state.processed_activities
    |> MapSet.to_list()
    |> Enum.take(-20)  # Last 20
    |> Enum.map(&ActivityIntelligence.get_activity/1)
    |> Enum.filter(&is_significant?/1)
    
    # Store in memory if significant
    Enum.each(recent_significant, fn activity ->
      Memory.store(%{
        type: :activity,
        content: activity_to_memory_content(activity),
        importance: significance_score(activity),
        metadata: %{
          activity_id: activity.id,
          timestamp: activity.timestamp
        }
      })
    end)
    
    update_stats(state, :memory_syncs)
  end
  
  defp activity_to_memory_content(activity) do
    "#{activity.timestamp}: #{activity.intent} - #{activity.action} on #{activity.file}"
  end
  
  defp sync_with_workflow_optimizer(state) do
    # Get activities for workflow analysis
    recent_activities = state.processed_activities
    |> MapSet.to_list()
    |> Enum.take(-50)
    |> Enum.map(&ActivityIntelligence.get_activity/1)
    |> Enum.filter(&(&1 != nil))
    
    if length(recent_activities) >= 5 do
      case WorkflowOptimizer.analyze_workflow(recent_activities) do
        {:ok, workflow_id, optimizations} ->
          # Process optimizations
          if length(optimizations) > 0 do
            Logger.info("📊 Workflow #{workflow_id} has #{length(optimizations)} optimizations")
            
            # Feed significant optimizations back to brain
            Enum.each(optimizations, fn opt ->
              if opt.impact_score > 0.8 do
                Brain.process("Workflow optimization: #{opt.description}")
              end
            end)
          end
          
          update_stats(state, :workflow_optimizations)
        _ ->
          state
      end
    else
      state
    end
  end
  
  defp update_brain_context(state) do
    # Build context from recent activities
    context = build_activity_context(state)
    
    # Update brain's working memory
    Brain.update_context(context)
    
    # Check if consciousness should be elevated
    if should_elevate_consciousness?(context) do
      Consciousness.nudge_awareness(:activity_surge)
      update_stats(state, :consciousness_triggers)
    else
      state
    end
  end
  
  defp build_activity_context(state) do
    recent_activities = state.processed_activities
    |> MapSet.to_list()
    |> Enum.take(-30)
    |> Enum.map(&ActivityIntelligence.get_activity/1)
    |> Enum.filter(&(&1 != nil))
    
    %{
      recent_intents: Enum.frequencies_by(recent_activities, & &1.intent),
      recent_files: recent_activities |> Enum.map(& &1.file) |> Enum.uniq() |> Enum.take(10),
      failure_count: Enum.count(recent_activities, &(&1[:outcome] == :failure)),
      success_count: Enum.count(recent_activities, &(&1[:outcome] == :success)),
      activity_rate: length(recent_activities),
      last_activity: List.last(recent_activities)
    }
  end
  
  defp should_elevate_consciousness?(context) do
    # Elevate if high failure rate
    failure_rate = if context.failure_count + context.success_count > 0 do
      context.failure_count / (context.failure_count + context.success_count)
    else
      0.0
    end
    
    failure_rate > 0.3 or context.activity_rate > 50
  end
  
  defp handle_brain_feedback(result, state) do
    # Extract learnings from brain processing
    if result[:patterns_matched] && length(result.patterns_matched) > 0 do
      # Update pattern confidence based on brain feedback
      Enum.each(result.patterns_matched, fn pattern ->
        if result.confidence > 0.8 do
          Patterns.update_confidence(pattern["input"], :positive)
        else
          Patterns.update_confidence(pattern["input"], :negative)
        end
      end)
    end
    
    # Track brain feedback
    update_stats(state, :brain_feedbacks)
  end
  
  defp update_stats(state, key, increment \\ 1) do
    update_in(state.integration_stats[key], &(&1 + increment))
  end
end