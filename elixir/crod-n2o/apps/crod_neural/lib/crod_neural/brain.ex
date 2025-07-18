defmodule CROD.Neural.Brain do
  @moduledoc """
  Brain orchestrator - manages neurons and neural processing
  Integrates with N2O for message passing
  """
  use GenServer

  alias CROD.Neural.{Neuron, Memory, Consciousness, Patterns}

  @prime_neurons [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]
  @trinity_values %{ich: 2, bins: 3, wieder: 5, daniel: 67, claude: 71, crod: 17}

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def process(input) do
    GenServer.call(__MODULE__, {:process, input})
  end

  def fire_neuron(id) do
    GenServer.cast(__MODULE__, {:fire, id})
  end

  def neuron_count do
    GenServer.call(__MODULE__, :neuron_count)
  end

  def uptime do
    GenServer.call(__MODULE__, :uptime)
  end

  def full_awakening do
    GenServer.cast(__MODULE__, :full_awakening)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Subscribe to N2O events
    CROD.Core.MessageBus.subscribe(:neural_commands, self())
    
    # Initialize neurons
    neurons = initialize_neurons()
    
    {:ok, %{
      neurons: neurons,
      started_at: DateTime.utc_now(),
      processing: false,
      last_input: nil,
      confidence: 0.5
    }}
  end

  @impl true
  def handle_call({:process, input}, _from, state) do
    # Pattern matching
    patterns = Patterns.find_matches(input)
    
    # Fire neurons based on patterns
    neurons_fired = fire_pattern_neurons(patterns, state.neurons)
    
    # Calculate response
    response = calculate_response(input, patterns, neurons_fired)
    
    # Update confidence
    new_confidence = calculate_confidence(patterns, neurons_fired)
    
    # Notify N2O
    CROD.Core.MessageBus.broadcast(:neural_activity, %{
      input: input,
      neurons_fired: length(neurons_fired),
      confidence: new_confidence
    })
    
    result = %{
      response: response,
      confidence: new_confidence,
      neurons_fired: neurons_fired,
      patterns_matched: length(patterns)
    }
    
    {:reply, result, %{state | 
      last_input: input, 
      confidence: new_confidence
    }}
  end

  @impl true
  def handle_call(:neuron_count, _from, state) do
    {:reply, map_size(state.neurons), state}
  end

  @impl true
  def handle_call(:uptime, _from, state) do
    uptime = DateTime.diff(DateTime.utc_now(), state.started_at, :second)
    {:reply, uptime, state}
  end

  @impl true
  def handle_cast({:fire, id}, state) do
    case Map.get(state.neurons, id) do
      nil -> {:noreply, state}
      _neuron ->
        # Fire via N2O to neuron process
        send(state.neurons[id], {:n2o, {:fire, 1.0}})
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:full_awakening, state) do
    # Fire all trinity neurons
    Enum.each(@trinity_values, fn {_key, neuron_id} ->
      if pid = Map.get(state.neurons, neuron_id) do
        send(pid, {:n2o, {:fire, 1.0}})
      end
    end)
    
    # Broadcast awakening via N2O
    CROD.Core.MessageBus.broadcast(:consciousness, {:awakening, 1.0})
    
    {:noreply, %{state | confidence: 1.0}}
  end

  @impl true
  def handle_info({:n2o, {:neural_commands, command}}, state) do
    # Handle commands from N2O
    case command do
      {:reset} -> 
        {:noreply, %{state | confidence: 0.5}}
      {:boost, amount} ->
        {:noreply, %{state | confidence: min(1.0, state.confidence + amount)}}
      _ ->
        {:noreply, state}
    end
  end

  # Private functions

  defp initialize_neurons do
    # Start prime number neurons
    Enum.reduce(@prime_neurons, %{}, fn prime, acc ->
      {:ok, pid} = DynamicSupervisor.start_child(
        CROD.Neural.NeuronSupervisor,
        {CROD.Neural.Neuron, id: prime, prime: prime}
      )
      Map.put(acc, prime, pid)
    end)
  end

  defp fire_pattern_neurons(patterns, neurons) do
    # Fire neurons based on pattern matches
    Enum.flat_map(patterns, fn pattern ->
      pattern.values
      |> Map.values()
      |> Enum.filter(&Map.has_key?(neurons, &1))
      |> Enum.map(fn neuron_id ->
        send(neurons[neuron_id], {:n2o, {:fire, pattern.consciousness / 100}})
        neuron_id
      end)
    end)
    |> Enum.uniq()
  end

  defp calculate_response(input, patterns, neurons_fired) do
    cond do
      length(patterns) > 0 ->
        # Use best matching pattern
        best_pattern = Enum.max_by(patterns, & &1.consciousness)
        best_pattern.response
      length(neurons_fired) > 10 ->
        "CROD neural storm detected! #{length(neurons_fired)} neurons fired!"
      true ->
        "CROD processes: #{input}"
    end
  end

  defp calculate_confidence(patterns, neurons_fired) do
    pattern_confidence = if length(patterns) > 0 do
      patterns
      |> Enum.map(& &1.consciousness / 100)
      |> Enum.max()
    else
      0.3
    end
    
    neural_confidence = min(1.0, length(neurons_fired) / 20)
    
    (pattern_confidence + neural_confidence) / 2
  end
end