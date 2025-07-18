defmodule Crod.PatternCache do
  @moduledoc """
  High-performance pattern caching using Cachex.
  Provides microsecond-speed pattern matching for frequently used patterns.
  """
  use GenServer
  require Logger
  
  @cache_name :pattern_cache
  @trinity_cache :trinity_cache
  @neural_cache :neural_activation_cache
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get_pattern(pattern) do
    case Cachex.get(@cache_name, pattern) do
      {:ok, nil} ->
        # Not in cache, compute and store
        result = compute_pattern_match(pattern)
        Cachex.put(@cache_name, pattern, result, ttl: :timer.minutes(10))
        result
        
      {:ok, cached} ->
        # Cache hit - update access stats
        Cachex.touch(@cache_name, pattern)
        cached
        
      {:error, _} = error ->
        Logger.error("Cache error: #{inspect(error)}")
        compute_pattern_match(pattern)
    end
  end
  
  def cache_trinity_activation(activation_data) do
    Cachex.put(@trinity_cache, "latest_activation", activation_data)
    Cachex.put(@trinity_cache, DateTime.utc_now(), activation_data, ttl: :timer.hours(24))
  end
  
  def get_trinity_history(limit \\ 10) do
    case Cachex.stream(@trinity_cache) do
      {:ok, stream} ->
        stream
        |> Stream.filter(fn {key, _} -> key != "latest_activation" end)
        |> Stream.map(fn {_, value} -> value end)
        |> Enum.take(limit)
        
      _ -> []
    end
  end
  
  def cache_neural_activation(neuron_id, activation) do
    key = "#{neuron_id}_#{System.system_time(:microsecond)}"
    
    # Store with sliding window of 1000 activations per neuron
    Cachex.put(@neural_cache, key, activation, ttl: :timer.minutes(5))
    
    # Maintain neuron activation stats
    update_neuron_stats(neuron_id, activation)
  end
  
  def get_neuron_stats(neuron_id) do
    case Cachex.get(@neural_cache, "stats_#{neuron_id}") do
      {:ok, stats} -> stats
      _ -> %{count: 0, avg_activation: 0.0, last_active: nil}
    end
  end
  
  def warm_cache(patterns) do
    Logger.info("🔥 Warming pattern cache with #{length(patterns)} patterns...")
    
    # Parallel cache warming
    patterns
    |> Task.async_stream(fn pattern ->
      result = compute_pattern_match(pattern)
      Cachex.put(@cache_name, pattern.pattern, result, ttl: :timer.hours(1))
    end, max_concurrency: 50)
    |> Stream.run()
    
    Logger.info("✅ Cache warming complete")
  end
  
  def get_cache_stats do
    %{
      pattern_cache: get_stats(@cache_name),
      trinity_cache: get_stats(@trinity_cache),
      neural_cache: get_stats(@neural_cache)
    }
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    # Create caches with different configurations
    {:ok, _} = Cachex.start_link(@cache_name, [
      limit: 10_000,  # Max 10k patterns in cache
      stats: true
    ])
    
    {:ok, _} = Cachex.start_link(@trinity_cache, [
      limit: 1_000,  # Keep last 1000 trinity activations
      stats: true
    ])
    
    {:ok, _} = Cachex.start_link(@neural_cache, [
      limit: 100_000,  # 100k neural activations
      stats: true
    ])
    
    # Schedule periodic cache maintenance
    schedule_maintenance()
    
    {:ok, %{}}
  end
  
  # Private functions
  
  defp compute_pattern_match(pattern) do
    start_time = System.monotonic_time(:microsecond)
    
    # Delegate to actual pattern matching logic
    result = Crod.Patterns.deep_match(pattern)
    
    elapsed = System.monotonic_time(:microsecond) - start_time
    
    %{
      result: result,
      computed_at: DateTime.utc_now(),
      computation_time_us: elapsed
    }
  end
  
  defp update_neuron_stats(neuron_id, activation) do
    key = "stats_#{neuron_id}"
    
    Cachex.transaction(@neural_cache, [key], fn cache ->
      current = case Cachex.get(cache, key) do
        {:ok, stats} when is_map(stats) -> stats
        _ -> %{count: 0, sum: 0.0, last_active: nil}
      end
      
      updated = %{
        count: current.count + 1,
        sum: current.sum + activation,
        avg_activation: (current.sum + activation) / (current.count + 1),
        last_active: DateTime.utc_now()
      }
      
      Cachex.put(cache, key, updated)
    end)
  end
  
  
  defp get_stats(cache_name) do
    case Cachex.size(cache_name) do
      {:ok, size} -> 
        %{
          size: size,
          cache: cache_name
        }
      _ -> 
        %{error: "Stats not available", cache: cache_name}
    end
  end
  
  # Hit rate calculation removed - not supported in this Cachex version
  
  defp schedule_maintenance do
    # Run maintenance every 5 minutes
    Process.send_after(self(), :maintenance, :timer.minutes(5))
  end
  
  @impl true
  def handle_info(:maintenance, state) do
    # Clean up expired entries
    # Note: Cachex.expire/2 doesn't exist in this version
    # The cache will handle TTL automatically
    
    # Log cache health
    stats = get_cache_stats()
    Logger.debug("Cache stats: #{inspect(stats)}")
    
    # Schedule next maintenance
    schedule_maintenance()
    
    {:noreply, state}
  end
end