defmodule Crod.ActivityReplay do
  @moduledoc """
  System for replaying past activities to analyze workflows, debug issues,
  and train the neural network on historical patterns.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{ActivityIntelligence, Brain, Patterns, WorkflowOptimizer}
  
  @replay_batch_size 50
  @replay_speed_multiplier 10  # 10x speed by default
  
  defstruct [
    :replay_state,
    :current_session,
    :replay_queue,
    :playback_speed,
    :filters,
    :analysis_results,
    :callbacks
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def start_replay(session_id, opts \\ []) do
    GenServer.call(__MODULE__, {:start_replay, session_id, opts})
  end
  
  def stop_replay do
    GenServer.cast(__MODULE__, :stop_replay)
  end
  
  def pause_replay do
    GenServer.cast(__MODULE__, :pause_replay)
  end
  
  def resume_replay do
    GenServer.cast(__MODULE__, :resume_replay)
  end
  
  def set_speed(multiplier) do
    GenServer.cast(__MODULE__, {:set_speed, multiplier})
  end
  
  def jump_to(timestamp) do
    GenServer.cast(__MODULE__, {:jump_to, timestamp})
  end
  
  def get_replay_state do
    GenServer.call(__MODULE__, :get_replay_state)
  end
  
  def analyze_replay(session_id, analysis_type) do
    GenServer.call(__MODULE__, {:analyze_replay, session_id, analysis_type})
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      replay_state: :stopped,
      current_session: nil,
      replay_queue: :queue.new(),
      playback_speed: @replay_speed_multiplier,
      filters: %{},
      analysis_results: %{},
      callbacks: %{}
    }
    
    {:ok, state}
  end
  
  def handle_call({:start_replay, session_id, opts}, _from, state) do
    case load_session_activities(session_id) do
      {:ok, activities} ->
        # Apply filters if provided
        filtered_activities = apply_filters(activities, opts[:filters] || %{})
        
        # Build replay queue
        replay_queue = build_replay_queue(filtered_activities)
        
        # Start replay timer
        schedule_next_replay(0)
        
        new_state = %{state |
          replay_state: :playing,
          current_session: %{
            id: session_id,
            activities: filtered_activities,
            total_count: length(filtered_activities),
            current_index: 0,
            start_time: DateTime.utc_now(),
            options: opts
          },
          replay_queue: replay_queue,
          filters: opts[:filters] || %{},
          callbacks: opts[:callbacks] || %{}
        }
        
        Logger.info("▶️ Started replay of session #{session_id} with #{length(filtered_activities)} activities")
        
        {:reply, {:ok, length(filtered_activities)}, new_state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call(:get_replay_state, _from, state) do
    replay_info = if state.current_session do
      %{
        state: state.replay_state,
        session_id: state.current_session.id,
        progress: calculate_progress(state),
        current_index: state.current_session.current_index,
        total_activities: state.current_session.total_count,
        playback_speed: state.playback_speed,
        elapsed_time: calculate_elapsed_time(state)
      }
    else
      %{state: :stopped}
    end
    
    {:reply, replay_info, state}
  end
  
  def handle_call({:analyze_replay, session_id, analysis_type}, _from, state) do
    result = perform_replay_analysis(session_id, analysis_type)
    
    # Cache analysis results
    new_analysis = Map.put(state.analysis_results, {session_id, analysis_type}, result)
    new_state = %{state | analysis_results: new_analysis}
    
    {:reply, result, new_state}
  end
  
  def handle_cast(:stop_replay, state) do
    Logger.info("⏹️ Stopped replay")
    
    # Run any completion callbacks
    if state.callbacks[:on_complete] do
      state.callbacks.on_complete.(state.current_session)
    end
    
    {:noreply, %{state |
      replay_state: :stopped,
      current_session: nil,
      replay_queue: :queue.new()
    }}
  end
  
  def handle_cast(:pause_replay, state) do
    Logger.info("⏸️ Paused replay")
    {:noreply, %{state | replay_state: :paused}}
  end
  
  def handle_cast(:resume_replay, state) do
    if state.replay_state == :paused do
      Logger.info("▶️ Resumed replay")
      schedule_next_replay(0)
      {:noreply, %{state | replay_state: :playing}}
    else
      {:noreply, state}
    end
  end
  
  def handle_cast({:set_speed, multiplier}, state) do
    Logger.info("⏩ Set replay speed to #{multiplier}x")
    {:noreply, %{state | playback_speed: multiplier}}
  end
  
  def handle_cast({:jump_to, timestamp}, state) do
    if state.current_session do
      # Find activity closest to timestamp
      new_index = find_activity_index_by_timestamp(
        state.current_session.activities,
        timestamp
      )
      
      # Rebuild queue from new position
      remaining_activities = Enum.drop(state.current_session.activities, new_index)
      new_queue = build_replay_queue(remaining_activities)
      
      new_session = %{state.current_session | current_index: new_index}
      
      Logger.info("⏭️ Jumped to activity #{new_index}")
      
      {:noreply, %{state |
        current_session: new_session,
        replay_queue: new_queue
      }}
    else
      {:noreply, state}
    end
  end
  
  def handle_info(:replay_next, state) do
    if state.replay_state == :playing do
      case :queue.out(state.replay_queue) do
        {{:value, activity}, new_queue} ->
          # Process activity
          process_replay_activity(activity, state)
          
          # Update state
          new_session = update_in(state.current_session.current_index, &(&1 + 1))
          new_state = %{state |
            current_session: new_session,
            replay_queue: new_queue
          }
          
          # Check if complete
          if :queue.is_empty(new_queue) do
            handle_cast(:stop_replay, new_state)
          else
            # Schedule next activity
            delay = calculate_replay_delay(activity, new_state)
            schedule_next_replay(delay)
            {:noreply, new_state}
          end
        
        {:empty, _} ->
          handle_cast(:stop_replay, state)
      end
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp load_session_activities(session_id) do
    case ActivityIntelligence.get_session_activities(session_id) do
      activities when is_list(activities) ->
        {:ok, activities}
      _ ->
        {:error, :session_not_found}
    end
  end
  
  defp apply_filters(activities, filters) do
    activities
    |> filter_by_intent(filters[:intent])
    |> filter_by_outcome(filters[:outcome])
    |> filter_by_time_range(filters[:time_range])
    |> filter_by_files(filters[:files])
  end
  
  defp filter_by_intent(activities, nil), do: activities
  defp filter_by_intent(activities, intent) do
    Enum.filter(activities, &(&1.intent == intent))
  end
  
  defp filter_by_outcome(activities, nil), do: activities
  defp filter_by_outcome(activities, outcome) do
    Enum.filter(activities, &(&1[:outcome] == outcome))
  end
  
  defp filter_by_time_range(activities, nil), do: activities
  defp filter_by_time_range(activities, {start_time, end_time}) do
    Enum.filter(activities, fn activity ->
      DateTime.compare(activity.timestamp, start_time) != :lt and
      DateTime.compare(activity.timestamp, end_time) != :gt
    end)
  end
  
  defp filter_by_files(activities, nil), do: activities
  defp filter_by_files(activities, files) do
    file_set = MapSet.new(files)
    Enum.filter(activities, &MapSet.member?(file_set, &1.file))
  end
  
  defp build_replay_queue(activities) do
    activities
    |> Enum.sort_by(& &1.timestamp)
    |> Enum.reduce(:queue.new(), &:queue.in/2)
  end
  
  defp schedule_next_replay(delay) do
    Process.send_after(self(), :replay_next, delay)
  end
  
  defp process_replay_activity(activity, state) do
    # Log replay
    Logger.debug("🔄 Replaying: #{activity.intent} - #{activity.action} on #{activity.file}")
    
    # Feed to brain if enabled
    if state.current_session.options[:feed_to_brain] do
      input = format_activity_for_brain(activity)
      Brain.process(input, metadata: %{replay: true, session_id: state.current_session.id})
    end
    
    # Learn patterns if enabled
    if state.current_session.options[:learn_patterns] && activity[:outcome] do
      learn_from_replay(activity)
    end
    
    # Run activity callback if provided
    if state.callbacks[:on_activity] do
      state.callbacks.on_activity.(activity, state.current_session.current_index)
    end
    
    # Broadcast replay event
    Phoenix.PubSub.broadcast(
      Crod.PubSub,
      "replay:events",
      {:replay_activity, activity, state.current_session.current_index}
    )
  end
  
  defp format_activity_for_brain(activity) do
    """
    [REPLAY] #{activity.timestamp}
    Intent: #{activity.intent}
    Action: #{activity.action} on #{activity.file}
    #{if activity[:details], do: "Details: #{activity.details}", else: ""}
    #{if activity[:outcome], do: "Outcome: #{activity.outcome}", else: ""}
    """
  end
  
  defp learn_from_replay(activity) do
    if activity.outcome == :success do
      pattern = %{
        "input" => "#{activity.intent}: #{activity.action} #{Path.basename(activity.file)}",
        "output" => activity[:details] || "Success",
        "confidence" => 0.7,
        "metadata" => %{
          "source" => "replay_learning",
          "replayed_at" => DateTime.utc_now()
        }
      }
      
      Patterns.add_pattern(pattern)
    end
  end
  
  defp calculate_replay_delay(activity, state) do
    # Base delay
    base_delay = 100  # 100ms between activities
    
    # Adjust for playback speed
    adjusted_delay = div(base_delay, state.playback_speed)
    
    # Special handling for time gaps
    if state.current_session.current_index > 0 do
      prev_activity = Enum.at(state.current_session.activities, state.current_session.current_index - 1)
      
      if prev_activity do
        actual_gap = DateTime.diff(activity.timestamp, prev_activity.timestamp, :millisecond)
        
        # If there was a significant gap, represent it in replay
        if actual_gap > 5000 do  # More than 5 seconds
          min(div(actual_gap, state.playback_speed), 2000)  # Cap at 2 seconds
        else
          adjusted_delay
        end
      else
        adjusted_delay
      end
    else
      adjusted_delay
    end
  end
  
  defp calculate_progress(state) do
    if state.current_session do
      (state.current_session.current_index / state.current_session.total_count) * 100
    else
      0
    end
  end
  
  defp calculate_elapsed_time(state) do
    if state.current_session && state.current_session.start_time do
      DateTime.diff(DateTime.utc_now(), state.current_session.start_time, :second)
    else
      0
    end
  end
  
  defp find_activity_index_by_timestamp(activities, target_timestamp) do
    activities
    |> Enum.with_index()
    |> Enum.min_by(fn {activity, _index} ->
      abs(DateTime.diff(activity.timestamp, target_timestamp, :millisecond))
    end)
    |> elem(1)
  end
  
  defp perform_replay_analysis(session_id, analysis_type) do
    case load_session_activities(session_id) do
      {:ok, activities} ->
        case analysis_type do
          :workflow ->
            analyze_workflow_patterns(activities)
          
          :errors ->
            analyze_error_patterns(activities)
          
          :performance ->
            analyze_performance_patterns(activities)
          
          :learning ->
            analyze_learning_opportunities(activities)
          
          _ ->
            {:error, :unknown_analysis_type}
        end
      
      error ->
        error
    end
  end
  
  defp analyze_workflow_patterns(activities) do
    # Group activities into workflows
    workflows = activities
    |> Enum.chunk_by(& &1.intent)
    |> Enum.map(fn chunk ->
      %{
        intent: hd(chunk).intent,
        steps: length(chunk),
        duration: calculate_workflow_duration(chunk),
        success_rate: calculate_workflow_success_rate(chunk),
        common_sequence: extract_common_sequence(chunk)
      }
    end)
    
    # Find optimal paths
    optimal_workflows = workflows
    |> Enum.filter(&(&1.success_rate > 0.8))
    |> Enum.sort_by(&(&1.duration))
    
    %{
      total_workflows: length(workflows),
      optimal_workflows: optimal_workflows,
      average_success_rate: average_success_rate(workflows),
      common_patterns: find_common_patterns(activities),
      recommendations: generate_workflow_recommendations(workflows)
    }
  end
  
  defp analyze_error_patterns(activities) do
    failures = Enum.filter(activities, &(&1[:outcome] == :failure))
    
    error_patterns = failures
    |> Enum.group_by(& &1.intent)
    |> Enum.map(fn {intent, failures} ->
      %{
        intent: intent,
        failure_count: length(failures),
        common_files: most_common_files(failures),
        error_types: classify_errors(failures),
        time_distribution: analyze_time_distribution(failures)
      }
    end)
    
    %{
      total_failures: length(failures),
      failure_rate: length(failures) / length(activities),
      error_patterns: error_patterns,
      recovery_patterns: find_recovery_patterns(activities),
      recommendations: generate_error_prevention_recommendations(error_patterns)
    }
  end
  
  defp analyze_performance_patterns(activities) do
    # Calculate performance metrics
    activities_with_duration = Enum.filter(activities, & &1[:duration_ms])
    
    performance_by_intent = activities_with_duration
    |> Enum.group_by(& &1.intent)
    |> Enum.map(fn {intent, acts} ->
      durations = Enum.map(acts, & &1.duration_ms)
      
      %{
        intent: intent,
        avg_duration: average(durations),
        min_duration: Enum.min(durations),
        max_duration: Enum.max(durations),
        std_deviation: standard_deviation(durations)
      }
    end)
    
    %{
      total_time: sum_durations(activities_with_duration),
      avg_activity_duration: average_duration(activities_with_duration),
      performance_by_intent: performance_by_intent,
      bottlenecks: find_bottlenecks(activities),
      optimization_opportunities: find_optimization_opportunities(activities)
    }
  end
  
  defp analyze_learning_opportunities(activities) do
    # Find patterns worth learning
    successful_sequences = find_successful_sequences(activities)
    
    learning_opportunities = successful_sequences
    |> Enum.map(fn sequence ->
      %{
        pattern: describe_sequence(sequence),
        frequency: count_sequence_occurrences(sequence, activities),
        success_rate: calculate_sequence_success_rate(sequence, activities),
        learnable: is_sequence_learnable?(sequence)
      }
    end)
    |> Enum.filter(& &1.learnable)
    
    %{
      learnable_patterns: learning_opportunities,
      unique_approaches: find_unique_approaches(activities),
      improvement_areas: identify_improvement_areas(activities),
      training_recommendations: generate_training_recommendations(learning_opportunities)
    }
  end
  
  # Analysis helper functions
  
  defp calculate_workflow_duration(activities) do
    if length(activities) > 1 do
      first = List.first(activities)
      last = List.last(activities)
      DateTime.diff(last.timestamp, first.timestamp, :millisecond)
    else
      0
    end
  end
  
  defp calculate_workflow_success_rate(activities) do
    success_count = Enum.count(activities, &(&1[:outcome] == :success))
    total_with_outcome = Enum.count(activities, & &1[:outcome])
    
    if total_with_outcome > 0 do
      success_count / total_with_outcome
    else
      0.0
    end
  end
  
  defp extract_common_sequence(activities) do
    activities
    |> Enum.map(&{&1.action, Path.extname(&1.file)})
    |> Enum.dedup()
  end
  
  defp average_success_rate(workflows) do
    rates = Enum.map(workflows, & &1.success_rate)
    if length(rates) > 0, do: Enum.sum(rates) / length(rates), else: 0.0
  end
  
  defp find_common_patterns(activities) do
    activities
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.map(&pattern_signature/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {_pattern, count} -> count > 2 end)
    |> Enum.sort_by(fn {_pattern, count} -> -count end)
    |> Enum.take(10)
  end
  
  defp pattern_signature(activities) do
    Enum.map(activities, &{&1.intent, &1.action})
  end
  
  defp generate_workflow_recommendations(workflows) do
    workflows
    |> Enum.filter(&(&1.success_rate < 0.7))
    |> Enum.map(fn workflow ->
      "Improve #{workflow.intent} workflow - current success rate: #{Float.round(workflow.success_rate * 100, 1)}%"
    end)
  end
  
  defp most_common_files(activities) do
    activities
    |> Enum.map(& &1.file)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_file, count} -> -count end)
    |> Enum.take(5)
    |> Enum.map(&elem(&1, 0))
  end
  
  defp classify_errors(failures) do
    failures
    |> Enum.map(&extract_error_type/1)
    |> Enum.frequencies()
  end
  
  defp extract_error_type(activity) do
    cond do
      String.contains?(activity[:details] || "", "undefined") -> :undefined_error
      String.contains?(activity[:details] || "", "syntax") -> :syntax_error
      String.contains?(activity[:details] || "", "timeout") -> :timeout_error
      true -> :general_error
    end
  end
  
  defp analyze_time_distribution(activities) do
    activities
    |> Enum.map(& &1.timestamp.hour)
    |> Enum.frequencies()
  end
  
  defp find_recovery_patterns(activities) do
    activities
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [a, b] ->
      a[:outcome] == :failure and b[:outcome] == :success
    end)
    |> Enum.map(fn [failure, success] ->
      %{
        failure_type: extract_error_type(failure),
        recovery_action: success.action,
        recovery_intent: success.intent
      }
    end)
    |> Enum.frequencies()
  end
  
  defp average(numbers) when length(numbers) > 0 do
    Enum.sum(numbers) / length(numbers)
  end
  defp average(_), do: 0.0
  
  defp standard_deviation(numbers) when length(numbers) > 1 do
    avg = average(numbers)
    variance = numbers
    |> Enum.map(fn n -> :math.pow(n - avg, 2) end)
    |> average()
    
    :math.sqrt(variance)
  end
  defp standard_deviation(_), do: 0.0
  
  defp sum_durations(activities) do
    activities
    |> Enum.map(& &1.duration_ms)
    |> Enum.sum()
  end
  
  defp average_duration(activities) do
    durations = Enum.map(activities, & &1.duration_ms)
    average(durations)
  end
  
  defp find_bottlenecks(activities) do
    activities
    |> Enum.filter(&(&1[:duration_ms] && &1.duration_ms > 1000))
    |> Enum.sort_by(&(-&1.duration_ms))
    |> Enum.take(10)
    |> Enum.map(fn activity ->
      %{
        activity: "#{activity.action} #{activity.file}",
        duration_ms: activity.duration_ms,
        intent: activity.intent
      }
    end)
  end
  
  defp find_optimization_opportunities(activities) do
    # Find repeated operations that could be batched
    repeated_ops = activities
    |> Enum.chunk_by(&{&1.action, &1.intent})
    |> Enum.filter(&(length(&1) > 3))
    |> Enum.map(fn chunk ->
      %{
        operation: "#{hd(chunk).action} for #{hd(chunk).intent}",
        count: length(chunk),
        potential_savings: estimate_batch_savings(chunk)
      }
    end)
    
    repeated_ops
  end
  
  defp estimate_batch_savings(activities) do
    total_duration = activities
    |> Enum.map(&(&1[:duration_ms] || 100))
    |> Enum.sum()
    
    # Estimate 70% savings from batching
    round(total_duration * 0.7)
  end
  
  defp find_successful_sequences(activities) do
    activities
    |> Enum.chunk_every(5, 1, :discard)
    |> Enum.filter(fn chunk ->
      Enum.all?(chunk, &(&1[:outcome] == :success))
    end)
  end
  
  defp describe_sequence(activities) do
    activities
    |> Enum.map(&"#{&1.action} #{&1.intent}")
    |> Enum.join(" → ")
  end
  
  defp count_sequence_occurrences(sequence, all_activities) do
    sequence_pattern = pattern_signature(sequence)
    
    all_activities
    |> Enum.chunk_every(length(sequence), 1, :discard)
    |> Enum.count(&(pattern_signature(&1) == sequence_pattern))
  end
  
  defp calculate_sequence_success_rate(sequence, all_activities) do
    sequence_pattern = pattern_signature(sequence)
    
    matching_sequences = all_activities
    |> Enum.chunk_every(length(sequence), 1, :discard)
    |> Enum.filter(&(pattern_signature(&1) == sequence_pattern))
    
    if length(matching_sequences) > 0 do
      successful = Enum.count(matching_sequences, fn seq ->
        Enum.all?(seq, &(&1[:outcome] != :failure))
      end)
      
      successful / length(matching_sequences)
    else
      0.0
    end
  end
  
  defp is_sequence_learnable?(sequence) do
    length(sequence) >= 2 and length(sequence) <= 7
  end
  
  defp find_unique_approaches(activities) do
    activities
    |> Enum.group_by(&{&1.intent, &1[:outcome]})
    |> Enum.map(fn {{intent, outcome}, group} ->
      approaches = group
      |> Enum.map(&extract_approach/1)
      |> Enum.uniq()
      
      %{
        intent: intent,
        outcome: outcome,
        unique_approaches: length(approaches),
        approaches: Enum.take(approaches, 3)
      }
    end)
  end
  
  defp extract_approach(activity) do
    %{
      action: activity.action,
      file_type: Path.extname(activity.file),
      details: activity[:details]
    }
  end
  
  defp identify_improvement_areas(activities) do
    # Find intents with low success rates
    activities
    |> Enum.group_by(& &1.intent)
    |> Enum.map(fn {intent, acts} ->
      success_rate = calculate_workflow_success_rate(acts)
      {intent, success_rate}
    end)
    |> Enum.filter(fn {_intent, rate} -> rate < 0.7 end)
    |> Enum.sort_by(fn {_intent, rate} -> rate end)
    |> Enum.map(fn {intent, rate} ->
      %{
        intent: intent,
        current_success_rate: rate,
        improvement_needed: (0.8 - rate) * 100
      }
    end)
  end
  
  defp generate_training_recommendations(opportunities) do
    opportunities
    |> Enum.filter(&(&1.success_rate > 0.9))
    |> Enum.sort_by(&(-&1.frequency))
    |> Enum.take(5)
    |> Enum.map(fn opp ->
      "Learn pattern: #{opp.pattern} (#{opp.frequency} occurrences, #{Float.round(opp.success_rate * 100, 1)}% success)"
    end)
  end
  
  defp generate_error_prevention_recommendations(error_patterns) do
    error_patterns
    |> Enum.sort_by(&(-&1.failure_count))
    |> Enum.take(3)
    |> Enum.flat_map(fn pattern ->
      pattern.error_types
      |> Enum.map(fn {error_type, count} ->
        "Prevent #{error_type} in #{pattern.intent} (#{count} occurrences)"
      end)
    end)
  end
end