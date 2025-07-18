defmodule Crod.WorkflowOptimizer do
  @moduledoc """
  Analyzes activity patterns to identify and optimize workflows.
  Learns from successful patterns and suggests improvements.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{ActivityIntelligence, Patterns, Brain}
  
  @optimization_threshold 0.7
  @pattern_min_occurrences 3
  @analysis_window_minutes 60
  
  defstruct [
    :workflows,
    :optimizations,
    :performance_history,
    :learning_enabled
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def analyze_workflow(activities) do
    GenServer.call(__MODULE__, {:analyze_workflow, activities})
  end
  
  def get_optimizations(workflow_id) do
    GenServer.call(__MODULE__, {:get_optimizations, workflow_id})
  end
  
  def suggest_next_action(current_context) do
    GenServer.call(__MODULE__, {:suggest_next_action, current_context})
  end
  
  def learn_from_outcome(workflow_id, outcome) do
    GenServer.cast(__MODULE__, {:learn_from_outcome, workflow_id, outcome})
  end
  
  def get_workflow_stats do
    GenServer.call(__MODULE__, :get_workflow_stats)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      workflows: %{},
      optimizations: %{},
      performance_history: [],
      learning_enabled: true
    }
    
    # Schedule periodic analysis
    :timer.send_interval(:timer.minutes(5), self(), :analyze_recent_workflows)
    
    {:ok, state}
  end
  
  def handle_call({:analyze_workflow, activities}, _from, state) do
    workflow = extract_workflow(activities)
    optimizations = identify_optimizations(workflow, state)
    
    # Store workflow and optimizations
    workflow_id = generate_workflow_id(workflow)
    
    new_state = state
    |> put_in([:workflows, workflow_id], workflow)
    |> put_in([:optimizations, workflow_id], optimizations)
    
    {:reply, {:ok, workflow_id, optimizations}, new_state}
  end
  
  def handle_call({:get_optimizations, workflow_id}, _from, state) do
    optimizations = get_in(state.optimizations, [workflow_id]) || []
    {:reply, optimizations, state}
  end
  
  def handle_call({:suggest_next_action, context}, _from, state) do
    suggestion = generate_suggestion(context, state)
    {:reply, suggestion, state}
  end
  
  def handle_call(:get_workflow_stats, _from, state) do
    stats = calculate_workflow_stats(state)
    {:reply, stats, state}
  end
  
  def handle_cast({:learn_from_outcome, workflow_id, outcome}, state) do
    new_state = update_workflow_performance(state, workflow_id, outcome)
    
    # Learn patterns if successful
    if outcome == :success and state.learning_enabled do
      learn_successful_patterns(workflow_id, new_state)
    end
    
    {:noreply, new_state}
  end
  
  def handle_info(:analyze_recent_workflows, state) do
    # Get recent activities
    activities = ActivityIntelligence.get_recent_activities(@analysis_window_minutes)
    
    # Group into workflows
    workflows = group_into_workflows(activities)
    
    # Analyze each workflow
    new_state = Enum.reduce(workflows, state, fn workflow, acc ->
      workflow_id = generate_workflow_id(workflow)
      optimizations = identify_optimizations(workflow, acc)
      
      acc
      |> put_in([:workflows, workflow_id], workflow)
      |> put_in([:optimizations, workflow_id], optimizations)
    end)
    
    {:noreply, new_state}
  end
  
  # Private Functions
  
  defp extract_workflow(activities) do
    activities
    |> Enum.sort_by(& &1.timestamp)
    |> Enum.map(fn activity ->
      %{
        action: activity.action,
        intent: activity.intent,
        file: activity.file,
        duration: activity[:duration_ms] || 0,
        outcome: activity[:outcome],
        timestamp: activity.timestamp
      }
    end)
    |> identify_workflow_boundaries()
    |> add_workflow_metadata()
  end
  
  defp identify_workflow_boundaries(activities) do
    # Group activities that are close in time and related
    activities
    |> Enum.chunk_while(
      [],
      fn activity, acc ->
        case acc do
          [] -> 
            {:cont, [activity]}
          [last | _] ->
            time_diff = DateTime.diff(activity.timestamp, last.timestamp, :second)
            
            # Same workflow if within 5 minutes and related
            if time_diff < 300 and related_activities?(activity, last) do
              {:cont, [activity | acc]}
            else
              {:cont, Enum.reverse(acc), [activity]}
            end
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.reverse(acc), []}
      end
    )
    |> Enum.reject(&Enum.empty?/1)
  end
  
  defp related_activities?(a1, a2) do
    # Activities are related if they share intent or work on related files
    a1.intent == a2.intent or
    Path.dirname(a1.file) == Path.dirname(a2.file) or
    String.contains?(a1.file, Path.basename(a2.file, Path.extname(a2.file)))
  end
  
  defp add_workflow_metadata(workflow_groups) do
    Enum.map(workflow_groups, fn activities ->
      %{
        steps: activities,
        total_duration: calculate_total_duration(activities),
        intent: most_common_intent(activities),
        files_touched: unique_files(activities),
        success_rate: calculate_success_rate(activities),
        complexity: calculate_complexity(activities)
      }
    end)
  end
  
  defp identify_optimizations(workflow, state) do
    optimizations = []
    
    # Check for redundant steps
    optimizations = optimizations ++ identify_redundant_steps(workflow)
    
    # Check for inefficient patterns
    optimizations = optimizations ++ identify_inefficient_patterns(workflow, state)
    
    # Check for missing steps based on successful workflows
    optimizations = optimizations ++ identify_missing_steps(workflow, state)
    
    # Check for ordering improvements
    optimizations = optimizations ++ suggest_reordering(workflow)
    
    # Rank optimizations by potential impact
    optimizations
    |> Enum.map(&add_impact_score(&1, workflow))
    |> Enum.sort_by(& &1.impact_score, :desc)
  end
  
  defp identify_redundant_steps(workflow) do
    workflow.steps
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {step, index}, {seen, opts} ->
      similar = Enum.find_index(seen, &similar_steps?(&1.step, step))
      
      if similar do
        opt = %{
          type: :remove_redundant,
          description: "Remove redundant #{step.action} on #{step.file}",
          step_index: index,
          similar_to: similar,
          confidence: 0.8
        }
        {seen, [opt | opts]}
      else
        {[{step, index} | seen], opts}
      end
    end)
    |> elem(1)
  end
  
  defp identify_inefficient_patterns(workflow, state) do
    known_inefficiencies = [
      # Multiple test runs without code changes
      %{
        pattern: fn steps ->
          consecutive_tests = steps
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.filter(fn [a, b] ->
            a.intent == "testing" and b.intent == "testing" and
            a.outcome == :failure and b.outcome == :failure
          end)
          
          length(consecutive_tests) > 0
        end,
        optimization: "Run tests once, fix all issues, then re-run"
      },
      
      # Reading same file multiple times
      %{
        pattern: fn steps ->
          reads = Enum.filter(steps, &(&1.action == "read"))
          duplicates = reads
          |> Enum.frequencies_by(& &1.file)
          |> Enum.filter(fn {_file, count} -> count > 2 end)
          
          map_size(duplicates) > 0
        end,
        optimization: "Cache file contents to avoid repeated reads"
      }
    ]
    
    known_inefficiencies
    |> Enum.filter(fn %{pattern: pattern} -> pattern.(workflow.steps) end)
    |> Enum.map(fn %{optimization: opt} ->
      %{
        type: :inefficiency,
        description: opt,
        confidence: 0.7
      }
    end)
  end
  
  defp identify_missing_steps(workflow, state) do
    # Compare with successful workflows of same intent
    similar_workflows = get_similar_successful_workflows(workflow, state)
    
    if length(similar_workflows) >= @pattern_min_occurrences do
      common_steps = extract_common_steps(similar_workflows)
      current_steps = MapSet.new(workflow.steps, &{&1.action, &1.intent})
      
      missing = MapSet.difference(common_steps, current_steps)
      
      MapSet.to_list(missing)
      |> Enum.map(fn {action, intent} ->
        %{
          type: :missing_step,
          description: "Consider adding #{action} for #{intent}",
          action: action,
          intent: intent,
          confidence: 0.6
        }
      end)
    else
      []
    end
  end
  
  defp suggest_reordering(workflow) do
    # Suggest running reads before writes
    read_write_issues = workflow.steps
    |> Enum.with_index()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [{s1, _}, {s2, _}] ->
      s1.action in ["write", "modify"] and s2.action == "read" and
      s1.file == s2.file
    end)
    
    Enum.map(read_write_issues, fn [{_s1, i1}, {_s2, i2}] ->
      %{
        type: :reorder,
        description: "Read file before modifying it",
        swap_indices: {i1, i2},
        confidence: 0.9
      }
    end)
  end
  
  defp generate_suggestion(context, state) do
    # Find workflows that started similarly
    matching_workflows = find_matching_workflows(context, state)
    
    if length(matching_workflows) > 0 do
      # Get the most successful workflow
      best_workflow = matching_workflows
      |> Enum.max_by(& &1.success_rate)
      
      # Find next step in that workflow
      current_step_index = find_current_position(context, best_workflow)
      
      if current_step_index < length(best_workflow.steps) - 1 do
        next_step = Enum.at(best_workflow.steps, current_step_index + 1)
        
        %{
          action: next_step.action,
          intent: next_step.intent,
          file: suggest_file_mapping(next_step.file, context),
          confidence: calculate_suggestion_confidence(matching_workflows),
          reasoning: "Based on #{length(matching_workflows)} similar successful workflows"
        }
      else
        %{action: :complete, reasoning: "Workflow appears complete"}
      end
    else
      %{action: :explore, reasoning: "No similar workflows found"}
    end
  end
  
  defp group_into_workflows(activities) do
    activities
    |> Enum.sort_by(& &1.timestamp)
    |> identify_workflow_boundaries()
    |> Enum.map(&add_workflow_metadata/1)
  end
  
  defp generate_workflow_id(workflow) do
    content = "#{workflow.intent}_#{length(workflow.steps)}_#{workflow.complexity}"
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower) |> String.slice(0..7)
  end
  
  defp calculate_total_duration(steps) do
    case steps do
      [] -> 0
      [_] -> 0
      steps ->
        first = List.first(steps)
        last = List.last(steps)
        DateTime.diff(last.timestamp, first.timestamp, :millisecond)
    end
  end
  
  defp most_common_intent(steps) do
    steps
    |> Enum.frequencies_by(& &1.intent)
    |> Enum.max_by(fn {_intent, count} -> count end)
    |> elem(0)
  end
  
  defp unique_files(steps) do
    steps
    |> Enum.map(& &1.file)
    |> Enum.uniq()
  end
  
  defp calculate_success_rate(steps) do
    total = length(steps)
    successful = Enum.count(steps, &(&1.outcome == :success))
    
    if total > 0, do: successful / total, else: 0.0
  end
  
  defp calculate_complexity(steps) do
    # Complexity based on: number of steps, unique files, different intents
    num_steps = length(steps)
    num_files = length(unique_files(steps))
    num_intents = steps |> Enum.map(& &1.intent) |> Enum.uniq() |> length()
    
    (num_steps * 0.4 + num_files * 0.4 + num_intents * 0.2) / 10
  end
  
  defp similar_steps?(s1, s2) do
    s1.action == s2.action and s1.file == s2.file and s1.intent == s2.intent
  end
  
  defp add_impact_score(optimization, workflow) do
    base_score = case optimization.type do
      :remove_redundant -> 0.8
      :inefficiency -> 0.7
      :reorder -> 0.9
      :missing_step -> 0.6
      _ -> 0.5
    end
    
    # Adjust based on workflow complexity
    adjusted_score = base_score * (1 + workflow.complexity * 0.2)
    
    Map.put(optimization, :impact_score, adjusted_score * optimization.confidence)
  end
  
  defp get_similar_successful_workflows(workflow, state) do
    state.workflows
    |> Enum.filter(fn {_id, w} ->
      w.intent == workflow.intent and
      w.success_rate > @optimization_threshold and
      similar_complexity?(w, workflow)
    end)
    |> Enum.map(&elem(&1, 1))
  end
  
  defp similar_complexity?(w1, w2) do
    abs(w1.complexity - w2.complexity) < 0.3
  end
  
  defp extract_common_steps(workflows) do
    workflows
    |> Enum.flat_map(& &1.steps)
    |> Enum.map(&{&1.action, &1.intent})
    |> Enum.frequencies()
    |> Enum.filter(fn {_step, count} -> count >= length(workflows) * 0.7 end)
    |> Enum.map(&elem(&1, 0))
    |> MapSet.new()
  end
  
  defp update_workflow_performance(state, workflow_id, outcome) do
    workflow = get_in(state.workflows, [workflow_id])
    
    if workflow do
      performance = %{
        workflow_id: workflow_id,
        outcome: outcome,
        timestamp: DateTime.utc_now(),
        duration: workflow.total_duration,
        complexity: workflow.complexity
      }
      
      update_in(state.performance_history, &[performance | &1])
      |> update_in([:performance_history], &Enum.take(&1, 1000))
    else
      state
    end
  end
  
  defp learn_successful_patterns(workflow_id, state) do
    workflow = get_in(state.workflows, [workflow_id])
    
    if workflow and workflow.success_rate > @optimization_threshold do
      # Extract patterns from successful workflow
      patterns = extract_workflow_patterns(workflow)
      
      # Learn each pattern
      Enum.each(patterns, fn pattern ->
        Patterns.learn_pattern(
          pattern.input,
          pattern.output,
          metadata: %{
            source: "workflow_optimizer",
            workflow_id: workflow_id,
            confidence: workflow.success_rate
          }
        )
      end)
    end
  end
  
  defp extract_workflow_patterns(workflow) do
    workflow.steps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [step1, step2] ->
      %{
        input: "After #{step1.action} #{step1.file} for #{step1.intent}",
        output: "Do #{step2.action} #{step2.file} for #{step2.intent}"
      }
    end)
  end
  
  defp find_matching_workflows(context, state) do
    current_intent = context[:intent] || "unknown"
    current_files = MapSet.new(context[:files] || [])
    
    state.workflows
    |> Enum.filter(fn {_id, workflow} ->
      workflow.intent == current_intent or
      MapSet.intersection(MapSet.new(workflow.files_touched), current_files) |> MapSet.size() > 0
    end)
    |> Enum.map(&elem(&1, 1))
  end
  
  defp find_current_position(context, workflow) do
    recent_actions = context[:recent_actions] || []
    
    # Find the best match for current position in workflow
    workflow.steps
    |> Enum.with_index()
    |> Enum.reduce({-1, 0}, fn {step, index}, {best_index, best_score} ->
      score = calculate_match_score(step, recent_actions)
      
      if score > best_score do
        {index, score}
      else
        {best_index, best_score}
      end
    end)
    |> elem(0)
  end
  
  defp calculate_match_score(step, recent_actions) do
    recent_actions
    |> Enum.map(fn action ->
      cond do
        action.file == step.file and action.action == step.action -> 1.0
        action.intent == step.intent -> 0.5
        action.action == step.action -> 0.3
        true -> 0.0
      end
    end)
    |> Enum.sum()
  end
  
  defp suggest_file_mapping(template_file, context) do
    # Try to map template file to actual file in context
    current_files = context[:files] || []
    
    # Find best match
    best_match = current_files
    |> Enum.max_by(fn file ->
      path_similarity(template_file, file)
    end, fn -> template_file end)
    
    best_match
  end
  
  defp path_similarity(path1, path2) do
    parts1 = Path.split(path1)
    parts2 = Path.split(path2)
    
    # Calculate similarity based on common parts
    common = Enum.zip(Enum.reverse(parts1), Enum.reverse(parts2))
    |> Enum.take_while(fn {p1, p2} -> p1 == p2 end)
    |> length()
    
    common / max(length(parts1), length(parts2))
  end
  
  defp calculate_suggestion_confidence(workflows) do
    # Higher confidence with more examples and higher success rates
    count_factor = min(length(workflows) / 10, 1.0)
    success_rates = Enum.map(workflows, & &1.success_rate)
    success_factor = Enum.sum(success_rates) / length(workflows)
    
    count_factor * 0.5 + success_factor * 0.5
  end
  
  defp calculate_workflow_stats(state) do
    total_workflows = map_size(state.workflows)
    
    success_rates = state.workflows
    |> Enum.map(fn {_id, w} -> w.success_rate end)
    
    optimization_counts = state.optimizations
    |> Enum.map(fn {_id, opts} -> length(opts) end)
    
    %{
      total_workflows: total_workflows,
      avg_success_rate: if(total_workflows > 0, do: Enum.sum(success_rates) / total_workflows, else: 0),
      total_optimizations: Enum.sum(optimization_counts),
      avg_optimizations_per_workflow: if(total_workflows > 0, do: Enum.sum(optimization_counts) / total_workflows, else: 0),
      performance_history_size: length(state.performance_history),
      top_intents: get_top_intents(state.workflows)
    }
  end
  
  defp get_top_intents(workflows) do
    workflows
    |> Enum.map(fn {_id, w} -> w.intent end)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_intent, count} -> -count end)
    |> Enum.take(5)
  end
end