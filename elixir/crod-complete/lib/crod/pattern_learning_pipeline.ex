defmodule Crod.PatternLearningPipeline do
  @moduledoc """
  Automated pipeline for learning patterns from activities and brain processing.
  Implements continuous learning with validation and quality control.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{Patterns, ActivityIntelligence, Brain, Memory}
  
  @learning_interval 30_000  # 30 seconds
  @min_confidence 0.6
  @validation_threshold 0.8
  @pattern_batch_size 50
  
  defstruct [
    :learning_enabled,
    :patterns_queue,
    :validation_results,
    :learning_stats,
    :quality_metrics
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def learn_from_activity(activity, outcome) do
    GenServer.cast(__MODULE__, {:learn_from_activity, activity, outcome})
  end
  
  def learn_from_interaction(input, output, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:learn_from_interaction, input, output, metadata})
  end
  
  def validate_pattern(pattern_id) do
    GenServer.call(__MODULE__, {:validate_pattern, pattern_id})
  end
  
  def get_learning_stats do
    GenServer.call(__MODULE__, :get_learning_stats)
  end
  
  def enable_learning do
    GenServer.cast(__MODULE__, :enable_learning)
  end
  
  def disable_learning do
    GenServer.cast(__MODULE__, :disable_learning)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      learning_enabled: true,
      patterns_queue: :queue.new(),
      validation_results: %{},
      learning_stats: init_stats(),
      quality_metrics: init_quality_metrics()
    }
    
    # Schedule periodic learning cycles
    :timer.send_interval(@learning_interval, self(), :learn_cycle)
    
    # Subscribe to activity updates
    Phoenix.PubSub.subscribe(Crod.PubSub, "activity:outcomes")
    Phoenix.PubSub.subscribe(Crod.PubSub, "brain:interactions")
    
    Logger.info("🎓 Pattern Learning Pipeline initialized")
    
    {:ok, state}
  end
  
  def handle_cast({:learn_from_activity, activity, outcome}, state) do
    if state.learning_enabled do
      pattern_candidate = extract_pattern_from_activity(activity, outcome)
      
      if pattern_candidate do
        new_queue = :queue.in(pattern_candidate, state.patterns_queue)
        {:noreply, %{state | patterns_queue: new_queue}}
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  def handle_cast({:learn_from_interaction, input, output, metadata}, state) do
    if state.learning_enabled do
      pattern_candidate = %{
        input: input,
        output: output,
        confidence: calculate_initial_confidence(input, output),
        metadata: Map.merge(metadata, %{
          source: "direct_interaction",
          created_at: DateTime.utc_now()
        }),
        requires_validation: true
      }
      
      new_queue = :queue.in(pattern_candidate, state.patterns_queue)
      {:noreply, %{state | patterns_queue: new_queue}}
    else
      {:noreply, state}
    end
  end
  
  def handle_cast(:enable_learning, state) do
    Logger.info("✅ Learning enabled")
    {:noreply, %{state | learning_enabled: true}}
  end
  
  def handle_cast(:disable_learning, state) do
    Logger.info("⏸️ Learning disabled")
    {:noreply, %{state | learning_enabled: false}}
  end
  
  def handle_call({:validate_pattern, pattern_id}, _from, state) do
    validation_result = perform_pattern_validation(pattern_id)
    
    new_results = Map.put(state.validation_results, pattern_id, validation_result)
    new_state = %{state | validation_results: new_results}
    
    {:reply, validation_result, new_state}
  end
  
  def handle_call(:get_learning_stats, _from, state) do
    stats = Map.merge(state.learning_stats, %{
      queue_size: :queue.len(state.patterns_queue),
      quality_metrics: state.quality_metrics,
      learning_enabled: state.learning_enabled
    })
    
    {:reply, stats, state}
  end
  
  def handle_info(:learn_cycle, state) do
    if state.learning_enabled and :queue.len(state.patterns_queue) > 0 do
      new_state = process_learning_cycle(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  def handle_info({:activity_outcome, activity_id, outcome}, state) do
    # Handle activity outcome notifications
    activity = ActivityIntelligence.get_activity(activity_id)
    
    if activity do
      handle_cast({:learn_from_activity, activity, outcome}, state)
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp init_stats do
    %{
      patterns_learned: 0,
      patterns_validated: 0,
      patterns_rejected: 0,
      patterns_improved: 0,
      learning_cycles: 0,
      total_confidence_gain: 0.0
    }
  end
  
  defp init_quality_metrics do
    %{
      avg_pattern_confidence: 0.0,
      validation_success_rate: 0.0,
      pattern_diversity_score: 0.0,
      learning_efficiency: 0.0
    }
  end
  
  defp extract_pattern_from_activity(activity, outcome) do
    case {activity.intent, outcome} do
      # Successful development activities
      {"elixir_development", :success} ->
        %{
          input: "Need to #{activity.action} #{Path.basename(activity.file)}",
          output: activity[:details] || "#{activity.action} completed successfully",
          confidence: 0.8,
          metadata: %{
            source: "activity_success",
            intent: activity.intent,
            file_type: Path.extname(activity.file)
          }
        }
      
      # Failed test activities - learn what not to do
      {"testing", :failure} ->
        %{
          input: "Running tests on #{Path.basename(activity.file)}",
          output: "Check for: #{extract_failure_reason(activity)}",
          confidence: 0.7,
          metadata: %{
            source: "test_failure",
            failure_type: classify_failure(activity)
          }
        }
      
      # Bug fixes - learn solutions
      {"bug_fix", :success} ->
        %{
          input: extract_bug_description(activity),
          output: extract_fix_description(activity),
          confidence: 0.9,
          metadata: %{
            source: "bug_fix",
            fix_type: classify_fix(activity)
          }
        }
      
      _ ->
        nil
    end
  end
  
  defp calculate_initial_confidence(input, output) do
    # Base confidence on input/output quality
    input_length = String.length(input)
    output_length = String.length(output)
    
    cond do
      input_length < 10 or output_length < 10 -> 0.3
      input_length > 200 or output_length > 500 -> 0.5
      String.contains?(output, ["error", "fail", "wrong"]) -> 0.4
      true -> 0.7
    end
  end
  
  defp process_learning_cycle(state) do
    Logger.debug("🔄 Processing learning cycle")
    
    # Take a batch of patterns
    {patterns, remaining_queue} = take_pattern_batch(state.patterns_queue, @pattern_batch_size)
    
    # Process each pattern
    results = Enum.map(patterns, &process_pattern_candidate/1)
    
    # Separate successful and failed patterns
    {learned, rejected} = Enum.split_with(results, & &1.success)
    
    # Update existing patterns with new learnings
    improved_count = improve_existing_patterns(learned)
    
    # Store new patterns
    new_patterns = Enum.filter(learned, & &1.is_new)
    Enum.each(new_patterns, &store_new_pattern/1)
    
    # Update statistics
    new_stats = state.learning_stats
    |> Map.update(:patterns_learned, 0, &(&1 + length(new_patterns)))
    |> Map.update(:patterns_rejected, 0, &(&1 + length(rejected)))
    |> Map.update(:patterns_improved, 0, &(&1 + improved_count))
    |> Map.update(:learning_cycles, 0, &(&1 + 1))
    
    # Update quality metrics
    new_quality = update_quality_metrics(state.quality_metrics, results)
    
    %{state |
      patterns_queue: remaining_queue,
      learning_stats: new_stats,
      quality_metrics: new_quality
    }
  end
  
  defp take_pattern_batch(queue, max_size) do
    take_pattern_batch_helper(queue, max_size, [])
  end
  
  defp take_pattern_batch_helper(queue, 0, acc) do
    {Enum.reverse(acc), queue}
  end
  defp take_pattern_batch_helper(queue, size, acc) do
    case :queue.out(queue) do
      {{:value, pattern}, new_queue} ->
        take_pattern_batch_helper(new_queue, size - 1, [pattern | acc])
      {:empty, _} ->
        {Enum.reverse(acc), queue}
    end
  end
  
  defp process_pattern_candidate(candidate) do
    # Check if pattern already exists
    existing = find_similar_pattern(candidate)
    
    if existing do
      # Validate and potentially improve existing pattern
      validate_and_improve(candidate, existing)
    else
      # Validate new pattern
      validate_new_pattern(candidate)
    end
  end
  
  defp find_similar_pattern(candidate) do
    matches = Patterns.find_matches(candidate.input, threshold: 0.8)
    
    Enum.find(matches, fn pattern ->
      similarity_score(pattern["output"], candidate.output) > 0.7
    end)
  end
  
  defp similarity_score(text1, text2) do
    # Simple similarity based on common words
    words1 = String.split(String.downcase(text1))
    words2 = String.split(String.downcase(text2))
    
    common = MapSet.intersection(MapSet.new(words1), MapSet.new(words2))
    total = MapSet.union(MapSet.new(words1), MapSet.new(words2))
    
    if MapSet.size(total) > 0 do
      MapSet.size(common) / MapSet.size(total)
    else
      0.0
    end
  end
  
  defp validate_and_improve(candidate, existing) do
    # Test both patterns
    test_result_existing = test_pattern(existing)
    test_result_candidate = test_pattern(candidate)
    
    cond do
      # Candidate is better
      test_result_candidate.score > test_result_existing.score + 0.1 ->
        %{
          success: true,
          is_new: false,
          pattern: candidate,
          improvement: test_result_candidate.score - test_result_existing.score
        }
      
      # Existing is good enough
      test_result_existing.score > @validation_threshold ->
        # Still update confidence if candidate confirms it
        Patterns.update_confidence(existing["input"], :positive)
        %{success: false, is_new: false, reason: :existing_better}
      
      # Both are poor, reject
      true ->
        %{success: false, is_new: false, reason: :both_poor}
    end
  end
  
  defp validate_new_pattern(candidate) do
    test_result = test_pattern(candidate)
    
    if test_result.score > @min_confidence do
      %{
        success: true,
        is_new: true,
        pattern: Map.put(candidate, :confidence, test_result.score)
      }
    else
      %{
        success: false,
        is_new: true,
        reason: :low_confidence,
        score: test_result.score
      }
    end
  end
  
  defp test_pattern(pattern) do
    # Test pattern through brain
    brain_result = Brain.process(pattern["input"] || pattern.input)
    
    # Calculate score based on output match
    output_match = similarity_score(
      brain_result.output,
      pattern["output"] || pattern.output
    )
    
    # Consider brain confidence
    score = output_match * 0.7 + brain_result.confidence * 0.3
    
    %{
      score: score,
      brain_confidence: brain_result.confidence,
      output_match: output_match
    }
  end
  
  defp improve_existing_patterns(learned_results) do
    learned_results
    |> Enum.filter(& &1[:improvement])
    |> Enum.map(fn result ->
      # Update pattern with improved version
      Patterns.add_pattern(%{
        "input" => result.pattern.input,
        "output" => result.pattern.output,
        "confidence" => result.pattern.confidence,
        "metadata" => Map.put(result.pattern.metadata, "improved_at", DateTime.utc_now())
      })
      
      1
    end)
    |> Enum.sum()
  end
  
  defp store_new_pattern(result) do
    pattern = result.pattern
    
    Patterns.add_pattern(%{
      "input" => pattern.input,
      "output" => pattern.output,
      "confidence" => pattern.confidence,
      "metadata" => Map.merge(pattern.metadata || %{}, %{
        "learned_at" => DateTime.utc_now(),
        "learning_pipeline" => true
      })
    })
  end
  
  defp perform_pattern_validation(pattern_id) do
    # Get pattern
    case Patterns.get_pattern(pattern_id) do
      {:ok, pattern} ->
        # Run validation tests
        test_results = run_validation_tests(pattern)
        
        # Calculate validation score
        score = calculate_validation_score(test_results)
        
        %{
          valid: score > @validation_threshold,
          score: score,
          tests: test_results,
          timestamp: DateTime.utc_now()
        }
      
      _ ->
        %{valid: false, error: :pattern_not_found}
    end
  end
  
  defp run_validation_tests(pattern) do
    [
      # Test exact match
      %{
        name: :exact_match,
        result: test_exact_match(pattern),
        weight: 0.4
      },
      
      # Test variations
      %{
        name: :variations,
        result: test_variations(pattern),
        weight: 0.3
      },
      
      # Test consistency
      %{
        name: :consistency,
        result: test_consistency(pattern),
        weight: 0.3
      }
    ]
  end
  
  defp test_exact_match(pattern) do
    result = Brain.process(pattern["input"])
    similarity_score(result.output, pattern["output"]) > 0.8
  end
  
  defp test_variations(pattern) do
    variations = generate_input_variations(pattern["input"])
    
    results = Enum.map(variations, fn input ->
      result = Brain.process(input)
      similarity_score(result.output, pattern["output"]) > 0.6
    end)
    
    Enum.count(results, & &1) / length(results) > 0.7
  end
  
  defp test_consistency(pattern) do
    # Test multiple times
    results = Enum.map(1..5, fn _ ->
      result = Brain.process(pattern["input"])
      similarity_score(result.output, pattern["output"])
    end)
    
    # Check consistency
    avg = Enum.sum(results) / length(results)
    variance = Enum.sum(Enum.map(results, fn r -> :math.pow(r - avg, 2) end)) / length(results)
    
    avg > 0.7 and variance < 0.1
  end
  
  defp generate_input_variations(input) do
    base_words = String.split(input)
    
    [
      # Original
      input,
      
      # Rephrase with synonyms
      rephrase_with_synonyms(input),
      
      # Add context
      "In this case, " <> input,
      
      # Question form
      "How to " <> String.downcase(input) <> "?",
      
      # Shortened
      base_words |> Enum.take(div(length(base_words), 2)) |> Enum.join(" ")
    ]
    |> Enum.uniq()
  end
  
  defp rephrase_with_synonyms(input) do
    # Simple synonym replacement
    input
    |> String.replace("need to", "have to")
    |> String.replace("modify", "change")
    |> String.replace("create", "make")
    |> String.replace("fix", "repair")
  end
  
  defp calculate_validation_score(test_results) do
    test_results
    |> Enum.map(fn test ->
      if test.result, do: test.weight, else: 0
    end)
    |> Enum.sum()
  end
  
  defp update_quality_metrics(metrics, results) do
    successful = Enum.filter(results, & &1.success)
    
    # Calculate new metrics
    avg_confidence = if length(successful) > 0 do
      successful
      |> Enum.map(& &1.pattern.confidence)
      |> Enum.sum()
      |> Kernel./(length(successful))
    else
      metrics.avg_pattern_confidence
    end
    
    success_rate = if length(results) > 0 do
      length(successful) / length(results)
    else
      metrics.validation_success_rate
    end
    
    %{metrics |
      avg_pattern_confidence: avg_confidence,
      validation_success_rate: success_rate,
      pattern_diversity_score: calculate_diversity_score(successful),
      learning_efficiency: calculate_efficiency(results)
    }
  end
  
  defp calculate_diversity_score(patterns) do
    # Measure diversity of learned patterns
    intents = patterns
    |> Enum.map(& get_in(&1, [:pattern, :metadata, "intent"]))
    |> Enum.uniq()
    |> length()
    
    sources = patterns
    |> Enum.map(& get_in(&1, [:pattern, :metadata, "source"]))
    |> Enum.uniq()
    |> length()
    
    (intents + sources) / 10.0  # Normalize to 0-1 range
  end
  
  defp calculate_efficiency(results) do
    # Ratio of successful patterns to total processing
    if length(results) > 0 do
      successful = Enum.count(results, & &1.success)
      successful / length(results)
    else
      0.0
    end
  end
  
  defp extract_failure_reason(activity) do
    activity[:details] || "unknown failure"
  end
  
  defp classify_failure(activity) do
    cond do
      String.contains?(activity[:details] || "", "undefined") -> :undefined_error
      String.contains?(activity[:details] || "", "syntax") -> :syntax_error
      String.contains?(activity[:details] || "", "type") -> :type_error
      true -> :general_error
    end
  end
  
  defp extract_bug_description(activity) do
    "Bug in #{Path.basename(activity.file)}: #{activity[:why] || "issue"}"
  end
  
  defp extract_fix_description(activity) do
    activity[:details] || "Applied fix to resolve the issue"
  end
  
  defp classify_fix(activity) do
    cond do
      String.contains?(activity.file, "test") -> :test_fix
      String.contains?(activity[:details] || "", "config") -> :config_fix
      String.contains?(activity[:details] || "", "logic") -> :logic_fix
      true -> :general_fix
    end
  end
end