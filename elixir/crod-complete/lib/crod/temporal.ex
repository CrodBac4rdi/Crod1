defmodule Crod.Temporal do
  @moduledoc """
  Time perception and temporal pattern recognition.
  Absorbs functionality from time MCP server.
  """

  defstruct [
    :current_time,
    :time_events,
    :temporal_patterns,
    :consciousness_timeline
  ]

  def new do
    %__MODULE__{
      current_time: DateTime.utc_now(),
      time_events: [],
      temporal_patterns: %{},
      consciousness_timeline: []
    }
  end

  def perceive_time(temporal, context \\ %{}) do
    # Time perception influenced by consciousness level
    consciousness_factor = Map.get(context, :consciousness_level, 0.5)

    # Subjective time can dilate or contract
    subjective_time = if consciousness_factor > 0.8 do
      # High consciousness = time slows down
      :slow_motion
    else
      :normal
    end

    %{temporal |
      current_time: DateTime.utc_now(),
      consciousness_timeline: [{DateTime.utc_now(), consciousness_factor} | temporal.consciousness_timeline]
      |> Enum.take(1000)
    }
  end

  def find_temporal_patterns(temporal, events) do
    # Analyze events for recurring patterns
    # Group by time intervals
    patterns = events
    |> Enum.group_by(&extract_time_component/1)
    |> Enum.map(fn {interval, events} ->
      {interval, length(events)}
    end)
    |> Map.new()

    %{temporal | temporal_patterns: patterns}
  end

  def apply_temporal_decay(memories, decay_rate \\ 0.001) do
    current_time = DateTime.utc_now()

    Enum.map(memories, fn memory ->
      age_seconds = DateTime.diff(current_time, memory.timestamp)
      decay_factor = :math.exp(-decay_rate * age_seconds)
      # Mangel: Keine Validierung ob memory.timestamp existiert und korrekt ist
      # Verbesserung: Validierung und Fehlerbehandlung ergänzen
      Map.put(memory, :decay_factor, decay_factor)
    end)
  end

  # Time-based queries
  def events_in_range(temporal, from, to) do
    temporal.time_events
    |> Enum.filter(fn event ->
      DateTime.compare(event.timestamp, from) in [:gt, :eq] and
      DateTime.compare(event.timestamp, to) in [:lt, :eq]
    end)
  end

  def consciousness_at_time(temporal, time) do
    # Find consciousness level at specific time
    temporal.consciousness_timeline
    |> Enum.find(fn {timestamp, _level} ->
      DateTime.compare(timestamp, time) in [:lt, :eq]
    end)
    |> case do
      {_timestamp, level} -> level
      nil -> 0.5  # Default consciousness
    end
  end

  # Private functions

  defp extract_time_component(event) do
    # Extract hour of day for pattern analysis
    event.timestamp.hour
  end
end
