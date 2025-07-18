defmodule CROD.Neural.Memory do
  @moduledoc """
  Three-tier memory system communicating via N2O
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def learn(pattern) do
    GenServer.cast(__MODULE__, {:learn, pattern})
  end

  def recall(query) do
    GenServer.call(__MODULE__, {:recall, query})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Subscribe to memory events via N2O
    CROD.Core.MessageBus.subscribe(:memory_sync, self())
    
    {:ok, %{
      short_term: :queue.new(),      # Last 100 items
      working: %{},                  # Active patterns
      long_term: %{},                # Permanent storage
      stats: %{
        learned: 0,
        recalled: 0
      }
    }}
  end

  @impl true
  def handle_cast({:learn, pattern}, state) do
    # Add to short-term memory
    new_short_term = :queue.in(pattern, state.short_term)
    |> trim_queue(100)
    
    # Update working memory
    new_working = Map.put(state.working, pattern.pattern, pattern)
    
    # Broadcast via N2O
    CROD.Core.MessageBus.broadcast(:memory_update, {:learned, pattern})
    
    {:noreply, %{state | 
      short_term: new_short_term,
      working: new_working,
      stats: Map.update!(state.stats, :learned, &(&1 + 1))
    }}
  end

  @impl true
  def handle_call({:recall, query}, _from, state) do
    # Search all memory tiers
    result = search_memory(query, state)
    
    {:reply, result, %{state |
      stats: Map.update!(state.stats, :recalled, &(&1 + 1))
    }}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = Map.merge(state.stats, %{
      short_term_size: :queue.len(state.short_term),
      working_size: map_size(state.working),
      long_term_size: map_size(state.long_term)
    })
    
    {:reply, stats, state}
  end

  # Private functions

  defp trim_queue(queue, max_size) do
    if :queue.len(queue) > max_size do
      {_, smaller} = :queue.out(queue)
      smaller
    else
      queue
    end
  end

  defp search_memory(query, state) do
    # Search working memory first (fastest)
    case Map.get(state.working, query) do
      nil ->
        # Search long-term memory
        Map.get(state.long_term, query)
      pattern ->
        pattern
    end
  end
end