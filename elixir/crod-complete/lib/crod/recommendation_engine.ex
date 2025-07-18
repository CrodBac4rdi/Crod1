defmodule Crod.RecommendationEngine do
  @moduledoc """
  Generates intelligent recommendations based on patterns, failures, and historical data.
  Helps Claude make better decisions and avoid past mistakes.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{
    ActivityIntelligence,
    Patterns,
    WorkflowOptimizer,
    SuccessFailureClassifier,
    Brain,
    Memory
  }
  
  @recommendation_cache_ttl 300_000  # 5 minutes
  @confidence_threshold 0.7
  @max_recommendations 10
  
  defstruct [
    :recommendation_cache,
    :failure_patterns,
    :success_patterns,
    :context_history,
    :learning_enabled
  ]
  
  # Recommendation types
  @recommendation_types %{
    next_action: "What to do next",
    avoid_mistake: "Common mistake to avoid",
    optimization: "Performance improvement",
    best_practice: "Recommended approach",
    alternative: "Alternative solution",
    prerequisite: "Required before proceeding",
    validation: "Check before continuing"
  }
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get_recommendations(context) do
    GenServer.call(__MODULE__, {:get_recommendations, context})
  end
  
  def get_specific_recommendation(type, context) do
    GenServer.call(__MODULE__, {:get_specific, type, context})
  end
  
  def learn_from_outcome(recommendation_id, outcome) do
    GenServer.cast(__MODULE__, {:learn_from_outcome, recommendation_id, outcome})
  end
  
  def clear_cache do
    GenServer.cast(__MODULE__, :clear_cache)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      recommendation_cache: %{},
      failure_patterns: load_failure_patterns(),
      success_patterns: load_success_patterns(),
      context_history: [],
      learning_enabled: true
    }
    
    # Schedule cache cleanup
    :timer.send_interval(60_000, self(), :cleanup_cache)
    
    Logger.info("💡 Recommendation Engine initialized")
    
    {:ok, state}
  end
  
  def handle_call({:get_recommendations, context}, _from, state) do
    cache_key = generate_cache_key(context)
    
    recommendations = case get_cached_recommendations(state, cache_key) do
      nil ->
        # Generate new recommendations
        recs = generate_recommendations(context, state)
        
        # Cache them
        new_cache = Map.put(state.recommendation_cache, cache_key, %{
          recommendations: recs,
          timestamp: System.system_time(:millisecond)
        })
        
        {recs, %{state | recommendation_cache: new_cache}}
      
      cached ->
        {cached, state}
    end
    
    # Update context history
    new_state = elem(recommendations, 1)
    |> update_context_history(context)
    
    {:reply, elem(recommendations, 0), new_state}
  end
  
  def handle_call({:get_specific, type, context}, _from, state) do
    recommendation = generate_specific_recommendation(type, context, state)
    {:reply, recommendation, state}
  end
  
  def handle_cast({:learn_from_outcome, recommendation_id, outcome}, state) do
    new_state = process_recommendation_feedback(state, recommendation_id, outcome)
    {:noreply, new_state}
  end
  
  def handle_cast(:clear_cache, state) do
    {:noreply, %{state | recommendation_cache: %{}}}
  end
  
  def handle_info(:cleanup_cache, state) do
    now = System.system_time(:millisecond)
    
    new_cache = state.recommendation_cache
    |> Enum.filter(fn {_key, entry} ->
      now - entry.timestamp < @recommendation_cache_ttl
    end)
    |> Enum.into(%{})
    
    {:noreply, %{state | recommendation_cache: new_cache}}
  end
  
  # Private Functions
  
  defp load_failure_patterns do
    # Load common failure patterns from activity intelligence
    ActivityIntelligence.get_patterns(:failure)
    |> Map.values()
    |> Enum.filter(&(&1.confidence > 0.6))
    |> Enum.map(fn pattern ->
      %{
        pattern: pattern.pattern,
        frequency: pattern.count,
        last_seen: pattern.last_seen,
        context: pattern.context
      }
    end)
  end
  
  defp load_success_patterns do
    # Load successful patterns
    ActivityIntelligence.get_patterns(:success)
    |> Map.values()
    |> Enum.filter(&(&1.confidence > 0.8))
    |> Enum.map(fn pattern ->
      %{
        pattern: pattern.pattern,
        frequency: pattern.count,
        context: pattern.context
      }
    end)
  end
  
  defp get_cached_recommendations(state, key) do
    case Map.get(state.recommendation_cache, key) do
      nil -> nil
      entry ->
        if System.system_time(:millisecond) - entry.timestamp < @recommendation_cache_ttl do
          entry.recommendations
        else
          nil
        end
    end
  end
  
  defp generate_cache_key(context) do
    # Create deterministic key from context
    relevant_fields = Map.take(context, [:intent, :action, :files, :recent_failures])
    :erlang.phash2(relevant_fields)
  end
  
  defp generate_recommendations(context, state) do
    recommendations = []
    
    # Get next action recommendations
    recommendations = recommendations ++ generate_next_action_recommendations(context, state)
    
    # Get mistake avoidance recommendations
    recommendations = recommendations ++ generate_mistake_avoidance_recommendations(context, state)
    
    # Get optimization recommendations
    recommendations = recommendations ++ generate_optimization_recommendations(context, state)
    
    # Get best practice recommendations
    recommendations = recommendations ++ generate_best_practice_recommendations(context, state)
    
    # Get validation recommendations
    recommendations = recommendations ++ generate_validation_recommendations(context, state)
    
    # Sort by relevance and confidence
    recommendations
    |> Enum.sort_by(&(-&1.relevance_score * &1.confidence))
    |> Enum.take(@max_recommendations)
    |> Enum.map(&add_recommendation_id/1)
  end
  
  defp generate_next_action_recommendations(context, state) do
    # Get workflow suggestions
    workflow_suggestions = case context[:recent_actions] do
      actions when is_list(actions) and length(actions) > 0 ->
        WorkflowOptimizer.suggest_next_action(context)
        |> List.wrap()
        |> Enum.map(fn suggestion ->
          %{
            type: :next_action,
            title: "Suggested next step",
            description: format_workflow_suggestion(suggestion),
            confidence: suggestion[:confidence] || 0.7,
            relevance_score: 0.9,
            metadata: %{
              action: suggestion.action,
              reasoning: suggestion.reasoning
            }
          }
        end)
      _ ->
        []
    end
    
    # Get pattern-based suggestions
    pattern_suggestions = if context[:current_task] do
      Patterns.find_matches(context.current_task)
      |> Enum.take(3)
      |> Enum.map(fn pattern ->
        %{
          type: :next_action,
          title: "Based on similar patterns",
          description: pattern["output"],
          confidence: pattern["confidence"],
          relevance_score: 0.8,
          metadata: %{
            pattern_id: pattern["id"],
            pattern_input: pattern["input"]
          }
        }
      end)
    else
      []
    end
    
    workflow_suggestions ++ pattern_suggestions
  end
  
  defp generate_mistake_avoidance_recommendations(context, state) do
    # Find relevant failure patterns
    relevant_failures = find_relevant_failures(context, state.failure_patterns)
    
    relevant_failures
    |> Enum.take(3)
    |> Enum.map(fn failure ->
      %{
        type: :avoid_mistake,
        title: "Common mistake to avoid",
        description: describe_failure_pattern(failure),
        confidence: calculate_failure_relevance(failure, context),
        relevance_score: 0.85,
        metadata: %{
          failure_pattern: failure.pattern,
          frequency: failure.frequency,
          last_seen: failure.last_seen
        }
      }
    end)
  end
  
  defp generate_optimization_recommendations(context, _state) do
    # Get workflow optimizations
    if context[:recent_actions] && length(context.recent_actions) >= 3 do
      case WorkflowOptimizer.analyze_workflow(context.recent_actions) do
        {:ok, _workflow_id, optimizations} ->
          optimizations
          |> Enum.take(2)
          |> Enum.map(fn opt ->
            %{
              type: :optimization,
              title: "Workflow optimization",
              description: opt.description,
              confidence: opt.confidence,
              relevance_score: opt.impact_score,
              metadata: %{
                optimization_type: opt.type,
                expected_improvement: estimate_improvement(opt)
              }
            }
          end)
        _ ->
          []
      end
    else
      []
    end
  end
  
  defp generate_best_practice_recommendations(context, state) do
    # Find successful patterns similar to current context
    if context[:intent] do
      similar_successes = find_similar_successes(context, state.success_patterns)
      
      similar_successes
      |> Enum.take(2)
      |> Enum.map(fn success ->
        %{
          type: :best_practice,
          title: "Recommended approach",
          description: describe_success_pattern(success),
          confidence: 0.8,
          relevance_score: calculate_pattern_relevance(success, context),
          metadata: %{
            pattern: success.pattern,
            success_rate: calculate_success_rate(success)
          }
        }
      end)
    else
      []
    end
  end
  
  defp generate_validation_recommendations(context, _state) do
    validations = []
    
    # File-based validations
    validations = if context[:files_modified] do
      file_validations = Enum.flat_map(context.files_modified, fn file ->
        generate_file_validations(file)
      end)
      validations ++ file_validations
    else
      validations
    end
    
    # Intent-based validations
    validations = case context[:intent] do
      "testing" ->
        validations ++ [
          %{
            type: :validation,
            title: "Pre-test validation",
            description: "Ensure all files are saved and code compiles",
            confidence: 0.9,
            relevance_score: 0.95,
            metadata: %{check_type: :pre_test}
          }
        ]
      
      "deployment" ->
        validations ++ [
          %{
            type: :validation,
            title: "Deployment checklist",
            description: "Run tests, check configs, verify dependencies",
            confidence: 0.95,
            relevance_score: 1.0,
            metadata: %{check_type: :pre_deployment}
          }
        ]
      
      _ ->
        validations
    end
    
    Enum.take(validations, 2)
  end
  
  defp generate_specific_recommendation(type, context, state) do
    case type do
      :next_action ->
        generate_next_action_recommendations(context, state)
        |> List.first()
      
      :avoid_mistake ->
        generate_mistake_avoidance_recommendations(context, state)
        |> List.first()
      
      :optimization ->
        generate_optimization_recommendations(context, state)
        |> List.first()
      
      :best_practice ->
        generate_best_practice_recommendations(context, state)
        |> List.first()
      
      :validation ->
        generate_validation_recommendations(context, state)
        |> List.first()
      
      _ ->
        nil
    end
  end
  
  defp format_workflow_suggestion(suggestion) do
    case suggestion.action do
      :complete -> "Workflow appears complete"
      :explore -> "Explore options - no clear next step identified"
      action -> "#{action} #{suggestion[:file] || ""}"
    end
  end
  
  defp find_relevant_failures(context, failure_patterns) do
    failure_patterns
    |> Enum.filter(fn failure ->
      # Check if failure is relevant to current context
      context_match = case {context[:intent], failure.context[:intent]} do
        {same, same} -> true
        _ -> false
      end
      
      file_match = if context[:files] && failure.context[:files] do
        MapSet.intersection(
          MapSet.new(context.files),
          MapSet.new(failure.context.files)
        ) |> MapSet.size() > 0
      else
        false
      end
      
      context_match or file_match
    end)
    |> Enum.sort_by(&(-&1.frequency))
  end
  
  defp describe_failure_pattern(failure) do
    base_description = case failure.pattern do
      %{action: action, outcome: :failure, reason: reason} ->
        "When #{action}, watch out for #{reason}"
      
      %{error_type: error_type} ->
        "Common #{error_type} error in this context"
      
      _ ->
        "Previously seen failure pattern"
    end
    
    if failure.frequency > 5 do
      "#{base_description} (occurred #{failure.frequency} times)"
    else
      base_description
    end
  end
  
  defp calculate_failure_relevance(failure, context) do
    base_relevance = 0.5
    
    # Increase relevance for recent failures
    recency_bonus = if failure.last_seen do
      age_minutes = DateTime.diff(DateTime.utc_now(), failure.last_seen, :minute)
      max(0, 0.3 * (1 - age_minutes / 1440))  # Decay over 24 hours
    else
      0
    end
    
    # Increase relevance for frequent failures
    frequency_bonus = min(0.2, failure.frequency / 50)
    
    min(1.0, base_relevance + recency_bonus + frequency_bonus)
  end
  
  defp find_similar_successes(context, success_patterns) do
    success_patterns
    |> Enum.filter(fn success ->
      context[:intent] == success.context[:intent] or
      similar_files?(context[:files], success.context[:files])
    end)
    |> Enum.sort_by(&(-&1.frequency))
  end
  
  defp similar_files?(files1, files2) when is_list(files1) and is_list(files2) do
    set1 = MapSet.new(files1)
    set2 = MapSet.new(files2)
    
    intersection_size = MapSet.intersection(set1, set2) |> MapSet.size()
    union_size = MapSet.union(set1, set2) |> MapSet.size()
    
    if union_size > 0 do
      intersection_size / union_size > 0.3
    else
      false
    end
  end
  defp similar_files?(_, _), do: false
  
  defp describe_success_pattern(success) do
    case success.pattern do
      %{action: action, approach: approach} ->
        "Successfully #{action} by #{approach}"
      
      %{strategy: strategy} ->
        "Use #{strategy} strategy"
      
      _ ->
        "Proven successful approach"
    end
  end
  
  defp calculate_pattern_relevance(pattern, context) do
    # Base relevance
    relevance = 0.6
    
    # Intent match
    if pattern.context[:intent] == context[:intent] do
      relevance + 0.2
    else
      relevance
    end
  end
  
  defp calculate_success_rate(success) do
    # In real implementation, would calculate from historical data
    0.85
  end
  
  defp generate_file_validations(file) do
    validations = []
    
    # Language-specific validations
    validations = case Path.extname(file) do
      ".ex" ->
        validations ++ [
          %{
            type: :validation,
            title: "Elixir validation",
            description: "Run `mix compile --warnings-as-errors`",
            confidence: 0.9,
            relevance_score: 0.8,
            metadata: %{file: file, validation_type: :compile}
          }
        ]
      
      ".exs" ->
        validations ++ [
          %{
            type: :validation,
            title: "Test file check",
            description: "Ensure test compiles: `mix test #{file} --no-run`",
            confidence: 0.85,
            relevance_score: 0.75,
            metadata: %{file: file, validation_type: :test_compile}
          }
        ]
      
      _ ->
        validations
    end
    
    validations
  end
  
  defp estimate_improvement(optimization) do
    case optimization.type do
      :remove_redundant -> "~20% faster"
      :reorder -> "~10% more efficient"
      :inefficiency -> "~30% improvement"
      _ -> "Moderate improvement"
    end
  end
  
  defp add_recommendation_id(recommendation) do
    Map.put(recommendation, :id, generate_recommendation_id())
  end
  
  defp generate_recommendation_id do
    :crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)
  end
  
  defp update_context_history(state, context) do
    # Keep last 50 contexts
    new_history = [context | state.context_history] |> Enum.take(50)
    %{state | context_history: new_history}
  end
  
  defp process_recommendation_feedback(state, recommendation_id, outcome) do
    # In real implementation, would update recommendation quality metrics
    Logger.info("📊 Recommendation #{recommendation_id} outcome: #{outcome}")
    
    case outcome do
      :helpful ->
        # Increase confidence in similar recommendations
        state
      
      :not_helpful ->
        # Decrease confidence, adjust patterns
        state
      
      :ignored ->
        # Track but don't adjust much
        state
      
      _ ->
        state
    end
  end
end