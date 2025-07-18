defmodule Crod.ActivityIntelligence do
  @moduledoc """
  Intelligence engine for analyzing Claude's activities.
  Learns patterns, detects success/failure, and feeds CROD's neural network.
  """
  
  use GenServer
  require Logger
  alias Crod.{Brain, Patterns, Memory}
  
  @activity_log_dir "/home/bacardi/crodidocker/claude-activity-logs"
  @pattern_threshold 0.7
  @learning_rate 0.1
  
  defstruct [
    :current_session,
    :activity_buffer,
    :pattern_cache,
    :success_patterns,
    :failure_patterns,
    :workflow_map
  ]
  
  # Public API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def track_activity(activity) do
    GenServer.cast(__MODULE__, {:track_activity, activity})
  end
  
  def analyze_session(session_id) do
    GenServer.call(__MODULE__, {:analyze_session, session_id})
  end
  
  def get_patterns(type \\ :all) do
    GenServer.call(__MODULE__, {:get_patterns, type})
  end
  
  def learn_from_outcome(activity_id, outcome) do
    GenServer.cast(__MODULE__, {:learn_outcome, activity_id, outcome})
  end
  
  # Callbacks
  
  @impl true
  def init(_opts) do
    state = %__MODULE__{
      current_session: generate_session_id(),
      activity_buffer: [],
      pattern_cache: %{},
      success_patterns: load_patterns("success"),
      failure_patterns: load_patterns("failures"),
      workflow_map: %{}
    }
    
    # Start monitoring activity logs
    schedule_log_check()
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:track_activity, activity}, state) do
    # Add to buffer
    activity_with_id = Map.put(activity, :id, generate_activity_id())
    new_buffer = [activity_with_id | state.activity_buffer]
    
    # Analyze for patterns
    patterns = extract_patterns(activity_with_id, state)
    
    # Update workflow map
    workflow = update_workflow(activity_with_id, state.workflow_map)
    
    # Feed to CROD brain if significant
    if significant_activity?(activity_with_id) do
      feed_to_brain(activity_with_id, patterns)
    end
    
    new_state = %{state | 
      activity_buffer: Enum.take(new_buffer, 1000),
      workflow_map: workflow
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_cast({:learn_outcome, activity_id, outcome}, state) do
    # Find activity in buffer
    case find_activity(activity_id, state.activity_buffer) do
      nil -> 
        {:noreply, state}
        
      activity ->
        # Update pattern collections
        new_state = case outcome do
          :success -> 
            patterns = Map.put(state.success_patterns, activity.intent, activity)
            save_pattern("success", activity)
            %{state | success_patterns: patterns}
            
          :failure ->
            patterns = Map.put(state.failure_patterns, activity.intent, activity)
            save_pattern("failures", activity)
            %{state | failure_patterns: patterns}
            
          _ ->
            state
        end
        
        {:noreply, new_state}
    end
  end
  
  @impl true
  def handle_call({:analyze_session, session_id}, _from, state) do
    analysis = %{
      session_id: session_id,
      total_activities: length(state.activity_buffer),
      success_rate: calculate_success_rate(state),
      common_patterns: extract_common_patterns(state),
      workflow_efficiency: analyze_workflow_efficiency(state.workflow_map),
      recommendations: generate_recommendations(state)
    }
    
    {:reply, analysis, state}
  end
  
  @impl true
  def handle_call({:get_patterns, type}, _from, state) do
    patterns = case type do
      :success -> state.success_patterns
      :failure -> state.failure_patterns
      :all -> Map.merge(state.success_patterns, state.failure_patterns)
    end
    
    {:reply, patterns, state}
  end
  
  @impl true
  def handle_info(:check_logs, state) do
    # Read new activity logs
    new_activities = read_recent_logs()
    
    # Process each activity
    state = Enum.reduce(new_activities, state, fn activity, acc ->
      {:noreply, new_state} = handle_cast({:track_activity, activity}, acc)
      new_state
    end)
    
    schedule_log_check()
    {:noreply, state}
  end
  
  # Private functions
  
  defp generate_session_id do
    "session_#{:os.system_time(:millisecond)}"
  end
  
  defp generate_activity_id do
    "activity_#{:os.system_time(:nanosecond)}"
  end
  
  defp load_patterns(type) do
    pattern_dir = Path.join([@activity_log_dir, "patterns", type])
    
    case File.ls(pattern_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".jsonl"))
        |> Enum.flat_map(fn file ->
          Path.join(pattern_dir, file)
          |> File.stream!()
          |> Enum.map(&Jason.decode!/1)
        end)
        |> Enum.group_by(& &1["intent"])
        
      _ ->
        %{}
    end
  end
  
  defp save_pattern(type, activity) do
    date = Date.utc_today() |> Date.to_string()
    file_path = Path.join([@activity_log_dir, "patterns", type, "#{date}.jsonl"])
    
    File.write!(file_path, Jason.encode!(activity) <> "\n", [:append])
  end
  
  defp extract_patterns(activity, state) do
    # Compare with known patterns
    success_match = find_matching_patterns(activity, state.success_patterns)
    failure_match = find_matching_patterns(activity, state.failure_patterns)
    
    %{
      success_similarity: success_match,
      failure_similarity: failure_match,
      novel: success_match < @pattern_threshold && failure_match < @pattern_threshold
    }
  end
  
  defp find_matching_patterns(activity, pattern_groups) do
    pattern_groups
    |> Map.get(activity.intent, [])
    |> Enum.map(fn pattern ->
      similarity_score(activity, pattern)
    end)
    |> Enum.max(fn -> 0.0 end)
  end
  
  defp similarity_score(activity1, activity2) do
    # Simple similarity based on action and file type
    action_match = if activity1[:action] == activity2["action"], do: 0.5, else: 0.0
    file_match = if similar_files?(activity1[:file], activity2["file"]), do: 0.5, else: 0.0
    
    action_match + file_match
  end
  
  defp similar_files?(file1, file2) when is_binary(file1) and is_binary(file2) do
    ext1 = Path.extname(file1)
    ext2 = Path.extname(file2)
    
    ext1 == ext2 || String.contains?(file1, file2) || String.contains?(file2, file1)
  end
  defp similar_files?(_, _), do: false
  
  defp significant_activity?(activity) do
    # Filter out noise
    activity.intent not in ["unknown"] &&
    activity.action not in ["open", "close"] &&
    !String.contains?(activity.file || "", "claude-activity-logs")
  end
  
  defp feed_to_brain(activity, patterns) do
    # Convert to CROD pattern format
    crod_pattern = %{
      input: "#{activity.intent} #{activity.action}",
      output: activity.file,
      confidence: if(patterns.novel, do: 0.5, else: 0.9),
      metadata: %{
        timestamp: activity.timestamp,
        patterns: patterns
      }
    }
    
    # Send to brain
    Brain.process(crod_pattern.input, %{pattern: crod_pattern})
    
    # Store in memory
    Memory.store(:long_term, activity.id, crod_pattern)
  end
  
  defp update_workflow(activity, workflow_map) do
    intent = activity.intent
    current_workflow = Map.get(workflow_map, intent, %{
      steps: [],
      success_count: 0,
      failure_count: 0
    })
    
    updated = %{current_workflow |
      steps: [activity | current_workflow.steps] |> Enum.take(50)
    }
    
    Map.put(workflow_map, intent, updated)
  end
  
  defp find_activity(activity_id, buffer) do
    Enum.find(buffer, fn a -> a.id == activity_id end)
  end
  
  defp calculate_success_rate(state) do
    total = length(state.activity_buffer)
    if total == 0 do
      0.0
    else
      # This would need actual success tracking
      0.75 # Placeholder
    end
  end
  
  defp extract_common_patterns(state) do
    state.activity_buffer
    |> Enum.group_by(& &1.intent)
    |> Enum.map(fn {intent, activities} ->
      %{
        intent: intent,
        count: length(activities),
        common_actions: activities 
          |> Enum.map(& &1.action) 
          |> Enum.frequencies()
          |> Enum.sort_by(fn {_, count} -> -count end)
          |> Enum.take(3)
      }
    end)
    |> Enum.sort_by(& -&1.count)
    |> Enum.take(5)
  end
  
  defp analyze_workflow_efficiency(workflow_map) do
    workflow_map
    |> Enum.map(fn {intent, workflow} ->
      %{
        intent: intent,
        avg_steps: length(workflow.steps),
        efficiency_score: calculate_efficiency(workflow)
      }
    end)
  end
  
  defp calculate_efficiency(workflow) do
    # Simple efficiency based on success/failure ratio
    total = workflow.success_count + workflow.failure_count
    if total == 0 do
      0.5
    else
      workflow.success_count / total
    end
  end
  
  defp generate_recommendations(state) do
    # Analyze patterns and suggest improvements
    common_failures = state.failure_patterns
      |> Enum.flat_map(fn {_, patterns} -> patterns end)
      |> Enum.take(5)
    
    recommendations = Enum.map(common_failures, fn failure ->
      %{
        issue: "Repeated failure in #{failure["intent"]}",
        suggestion: suggest_fix(failure),
        similar_success: find_similar_success(failure, state.success_patterns)
      }
    end)
    
    recommendations
  end
  
  defp suggest_fix(failure) do
    case failure["intent"] do
      "mcp_configuration" -> "Check @behaviour implementation and module references"
      "testing" -> "Ensure database is running before tests"
      "elixir_development" -> "Run mix format and check for compilation warnings"
      _ -> "Review similar successful patterns"
    end
  end
  
  defp find_similar_success(failure, success_patterns) do
    success_patterns
    |> Map.get(failure["intent"], [])
    |> Enum.max_by(fn success -> similarity_score(failure, success) end, fn -> nil end)
  end
  
  defp read_recent_logs do
    # Read from current session log
    session_file = Path.join(@activity_log_dir, "current-session.jsonl")
    
    if File.exists?(session_file) do
      session_file
      |> File.stream!()
      |> Stream.take(-100) # Last 100 entries
      |> Enum.map(&Jason.decode!/1)
      |> Enum.filter(fn log -> 
        log["event_type"] == "file_operation" && 
        log["timestamp"] != nil
      end)
    else
      []
    end
  end
  
  defp schedule_log_check do
    Process.send_after(self(), :check_logs, 30_000) # Check every 30 seconds
  end
end