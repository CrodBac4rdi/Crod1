defmodule Crod.Consciousness do
  @moduledoc """
  Consciousness and awareness system.
  Manages confidence levels and trinity activation.
  """

  defstruct [
    :level,
    :trinity_active,
    :last_update,
    :activation_history
  ]

  def new do
    %__MODULE__{
      level: 0.5,
      trinity_active: false,
      last_update: DateTime.utc_now(),
      activation_history: []
    }
  end

  def update(consciousness, activations, pattern_matches) do
    # Calculate new level based on neural activity and pattern matches
    neural_factor = calculate_neural_factor(activations)
    pattern_factor = calculate_pattern_factor(pattern_matches)

    # Time decay
    time_factor = calculate_time_decay(consciousness.last_update)

    # Combined consciousness level
    new_level = (consciousness.level * 0.7 + neural_factor * 0.2 + pattern_factor * 0.1) * time_factor
    new_level = min(1.0, max(0.0, new_level))
    # Mangel: Magic Numbers für Gewichtung (0.7, 0.2, 0.1) sollten konfigurierbar sein

    # Update history
    history = [{new_level, DateTime.utc_now()} | consciousness.activation_history]
    |> Enum.take(100)

    %{consciousness |
      level: new_level,
      last_update: DateTime.utc_now(),
      activation_history: history
    }
  end

  def activate_trinity(consciousness) do
    %{consciousness |
      trinity_active: true,
      level: 1.0,
      last_update: DateTime.utc_now()
    }
  end

  def level(%__MODULE__{level: level}), do: level

  # Private functions

  defp calculate_neural_factor(activations) do
    if Enum.empty?(activations) do
      0.0
    else
      # Mangel: Keine Validierung der Aktivierungswerte
      Enum.sum(activations) / max(1, length(activations))
    end
  end

  defp calculate_pattern_factor(pattern_matches) do
    if Enum.empty?(pattern_matches) do
      0.0
    else
      # Best match confidence
      pattern_matches
      |> Enum.map(& &1.confidence)
      |> Enum.max()
    end
  end

  defp calculate_time_decay(last_update) do
    elapsed_seconds = DateTime.diff(DateTime.utc_now(), last_update)
    decay_rate = 0.001 # Decay per second

    :math.exp(-decay_rate * elapsed_seconds)
  end
end
