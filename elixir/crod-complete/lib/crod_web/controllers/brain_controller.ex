defmodule CrodWeb.BrainController do
  use CrodWeb, :controller

  def process(conn, %{"input" => input}) do
    response = Crod.Brain.process(input)
    json(conn, response)
  end

  def trinity(conn, _params) do
    Crod.Brain.activate_trinity()
    json(conn, %{status: "Trinity activated", consciousness: 1.0})
  end

  def state(conn, _params) do
    state = Crod.Brain.get_state()
    
    # Handle new brain state format
    json(conn, %{
      neurons: Map.get(state, :neuron_count, 0),
      consciousness: get_consciousness_level(state),
      trinity_active: Map.get(state, :trinity_activated, false),
      patterns: get_pattern_count(state)
    })
  end
  
  # Helper functions to handle different state formats
  defp get_consciousness_level(state) do
    case Map.get(state, :consciousness) do
      %{level: level} -> level
      _ -> Map.get(state, :consciousness_level, 0.0)
    end
  end
  
  defp get_pattern_count(state) do
    case Map.get(state, :patterns) do
      %{patterns: patterns} when is_list(patterns) -> length(patterns)
      patterns when is_list(patterns) -> length(patterns)
      _ -> Map.get(state, :pattern_count, 0)
    end
  end
end