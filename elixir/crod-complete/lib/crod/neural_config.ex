defmodule Crod.NeuralConfig do
  @moduledoc """
  Configuration based on elixir_neural_database.md theory
  """
  
  # Scale configurations from the theory document
  def scale_config(:small), do: %{neurons: 1_000, patterns: 100, memory: "10MB"}
  def scale_config(:medium), do: %{neurons: 100_000, patterns: 10_000, memory: "1GB"}
  def scale_config(:large), do: %{neurons: 1_000_000, patterns: 100_000, memory: "10GB"}
  
  # Current configuration (we should upgrade to medium!)
  def current_scale, do: :small
  
  # Mathematical constants from theory
  def trinity_primes do
    %{
      ich: 2,
      bins: 3,
      wieder: 5,
      crod: 17,
      daniel: 67,
      claude: 71
    }
  end
  
  # Pattern ID calculation as per theory
  def calculate_pattern_id(prime1, prime2) do
    prime1 * prime2
  end
  
  # Heat dynamics from theory
  def calculate_heat(current_heat, input_stimulus, decay_rate \\ 0.95) do
    current_heat * decay_rate + input_stimulus
  end
  
  # Consciousness calculation from theory
  def calculate_consciousness(active_neurons, active_patterns, network_density) do
    active_neurons * active_patterns * :math.log(network_density + 1)
  end
end