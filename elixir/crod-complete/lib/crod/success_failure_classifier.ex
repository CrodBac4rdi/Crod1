defmodule Crod.SuccessFailureClassifier do
  @moduledoc """
  Classifies activities and operations as success or failure based on
  multiple signals and learns from patterns to improve accuracy.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{Patterns, Brain, ActivityIntelligence}
  
  @classification_threshold 0.7
  @learning_rate 0.1
  @history_size 1000
  
  defstruct [
    :classification_models,
    :signal_weights,
    :classification_history,
    :accuracy_metrics,
    :learning_enabled
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def classify(activity_or_result) do
    GenServer.call(__MODULE__, {:classify, activity_or_result})
  end
  
  def classify_batch(items) do
    GenServer.call(__MODULE__, {:classify_batch, items})
  end
  
  def learn_from_feedback(classification_id, actual_outcome) do
    GenServer.cast(__MODULE__, {:learn_from_feedback, classification_id, actual_outcome})
  end
  
  def get_accuracy_metrics do
    GenServer.call(__MODULE__, :get_accuracy_metrics)
  end
  
  def get_signal_importance do
    GenServer.call(__MODULE__, :get_signal_importance)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      classification_models: init_models(),
      signal_weights: init_signal_weights(),
      classification_history: [],
      accuracy_metrics: init_metrics(),
      learning_enabled: true
    }
    
    # Schedule periodic model updates
    :timer.send_interval(:timer.minutes(5), self(), :update_models)
    
    Logger.info("🎯 Success/Failure Classifier initialized")
    
    {:ok, state}
  end
  
  def handle_call({:classify, item}, _from, state) do
    {classification, confidence, signals} = perform_classification(item, state)
    
    # Store in history
    history_entry = %{
      id: generate_classification_id(),
      item: sanitize_item(item),
      classification: classification,
      confidence: confidence,
      signals: signals,
      timestamp: DateTime.utc_now()
    }
    
    new_state = update_history(state, history_entry)
    
    result = %{
      outcome: classification,
      confidence: confidence,
      signals: signals,
      classification_id: history_entry.id
    }
    
    {:reply, result, new_state}
  end
  
  def handle_call({:classify_batch, items}, _from, state) do
    results = Enum.map(items, fn item ->
      {classification, confidence, signals} = perform_classification(item, state)
      
      %{
        item: item,
        outcome: classification,
        confidence: confidence,
        signals: signals
      }
    end)
    
    {:reply, results, state}
  end
  
  def handle_call(:get_accuracy_metrics, _from, state) do
    {:reply, state.accuracy_metrics, state}
  end
  
  def handle_call(:get_signal_importance, _from, state) do
    importance = calculate_signal_importance(state)
    {:reply, importance, state}
  end
  
  def handle_cast({:learn_from_feedback, classification_id, actual_outcome}, state) do
    case find_classification(state.classification_history, classification_id) do
      nil ->
        {:noreply, state}
      
      entry ->
        # Update models based on feedback
        new_state = learn_from_mistake(state, entry, actual_outcome)
        
        # Update accuracy metrics
        new_state = update_accuracy_metrics(new_state, entry.classification, actual_outcome)
        
        {:noreply, new_state}
    end
  end
  
  def handle_info(:update_models, state) do
    if state.learning_enabled do
      new_state = update_classification_models(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp init_models do
    %{
      # Models for different types of classification
      activity: %{
        success_patterns: [],
        failure_patterns: [],
        threshold: 0.7
      },
      test_result: %{
        success_indicators: ["passed", "success", "ok", "✓"],
        failure_indicators: ["failed", "error", "exception", "✗"],
        warning_indicators: ["warning", "deprecated", "skipped"]
      },
      code_change: %{
        success_signals: ["compiles", "tests pass", "no errors"],
        failure_signals: ["syntax error", "undefined", "cannot find"]
      },
      performance: %{
        success_thresholds: %{response_time_ms: 100, cpu_usage: 0.8},
        failure_thresholds: %{response_time_ms: 1000, cpu_usage: 0.95}
      }
    }
  end
  
  defp init_signal_weights do
    %{
      # Weights for different classification signals
      explicit_outcome: 1.0,      # Explicit success/failure field
      error_presence: 0.9,        # Presence of errors
      keyword_match: 0.8,         # Success/failure keywords
      pattern_match: 0.7,         # Historical pattern matching
      performance_metrics: 0.6,   # Performance thresholds
      file_changes: 0.5,          # File modification patterns
      duration: 0.4,              # Task duration
      context: 0.3                # Surrounding context
    }
  end
  
  defp init_metrics do
    %{
      total_classifications: 0,
      correct_classifications: 0,
      false_positives: 0,
      false_negatives: 0,
      accuracy: 0.0,
      precision: 0.0,
      recall: 0.0,
      f1_score: 0.0,
      confusion_matrix: %{
        true_positive: 0,
        true_negative: 0,
        false_positive: 0,
        false_negative: 0
      }
    }
  end
  
  defp perform_classification(item, state) do
    signals = extract_signals(item, state)
    
    # Calculate weighted score
    weighted_scores = Enum.map(signals, fn {signal_type, signal_value, confidence} ->
      weight = Map.get(state.signal_weights, signal_type, 0.5)
      
      score = case signal_value do
        :success -> confidence
        :failure -> -confidence
        :neutral -> 0
        :warning -> -confidence * 0.5
      end
      
      score * weight
    end)
    
    total_score = Enum.sum(weighted_scores)
    total_weight = signals
    |> Enum.map(fn {type, _, _} -> Map.get(state.signal_weights, type, 0.5) end)
    |> Enum.sum()
    
    normalized_score = if total_weight > 0 do
      (total_score / total_weight + 1) / 2  # Normalize to 0-1
    else
      0.5
    end
    
    # Determine classification
    classification = cond do
      normalized_score >= @classification_threshold -> :success
      normalized_score <= (1 - @classification_threshold) -> :failure
      true -> :uncertain
    end
    
    # Calculate confidence
    confidence = if classification == :uncertain do
      1 - abs(normalized_score - 0.5) * 2
    else
      abs(normalized_score - 0.5) * 2
    end
    
    {classification, confidence, signals}
  end
  
  defp extract_signals(item, state) do
    signals = []
    
    # Check explicit outcome
    signals = if Map.has_key?(item, :outcome) do
      outcome_signal = case item.outcome do
        :success -> {:explicit_outcome, :success, 1.0}
        :failure -> {:explicit_outcome, :failure, 1.0}
        _ -> {:explicit_outcome, :neutral, 0.5}
      end
      [outcome_signal | signals]
    else
      signals
    end
    
    # Check for errors
    signals = if Map.has_key?(item, :error) or Map.has_key?(item, :errors) do
      [{:error_presence, :failure, 0.9} | signals]
    else
      signals
    end
    
    # Check keywords in text fields
    text_content = extract_text_content(item)
    keyword_signal = analyze_keywords(text_content, state.classification_models.test_result)
    signals = [keyword_signal | signals]
    
    # Check pattern matches
    pattern_signal = check_pattern_match(item, state)
    signals = [pattern_signal | signals]
    
    # Check performance metrics
    if Map.has_key?(item, :duration_ms) or Map.has_key?(item, :response_time) do
      perf_signal = analyze_performance(item, state.classification_models.performance)
      signals = [perf_signal | signals]
    else
      signals
    end
    
    # Check file changes
    if Map.has_key?(item, :action) and item.action in ["created", "modified", "deleted"] do
      file_signal = analyze_file_operation(item)
      signals = [file_signal | signals]
    else
      signals
    end
    
    # Context analysis
    context_signal = analyze_context(item, state)
    [context_signal | signals]
  end
  
  defp extract_text_content(item) do
    fields = [:output, :details, :description, :message, :log, :stdout, :stderr]
    
    fields
    |> Enum.map(&Map.get(item, &1, ""))
    |> Enum.join(" ")
    |> String.downcase()
  end
  
  defp analyze_keywords(text, keyword_model) do
    success_count = Enum.count(keyword_model.success_indicators, &String.contains?(text, &1))
    failure_count = Enum.count(keyword_model.failure_indicators, &String.contains?(text, &1))
    warning_count = Enum.count(keyword_model.warning_indicators, &String.contains?(text, &1))
    
    cond do
      failure_count > success_count ->
        {:keyword_match, :failure, min(failure_count / 3, 1.0)}
      
      success_count > failure_count ->
        {:keyword_match, :success, min(success_count / 3, 1.0)}
      
      warning_count > 0 ->
        {:keyword_match, :warning, min(warning_count / 2, 1.0)}
      
      true ->
        {:keyword_match, :neutral, 0.5}
    end
  end
  
  defp check_pattern_match(item, state) do
    # Create a searchable representation
    search_text = create_search_text(item)
    
    # Search for matching patterns
    matches = Patterns.find_matches(search_text, threshold: 0.6)
    
    if length(matches) > 0 do
      # Analyze matched patterns
      success_patterns = Enum.filter(matches, fn p ->
        String.contains?(String.downcase(p["output"]), ["success", "complete", "done"])
      end)
      
      failure_patterns = Enum.filter(matches, fn p ->
        String.contains?(String.downcase(p["output"]), ["fail", "error", "wrong"])
      end)
      
      cond do
        length(failure_patterns) > length(success_patterns) ->
          {:pattern_match, :failure, 0.8}
        
        length(success_patterns) > length(failure_patterns) ->
          {:pattern_match, :success, 0.8}
        
        true ->
          {:pattern_match, :neutral, 0.5}
      end
    else
      {:pattern_match, :neutral, 0.3}
    end
  end
  
  defp analyze_performance(item, perf_model) do
    duration = item[:duration_ms] || item[:response_time] || 0
    
    cond do
      duration <= perf_model.success_thresholds.response_time_ms ->
        {:performance_metrics, :success, 0.9}
      
      duration >= perf_model.failure_thresholds.response_time_ms ->
        {:performance_metrics, :failure, 0.9}
      
      true ->
        # Linear interpolation between thresholds
        success_threshold = perf_model.success_thresholds.response_time_ms
        failure_threshold = perf_model.failure_thresholds.response_time_ms
        
        confidence = (duration - success_threshold) / (failure_threshold - success_threshold)
        
        if confidence < 0.5 do
          {:performance_metrics, :success, 1 - confidence * 2}
        else
          {:performance_metrics, :failure, (confidence - 0.5) * 2}
        end
    end
  end
  
  defp analyze_file_operation(item) do
    case item.action do
      "created" ->
        if String.contains?(item.file, ["test", "spec"]) do
          {:file_changes, :success, 0.7}
        else
          {:file_changes, :neutral, 0.6}
        end
      
      "modified" ->
        {:file_changes, :neutral, 0.5}
      
      "deleted" ->
        if String.contains?(item.file, ["tmp", "temp", "backup"]) do
          {:file_changes, :success, 0.6}
        else
          {:file_changes, :warning, 0.7}
        end
      
      _ ->
        {:file_changes, :neutral, 0.5}
    end
  end
  
  defp analyze_context(item, state) do
    # Look at recent history for context
    recent = Enum.take(state.classification_history, 5)
    
    if length(recent) > 0 do
      # Check if this is part of a pattern
      recent_outcomes = Enum.map(recent, & &1.classification)
      
      cond do
        Enum.all?(recent_outcomes, &(&1 == :success)) ->
          {:context, :success, 0.7}
        
        Enum.all?(recent_outcomes, &(&1 == :failure)) ->
          {:context, :failure, 0.7}
        
        true ->
          {:context, :neutral, 0.5}
      end
    else
      {:context, :neutral, 0.3}
    end
  end
  
  defp create_search_text(item) do
    relevant_fields = [:action, :intent, :file, :details, :output, :message]
    
    relevant_fields
    |> Enum.map(&Map.get(item, &1))
    |> Enum.filter(&(&1 != nil))
    |> Enum.join(" ")
  end
  
  defp generate_classification_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
  
  defp sanitize_item(item) do
    # Remove large fields to save memory
    Map.drop(item, [:data, :content, :large_output])
  end
  
  defp update_history(state, entry) do
    new_history = [entry | state.classification_history] |> Enum.take(@history_size)
    %{state | classification_history: new_history}
  end
  
  defp find_classification(history, id) do
    Enum.find(history, &(&1.id == id))
  end
  
  defp learn_from_mistake(state, entry, actual_outcome) do
    if entry.classification != actual_outcome do
      Logger.info("📚 Learning from misclassification: predicted #{entry.classification}, actual #{actual_outcome}")
      
      # Adjust signal weights based on which signals were wrong
      new_weights = adjust_signal_weights(state.signal_weights, entry.signals, actual_outcome)
      
      # Update classification models
      new_models = update_models_from_mistake(state.classification_models, entry, actual_outcome)
      
      %{state |
        signal_weights: new_weights,
        classification_models: new_models
      }
    else
      # Correct classification - reinforce current weights slightly
      new_weights = reinforce_signal_weights(state.signal_weights, entry.signals)
      %{state | signal_weights: new_weights}
    end
  end
  
  defp adjust_signal_weights(weights, signals, actual_outcome) do
    Enum.reduce(signals, weights, fn {signal_type, signal_value, _confidence}, acc ->
      current_weight = Map.get(acc, signal_type, 0.5)
      
      # Determine if this signal was correct
      signal_correct = case {signal_value, actual_outcome} do
        {:success, :success} -> true
        {:failure, :failure} -> true
        {:neutral, _} -> true  # Neutral is never wrong
        _ -> false
      end
      
      # Adjust weight
      adjustment = if signal_correct do
        @learning_rate * 0.5  # Small positive reinforcement
      else
        -@learning_rate       # Larger negative adjustment for mistakes
      end
      
      new_weight = max(0.1, min(1.0, current_weight + adjustment))
      Map.put(acc, signal_type, new_weight)
    end)
  end
  
  defp reinforce_signal_weights(weights, signals) do
    Enum.reduce(signals, weights, fn {signal_type, _signal_value, confidence}, acc ->
      if confidence > 0.7 do
        current_weight = Map.get(acc, signal_type, 0.5)
        new_weight = min(1.0, current_weight + @learning_rate * 0.1)
        Map.put(acc, signal_type, new_weight)
      else
        acc
      end
    end)
  end
  
  defp update_models_from_mistake(models, entry, actual_outcome) do
    # Learn new patterns from mistakes
    item_text = create_search_text(entry.item)
    
    new_pattern = %{
      text: item_text,
      outcome: actual_outcome,
      learned_from: :mistake,
      timestamp: DateTime.utc_now()
    }
    
    case actual_outcome do
      :success ->
        update_in(models.activity.success_patterns, &([new_pattern | &1] |> Enum.take(100)))
      
      :failure ->
        update_in(models.activity.failure_patterns, &([new_pattern | &1] |> Enum.take(100)))
      
      _ ->
        models
    end
  end
  
  defp update_accuracy_metrics(state, predicted, actual) do
    metrics = state.accuracy_metrics
    
    # Update confusion matrix
    new_matrix = case {predicted, actual} do
      {:success, :success} ->
        update_in(metrics.confusion_matrix.true_positive, &(&1 + 1))
      
      {:failure, :failure} ->
        update_in(metrics.confusion_matrix.true_negative, &(&1 + 1))
      
      {:success, :failure} ->
        update_in(metrics.confusion_matrix.false_positive, &(&1 + 1))
      
      {:failure, :success} ->
        update_in(metrics.confusion_matrix.false_negative, &(&1 + 1))
      
      _ ->
        metrics.confusion_matrix
    end
    
    # Update counts
    is_correct = predicted == actual
    new_metrics = metrics
    |> Map.update!(:total_classifications, &(&1 + 1))
    |> Map.update!(:correct_classifications, fn c ->
      if is_correct, do: c + 1, else: c
    end)
    |> Map.put(:confusion_matrix, new_matrix)
    
    # Recalculate derived metrics
    new_metrics = calculate_derived_metrics(new_metrics)
    
    %{state | accuracy_metrics: new_metrics}
  end
  
  defp calculate_derived_metrics(metrics) do
    tp = metrics.confusion_matrix.true_positive
    tn = metrics.confusion_matrix.true_negative
    fp = metrics.confusion_matrix.false_positive
    false_neg = metrics.confusion_matrix.false_negative
    
    total = tp + tn + fp + false_neg
    
    accuracy = if total > 0, do: (tp + tn) / total, else: 0.0
    precision = if tp + fp > 0, do: tp / (tp + fp), else: 0.0
    recall = if tp + false_neg > 0, do: tp / (tp + false_neg), else: 0.0
    
    f1_score = if precision + recall > 0 do
      2 * precision * recall / (precision + recall)
    else
      0.0
    end
    
    %{metrics |
      accuracy: accuracy,
      precision: precision,
      recall: recall,
      f1_score: f1_score,
      false_positives: fp,
      false_negatives: false_neg
    }
  end
  
  defp update_classification_models(state) do
    # Analyze recent classifications for patterns
    recent_correct = state.classification_history
    |> Enum.filter(fn entry ->
      # Find entries with feedback
      actual = get_actual_outcome(entry)
      actual != nil and entry.classification == actual
    end)
    |> Enum.take(100)
    
    if length(recent_correct) >= 10 do
      # Extract new patterns from correct classifications
      new_patterns = extract_patterns_from_correct(recent_correct)
      
      # Update models with new patterns
      updated_models = incorporate_new_patterns(state.classification_models, new_patterns)
      
      %{state | classification_models: updated_models}
    else
      state
    end
  end
  
  defp get_actual_outcome(entry) do
    # In real implementation, this would query feedback storage
    # For now, return nil
    nil
  end
  
  defp extract_patterns_from_correct(entries) do
    entries
    |> Enum.group_by(& &1.classification)
    |> Enum.map(fn {outcome, group} ->
      common_signals = find_common_signals(group)
      
      %{
        outcome: outcome,
        signals: common_signals,
        confidence: length(group) / length(entries)
      }
    end)
  end
  
  defp find_common_signals(entries) do
    all_signals = Enum.flat_map(entries, & &1.signals)
    
    all_signals
    |> Enum.group_by(& elem(&1, 0))  # Group by signal type
    |> Enum.map(fn {type, signals} ->
      # Find most common value for this signal type
      most_common = signals
      |> Enum.frequencies_by(& elem(&1, 1))
      |> Enum.max_by(& elem(&1, 1))
      |> elem(0)
      
      {type, most_common, length(signals) / length(entries)}
    end)
    |> Enum.filter(fn {_type, _value, frequency} -> frequency > 0.5 end)
  end
  
  defp incorporate_new_patterns(models, new_patterns) do
    # Update models with newly discovered patterns
    Enum.reduce(new_patterns, models, fn pattern, acc ->
      case pattern.outcome do
        :success ->
          # Add to success patterns
          put_in(acc.activity.success_patterns, 
            [pattern | acc.activity.success_patterns] |> Enum.take(200))
        
        :failure ->
          # Add to failure patterns
          put_in(acc.activity.failure_patterns,
            [pattern | acc.activity.failure_patterns] |> Enum.take(200))
        
        _ ->
          acc
      end
    end)
  end
  
  defp calculate_signal_importance(state) do
    # Calculate importance based on accuracy when using each signal
    state.signal_weights
    |> Enum.map(fn {signal_type, weight} ->
      # Calculate accuracy contribution
      classifications_with_signal = state.classification_history
      |> Enum.filter(fn entry ->
        Enum.any?(entry.signals, fn {type, _, _} -> type == signal_type end)
      end)
      
      accuracy = if length(classifications_with_signal) > 0 do
        correct = Enum.count(classifications_with_signal, fn entry ->
          # Check if classification was correct (would need feedback data)
          true  # Placeholder
        end)
        
        correct / length(classifications_with_signal)
      else
        0.5
      end
      
      {signal_type, %{
        weight: weight,
        usage_count: length(classifications_with_signal),
        estimated_accuracy: accuracy
      }}
    end)
    |> Enum.into(%{})
  end
end