defmodule Crod.MonitoringDashboard do
  @moduledoc """
  Comprehensive monitoring dashboard that aggregates metrics from all CROD components
  and provides real-time insights into system health and performance.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{
    Brain,
    ActivityIntelligence,
    Patterns,
    Memory,
    NeuronStats,
    PatternPersistence,
    BackupRestoreSystem,
    WorkflowOptimizer,
    SuccessFailureClassifier,
    RecommendationEngine,
    Neuron,
    NeuronRegistry
  }
  
  @refresh_interval 5_000  # 5 seconds
  @metric_history_size 100
  @alert_check_interval 30_000  # 30 seconds
  
  defstruct [
    :metrics,
    :alerts,
    :history,
    :thresholds,
    :refresh_timer,
    :alert_timer,
    :subscribers
  ]
  
  # Metric categories
  @metric_categories [
    :system,
    :neural,
    :patterns,
    :memory,
    :activity,
    :performance,
    :storage,
    :health
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get_metrics(category \\ :all) do
    GenServer.call(__MODULE__, {:get_metrics, category})
  end
  
  def get_alerts do
    GenServer.call(__MODULE__, :get_alerts)
  end
  
  def get_history(metric_name, duration_minutes \\ 60) do
    GenServer.call(__MODULE__, {:get_history, metric_name, duration_minutes})
  end
  
  def set_threshold(metric_name, threshold) do
    GenServer.cast(__MODULE__, {:set_threshold, metric_name, threshold})
  end
  
  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end
  
  def unsubscribe do
    GenServer.cast(__MODULE__, {:unsubscribe, self()})
  end
  
  def force_refresh do
    GenServer.cast(__MODULE__, :force_refresh)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    state = %__MODULE__{
      metrics: %{},
      alerts: [],
      history: %{},
      thresholds: init_thresholds(),
      subscribers: []
    }
    
    # Schedule metric collection
    refresh_timer = Process.send_after(self(), :collect_metrics, 1000)
    alert_timer = Process.send_after(self(), :check_alerts, @alert_check_interval)
    
    Logger.info("📊 Monitoring Dashboard initialized")
    
    {:ok, %{state | refresh_timer: refresh_timer, alert_timer: alert_timer}}
  end
  
  def handle_call({:get_metrics, :all}, _from, state) do
    {:reply, state.metrics, state}
  end
  
  def handle_call({:get_metrics, category}, _from, state) do
    metrics = Map.get(state.metrics, category, %{})
    {:reply, metrics, state}
  end
  
  def handle_call(:get_alerts, _from, state) do
    {:reply, state.alerts, state}
  end
  
  def handle_call({:get_history, metric_name, duration_minutes}, _from, state) do
    cutoff_time = DateTime.add(DateTime.utc_now(), -duration_minutes * 60, :second)
    
    history = state.history
    |> Map.get(metric_name, [])
    |> Enum.filter(fn {timestamp, _value} ->
      DateTime.compare(timestamp, cutoff_time) == :gt
    end)
    
    {:reply, history, state}
  end
  
  def handle_call(:subscribe, {pid, _}, state) do
    Process.monitor(pid)
    new_subscribers = [pid | state.subscribers] |> Enum.uniq()
    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end
  
  def handle_cast({:set_threshold, metric_name, threshold}, state) do
    new_thresholds = Map.put(state.thresholds, metric_name, threshold)
    {:noreply, %{state | thresholds: new_thresholds}}
  end
  
  def handle_cast({:unsubscribe, pid}, state) do
    new_subscribers = List.delete(state.subscribers, pid)
    {:noreply, %{state | subscribers: new_subscribers}}
  end
  
  def handle_cast(:force_refresh, state) do
    send(self(), :collect_metrics)
    {:noreply, state}
  end
  
  def handle_info(:collect_metrics, state) do
    # Collect metrics from all components
    new_metrics = collect_all_metrics()
    
    # Update history
    new_history = update_metric_history(state.history, new_metrics)
    
    # Broadcast to subscribers
    broadcast_metrics(state.subscribers, new_metrics)
    
    # Schedule next collection
    Process.cancel_timer(state.refresh_timer)
    refresh_timer = Process.send_after(self(), :collect_metrics, @refresh_interval)
    
    {:noreply, %{state |
      metrics: new_metrics,
      history: new_history,
      refresh_timer: refresh_timer
    }}
  end
  
  def handle_info(:check_alerts, state) do
    # Check for alert conditions
    new_alerts = check_alert_conditions(state.metrics, state.thresholds)
    
    # Notify if new alerts
    if new_alerts != state.alerts do
      broadcast_alerts(state.subscribers, new_alerts)
    end
    
    # Schedule next check
    Process.cancel_timer(state.alert_timer)
    alert_timer = Process.send_after(self(), :check_alerts, @alert_check_interval)
    
    {:noreply, %{state | alerts: new_alerts, alert_timer: alert_timer}}
  end
  
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_subscribers = List.delete(state.subscribers, pid)
    {:noreply, %{state | subscribers: new_subscribers}}
  end
  
  # Private Functions
  
  defp init_thresholds do
    %{
      # System thresholds
      cpu_usage: %{max: 0.8, min: nil},
      memory_usage: %{max: 0.9, min: nil},
      
      # Neural thresholds
      neuron_activation_rate: %{max: nil, min: 0.1},
      dead_neurons: %{max: 100, min: nil},
      
      # Pattern thresholds
      pattern_match_time: %{max: 50, min: nil},
      pattern_confidence: %{max: nil, min: 0.6},
      
      # Activity thresholds
      activity_error_rate: %{max: 0.1, min: nil},
      activity_backlog: %{max: 1000, min: nil},
      
      # Performance thresholds
      response_time_p99: %{max: 1000, min: nil},
      throughput: %{max: nil, min: 100}
    }
  end
  
  defp collect_all_metrics do
    %{
      system: collect_system_metrics(),
      neural: collect_neural_metrics(),
      patterns: collect_pattern_metrics(),
      memory: collect_memory_metrics(),
      activity: collect_activity_metrics(),
      performance: collect_performance_metrics(),
      storage: collect_storage_metrics(),
      health: collect_health_metrics()
    }
  end
  
  defp collect_system_metrics do
    memory_data = :erlang.memory()
    scheduler_usage = :scheduler.utilization(1)
    
    %{
      timestamp: DateTime.utc_now(),
      cpu_usage: calculate_cpu_usage(scheduler_usage),
      memory_usage: memory_data[:total] / memory_data[:system],
      memory_mb: memory_data[:total] / 1_048_576,
      processes: :erlang.system_info(:process_count),
      uptime_seconds: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000),
      otp_release: :erlang.system_info(:otp_release),
      node: Node.self()
    }
  end
  
  defp collect_neural_metrics do
    neuron_stats = NeuronStats.get_stats()
    brain_state = Brain.get_state()
    
    all_neurons = NeuronRegistry.all_neurons()
    alive_count = Enum.count(all_neurons, fn {_id, pid} -> Process.alive?(pid) end)
    
    %{
      total_neurons: 10_000,
      alive_neurons: alive_count,
      dead_neurons: 10_000 - alive_count,
      total_activations: neuron_stats.total_activations,
      activation_rate: calculate_activation_rate(neuron_stats),
      consciousness_level: brain_state.consciousness_level,
      quantum_coherence: brain_state.quantum_state.coherence,
      most_active_neurons: neuron_stats.most_active_neurons,
      error_prone_neurons: neuron_stats.error_prone_neurons
    }
  end
  
  defp collect_pattern_metrics do
    patterns_count = length(Patterns.export_all())
    pattern_stats = PatternPersistence.get_stats()
    
    %{
      total_patterns: patterns_count,
      patterns_loaded: pattern_stats.patterns_loaded,
      pattern_confidence_avg: calculate_average_confidence(),
      pattern_match_time_avg: get_pattern_match_time(),
      patterns_persisted: pattern_stats.patterns_persisted,
      persist_operations: pattern_stats.persist_operations,
      last_persist_duration_ms: pattern_stats.last_persist_duration_ms
    }
  end
  
  defp collect_memory_metrics do
    memory_stats = Memory.get_stats()
    
    %{
      short_term_entries: memory_stats.short_term.count,
      long_term_entries: memory_stats.long_term.count,
      episodic_entries: memory_stats.episodic.count,
      semantic_entries: memory_stats.semantic.count,
      total_memory_entries: memory_stats.total_entries,
      memory_hit_rate: memory_stats.hit_rate,
      memory_evictions: memory_stats.evictions,
      oldest_memory: memory_stats.oldest_entry
    }
  end
  
  defp collect_activity_metrics do
    activity_stats = ActivityIntelligence.get_stats()
    classifier_metrics = SuccessFailureClassifier.get_accuracy_metrics()
    
    %{
      total_activities: activity_stats.total_activities,
      recent_activities: activity_stats.activities_last_hour,
      activity_patterns: map_size(activity_stats.patterns),
      success_rate: activity_stats.success_rate,
      failure_rate: activity_stats.failure_rate,
      classifier_accuracy: classifier_metrics.accuracy,
      classifier_precision: classifier_metrics.precision,
      classifier_recall: classifier_metrics.recall,
      classifier_f1_score: classifier_metrics.f1_score
    }
  end
  
  defp collect_performance_metrics do
    # Collect performance metrics from various sources
    workflow_stats = get_workflow_stats()
    
    %{
      avg_response_time_ms: calculate_avg_response_time(),
      response_time_p95_ms: calculate_percentile_response_time(0.95),
      response_time_p99_ms: calculate_percentile_response_time(0.99),
      requests_per_second: calculate_throughput(),
      workflow_optimization_rate: workflow_stats.optimization_rate,
      recommendation_accuracy: get_recommendation_accuracy(),
      pattern_learning_rate: get_pattern_learning_rate()
    }
  end
  
  defp collect_storage_metrics do
    backup_stats = get_backup_stats()
    
    %{
      database_size_mb: get_database_size(),
      pattern_storage_mb: get_pattern_storage_size(),
      backup_count: backup_stats.backup_count,
      total_backup_size_mb: backup_stats.total_size_mb,
      last_backup_age_hours: backup_stats.last_backup_age_hours,
      disk_usage_percent: calculate_disk_usage()
    }
  end
  
  defp collect_health_metrics do
    %{
      system_health: calculate_system_health(),
      neural_health: calculate_neural_health(),
      pattern_health: calculate_pattern_health(),
      memory_health: calculate_memory_health(),
      activity_health: calculate_activity_health(),
      overall_health: calculate_overall_health()
    }
  end
  
  defp calculate_cpu_usage(scheduler_usage) do
    # Average scheduler usage across all schedulers
    case scheduler_usage do
      {:ok, usage_list} ->
        total = Enum.sum(Enum.map(usage_list, & &1.utilization))
        total / length(usage_list)
      _ ->
        0.0
    end
  end
  
  defp calculate_activation_rate(stats) do
    # Activations per second over last minute
    if stats.total_activations > 0 do
      stats.total_activations / max(:erlang.system_info(:uptime) / 1000, 1)
    else
      0.0
    end
  end
  
  defp calculate_average_confidence do
    patterns = Patterns.export_all()
    if length(patterns) > 0 do
      total = Enum.sum(Enum.map(patterns, & &1["confidence"]))
      total / length(patterns)
    else
      0.0
    end
  end
  
  defp get_pattern_match_time do
    # Would need to implement timing collection
    :rand.uniform(20) + 5  # Placeholder: 5-25ms
  end
  
  defp get_workflow_stats do
    # Placeholder for workflow statistics
    %{
      optimization_rate: 0.75,
      workflows_analyzed: 156,
      optimizations_applied: 89
    }
  end
  
  defp calculate_avg_response_time do
    # Placeholder - would track actual response times
    :rand.uniform(50) + 10
  end
  
  defp calculate_percentile_response_time(percentile) do
    # Placeholder - would calculate from actual data
    base = calculate_avg_response_time()
    base * (1 + percentile)
  end
  
  defp calculate_throughput do
    # Placeholder - requests per second
    :rand.uniform(100) + 50
  end
  
  defp get_recommendation_accuracy do
    # Placeholder - would track recommendation feedback
    0.82
  end
  
  defp get_pattern_learning_rate do
    # Patterns learned per hour
    12.5
  end
  
  defp get_backup_stats do
    backups = BackupRestoreSystem.list_backups()
    
    total_size = Enum.sum(Enum.map(backups, & &1.size_bytes))
    last_backup = List.first(backups)
    
    last_backup_age = if last_backup do
      DateTime.diff(DateTime.utc_now(), last_backup.created_at, :hour)
    else
      999
    end
    
    %{
      backup_count: length(backups),
      total_size_mb: total_size / 1_048_576,
      last_backup_age_hours: last_backup_age
    }
  end
  
  defp get_database_size do
    # Query database size
    case Repo.query("SELECT pg_database_size(current_database())") do
      {:ok, %{rows: [[size]]}} -> size / 1_048_576
      _ -> 0
    end
  end
  
  defp get_pattern_storage_size do
    # Calculate pattern file sizes
    pattern_dir = "data/patterns"
    
    if File.exists?(pattern_dir) do
      Path.wildcard(Path.join(pattern_dir, "**/*"))
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&File.stat!/1)
      |> Enum.map(& &1.size)
      |> Enum.sum()
      |> Kernel./(1_048_576)
    else
      0
    end
  end
  
  defp calculate_disk_usage do
    # Get disk usage percentage
    case System.cmd("df", ["-h", "/"]) do
      {output, 0} ->
        lines = String.split(output, "\n")
        if length(lines) > 1 do
          parts = String.split(Enum.at(lines, 1), ~r/\s+/)
          usage_str = Enum.at(parts, 4, "0%")
          String.trim_trailing(usage_str, "%") |> String.to_integer()
        else
          0
        end
      _ ->
        0
    end
  end
  
  defp calculate_system_health do
    cpu = get_in(collect_system_metrics(), [:cpu_usage])
    memory = get_in(collect_system_metrics(), [:memory_usage])
    
    cond do
      cpu > 0.9 or memory > 0.95 -> :critical
      cpu > 0.8 or memory > 0.9 -> :warning
      cpu > 0.7 or memory > 0.8 -> :fair
      true -> :good
    end
  end
  
  defp calculate_neural_health do
    metrics = collect_neural_metrics()
    dead_ratio = metrics.dead_neurons / metrics.total_neurons
    
    cond do
      dead_ratio > 0.1 -> :critical
      dead_ratio > 0.05 -> :warning
      dead_ratio > 0.02 -> :fair
      true -> :good
    end
  end
  
  defp calculate_pattern_health do
    confidence = calculate_average_confidence()
    
    cond do
      confidence < 0.5 -> :critical
      confidence < 0.6 -> :warning
      confidence < 0.7 -> :fair
      true -> :good
    end
  end
  
  defp calculate_memory_health do
    stats = Memory.get_stats()
    hit_rate = stats.hit_rate
    
    cond do
      hit_rate < 0.5 -> :critical
      hit_rate < 0.7 -> :warning
      hit_rate < 0.8 -> :fair
      true -> :good
    end
  end
  
  defp calculate_activity_health do
    stats = ActivityIntelligence.get_stats()
    error_rate = stats.failure_rate
    
    cond do
      error_rate > 0.3 -> :critical
      error_rate > 0.2 -> :warning
      error_rate > 0.1 -> :fair
      true -> :good
    end
  end
  
  defp calculate_overall_health do
    healths = [
      calculate_system_health(),
      calculate_neural_health(),
      calculate_pattern_health(),
      calculate_memory_health(),
      calculate_activity_health()
    ]
    
    critical_count = Enum.count(healths, &(&1 == :critical))
    warning_count = Enum.count(healths, &(&1 == :warning))
    
    cond do
      critical_count > 0 -> :critical
      warning_count > 2 -> :warning
      warning_count > 0 -> :fair
      true -> :good
    end
  end
  
  defp update_metric_history(history, metrics) do
    timestamp = DateTime.utc_now()
    
    # Flatten metrics and update history
    flat_metrics = flatten_metrics(metrics)
    
    Enum.reduce(flat_metrics, history, fn {key, value}, acc ->
      if is_number(value) do
        current_history = Map.get(acc, key, [])
        new_entry = {timestamp, value}
        new_history = [new_entry | current_history] |> Enum.take(@metric_history_size)
        Map.put(acc, key, new_history)
      else
        acc
      end
    end)
  end
  
  defp flatten_metrics(metrics, prefix \\ "") do
    Enum.flat_map(metrics, fn {key, value} ->
      new_key = if prefix == "", do: to_string(key), else: "#{prefix}.#{key}"
      
      case value do
        %{} = map ->
          flatten_metrics(map, new_key)
        list when is_list(list) ->
          []  # Skip lists
        _ ->
          [{new_key, value}]
      end
    end)
  end
  
  defp check_alert_conditions(metrics, thresholds) do
    flat_metrics = flatten_metrics(metrics)
    
    Enum.flat_map(thresholds, fn {metric_name, threshold} ->
      metric_key = to_string(metric_name)
      current_value = Keyword.get(flat_metrics, metric_key)
      
      if current_value do
        alerts = []
        
        alerts = if threshold.max && current_value > threshold.max do
          [%{
            type: :threshold_exceeded,
            severity: :warning,
            metric: metric_name,
            value: current_value,
            threshold: threshold.max,
            message: "#{metric_name} exceeded maximum threshold"
          } | alerts]
        else
          alerts
        end
        
        alerts = if threshold.min && current_value < threshold.min do
          [%{
            type: :threshold_below,
            severity: :warning,
            metric: metric_name,
            value: current_value,
            threshold: threshold.min,
            message: "#{metric_name} below minimum threshold"
          } | alerts]
        else
          alerts
        end
        
        alerts
      else
        []
      end
    end)
  end
  
  defp broadcast_metrics(subscribers, metrics) do
    message = {:metrics_update, metrics}
    Enum.each(subscribers, &send(&1, message))
  end
  
  defp broadcast_alerts(subscribers, alerts) do
    message = {:alerts_update, alerts}
    Enum.each(subscribers, &send(&1, message))
  end
end