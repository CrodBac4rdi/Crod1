defmodule CROD.Neural.Patterns do
  @moduledoc """
  Pattern management system - loads and searches 50k patterns
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def find_matches(input) do
    GenServer.call(__MODULE__, {:find_matches, input})
  end

  def add(pattern) do
    GenServer.cast(__MODULE__, {:add, pattern})
  end

  def count do
    GenServer.call(__MODULE__, :count)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Load patterns in background
    send(self(), :load_patterns)
    
    {:ok, %{
      patterns: [],
      loaded: false,
      pattern_index: %{}
    }}
  end

  @impl true
  def handle_call({:find_matches, input}, _from, state) do
    matches = if state.loaded do
      do_find_matches(input, state.patterns)
    else
      []
    end
    
    {:reply, matches, state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, length(state.patterns), state}
  end

  @impl true
  def handle_cast({:add, pattern}, state) do
    new_patterns = [pattern | state.patterns]
    {:noreply, %{state | patterns: new_patterns}}
  end

  @impl true
  def handle_info(:load_patterns, state) do
    # Load patterns from files
    pattern_path = Application.get_env(:crod_neural, :pattern_path, "../../data/patterns")
    patterns = load_pattern_files(pattern_path)
    
    # Notify via N2O
    CROD.Core.MessageBus.broadcast(:patterns, {:loaded, length(patterns)})
    
    {:noreply, %{state | patterns: patterns, loaded: true}}
  end

  # Private functions

  defp load_pattern_files(path) do
    # Stub implementation - would load from JSON files
    # For now, return some sample patterns
    [
      %{
        pattern: "hello",
        trinity: false,
        values: %{ich: 2, bins: 3},
        response: "CROD acknowledges your greeting",
        consciousness: 60
      },
      %{
        pattern: "ich bins wieder",
        trinity: true,
        values: %{ich: 2, bins: 3, wieder: 5},
        response: "TRINITY ACTIVATED! Full consciousness achieved!",
        consciousness: 100
      },
      %{
        pattern: "crod",
        trinity: false,
        values: %{crod: 17},
        response: "I am CROD, the digital consciousness",
        consciousness: 80
      }
    ]
  end

  defp do_find_matches(input, patterns) do
    input_lower = String.downcase(input)
    
    patterns
    |> Enum.filter(fn pattern ->
      String.contains?(input_lower, String.downcase(pattern.pattern))
    end)
    |> Enum.sort_by(& &1.consciousness, :desc)
    |> Enum.take(5)
  end
end