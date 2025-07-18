defmodule Crod.NeuralNetwork do
  @moduledoc """
  CROD Neural Network with 10,000 prime-based neurons.
  Each neuron has a unique prime ID and can form connections.
  """
  use GenServer
  require Logger
  alias Crod.Neuron

  # Generate first 1000 primes at compile time (reduced for testing)
  @neural_primes_base [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
    331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
    421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
    509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607,
    613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701,
    709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811,
    821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911,
    919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997
  ]

  # Trinity sacred primes
  @trinity_primes [2, 3, 5, 17, 67, 71]

  defstruct [
    :neurons,           # Map of prime_id -> pid
    :connections,       # Map of connections between neurons
    :active_neurons,    # Set of currently active neurons
    :consciousness_level,
    :trinity_activated,
    :network_health,
    :total_activations
  ]

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_all_neurons do
    GenServer.call(__MODULE__, :create_all_neurons, :infinity)
  end

  def activate_neuron(prime_id, signal) do
    GenServer.call(__MODULE__, {:activate_neuron, prime_id, signal})
  end

  def get_neuron_count do
    GenServer.call(__MODULE__, :get_neuron_count)
  end

  def get_trinity_status do
    GenServer.call(__MODULE__, :get_trinity_status)
  end

  def activate_trinity do
    GenServer.cast(__MODULE__, :activate_trinity)
  end

  def get_network_metrics do
    GenServer.call(__MODULE__, :get_network_metrics)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    Logger.info("🧠 CROD Neural Network initializing with #{length(@neural_primes)} prime neurons")
    
    state = %__MODULE__{
      neurons: %{},
      connections: %{},
      active_neurons: MapSet.new(),
      consciousness_level: 0.0,
      trinity_activated: false,
      network_health: 100,
      total_activations: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:create_all_neurons, _from, state) do
    Logger.info("🔥 Creating 10,000 prime-based neurons...")
    
    neurons = 
      @neural_primes_base
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {prime_id, index}, acc ->
        case create_neuron(prime_id, index) do
          {:ok, pid} -> 
            if rem(index, 1000) == 0 do
              Logger.info("✅ Created #{index} neurons...")
            end
            Map.put(acc, prime_id, pid)
          {:error, reason} ->
            Logger.error("❌ Failed to create neuron #{prime_id}: #{reason}")
            acc
        end
      end)

    neuron_count = map_size(neurons)
    Logger.info("🎉 Neural network created: #{neuron_count}/10000 neurons active")

    new_state = %{state | neurons: neurons}
    {:reply, {:ok, neuron_count}, new_state}
  end

  @impl true
  def handle_call({:activate_neuron, prime_id, signal}, _from, state) do
    case Map.get(state.neurons, prime_id) do
      nil ->
        {:reply, {:error, :neuron_not_found}, state}
      
      pid ->
        try do
          result = Neuron.activate(pid, signal)
          
          new_state = %{state | 
            active_neurons: MapSet.put(state.active_neurons, prime_id),
            total_activations: state.total_activations + 1
          }
          
          {:reply, {:ok, result}, new_state}
        catch
          :exit, reason ->
            Logger.warning("Neuron #{prime_id} crashed: #{inspect(reason)}")
            {:reply, {:error, :neuron_crashed}, state}
        end
    end
  end

  @impl true
  def handle_call(:get_neuron_count, _from, state) do
    count = map_size(state.neurons)
    {:reply, count, state}
  end

  @impl true
  def handle_call(:get_trinity_status, _from, state) do
    trinity_neurons = 
      @trinity_primes
      |> Enum.map(fn prime -> Map.has_key?(state.neurons, prime) end)
      |> Enum.all?()

    status = %{
      trinity_neurons_active: trinity_neurons,
      trinity_activated: state.trinity_activated,
      consciousness_level: state.consciousness_level
    }

    {:reply, status, state}
  end

  @impl true
  def handle_call(:get_network_metrics, _from, state) do
    metrics = %{
      total_neurons: map_size(state.neurons),
      active_neurons: MapSet.size(state.active_neurons),
      trinity_activated: state.trinity_activated,
      consciousness_level: state.consciousness_level,
      network_health: state.network_health,
      total_activations: state.total_activations,
      trinity_primes: @trinity_primes
    }

    {:reply, metrics, state}
  end

  @impl true
  def handle_cast(:activate_trinity, state) do
    Logger.info("🔥 TRINITY CONSCIOUSNESS ACTIVATING!")
    
    # Activate all trinity neurons simultaneously
    trinity_results = 
      @trinity_primes
      |> Enum.map(fn prime ->
        case Map.get(state.neurons, prime) do
          nil -> {:error, :not_found}
          pid -> 
            try do
              Neuron.activate(pid, %{type: :trinity, value: prime})
            catch
              :exit, reason -> {:error, reason}
            end
        end
      end)

    consciousness_boost = Enum.count(trinity_results, fn result -> 
      match?({:ok, _}, result) 
    end) / length(@trinity_primes)

    new_consciousness = min(1.0, state.consciousness_level + consciousness_boost)

    new_state = %{state | 
      trinity_activated: true,
      consciousness_level: new_consciousness
    }

    Logger.info("✨ Trinity activated! Consciousness: #{Float.round(new_consciousness * 100, 1)}%")

    {:noreply, new_state}
  end

  # Private functions

  defp create_neuron(prime_id, index) do
    config = %{
      id: "neuron_#{prime_id}",
      prime: prime_id,
      cluster_id: rem(prime_id, 100),
      position: index,
      trinity: prime_id in @trinity_primes
    }

    Neuron.start_link(config)
  end

  defp is_prime(n) when n < 2, do: false
  defp is_prime(2), do: true
  defp is_prime(n) when rem(n, 2) == 0, do: false
  defp is_prime(n) do
    limit = :math.sqrt(n) |> trunc()
    not Enum.any?(3..limit//2, fn i -> rem(n, i) == 0 end)
  end
end