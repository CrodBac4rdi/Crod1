defmodule Crod.NeuralNeuron do
  @moduledoc """
  Enhanced neuron using Nx tensors and Axon neural networks.
  Each neuron is a small neural network that can learn.
  """
  use GenServer
  require Nx
  
  defstruct [:id, :prime, :weights, :bias, :activation_history, :learning_rate]
  
  # Client API
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:id]))
  end
  
  def activate(neuron_id, inputs) do
    GenServer.call(via_tuple(neuron_id), {:activate, inputs})
  end
  
  def train(neuron_id, inputs, target) do
    GenServer.cast(via_tuple(neuron_id), {:train, inputs, target})
  end
  
  def get_state(neuron_id) do
    GenServer.call(via_tuple(neuron_id), :get_state)
  end
  
  # Server Callbacks
  
  @impl true
  def init(opts) do
    # Initialize with random weights based on prime number
    prime = opts[:prime] || 7
    input_size = opts[:input_size] || 10
    
    # Use prime as seed for reproducible initialization
    key = Nx.Random.key(prime)
    {weights, _key} = Nx.Random.normal(key, shape: {input_size, 1}, mean: 0.0, scale: 0.1)
    
    state = %__MODULE__{
      id: opts[:id],
      prime: prime,
      weights: weights,
      bias: Nx.tensor(0.0),
      activation_history: [],
      learning_rate: 0.01
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:activate, inputs}, _from, state) do
    # Convert inputs to tensor
    input_tensor = Nx.tensor(inputs)
    
    # Neural activation: w·x + b with sigmoid
    activation = 
      input_tensor
      |> Nx.dot(state.weights)
      |> Nx.add(state.bias)
      |> Nx.sigmoid()
      |> Nx.to_number()
    
    # Store activation in history (keep last 100)
    history = [activation | state.activation_history] |> Enum.take(100)
    
    # Prime number modulation - unique to each neuron
    modulated = activation * :math.sin(state.prime * activation)
    
    {:reply, modulated, %{state | activation_history: history}}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    summary = %{
      id: state.id,
      prime: state.prime,
      recent_activations: Enum.take(state.activation_history, 10),
      weight_norm: Nx.sum(Nx.pow(state.weights, 2)) |> Nx.to_number(),
      bias: Nx.to_number(state.bias)
    }
    
    {:reply, summary, state}
  end
  
  @impl true
  def handle_cast({:train, inputs, target}, state) do
    # Simple gradient descent training
    input_tensor = Nx.tensor(inputs)
    target_tensor = Nx.tensor(target)
    
    # Forward pass
    output = 
      input_tensor
      |> Nx.dot(state.weights)
      |> Nx.add(state.bias)
      |> Nx.sigmoid()
    
    # Calculate error
    error = Nx.subtract(target_tensor, output)
    
    # Backpropagation
    gradient = Nx.multiply(error, Nx.multiply(output, Nx.subtract(1, output)))
    
    # Update weights and bias
    weight_update = Nx.multiply(state.learning_rate, Nx.multiply(gradient, input_tensor))
    new_weights = Nx.add(state.weights, weight_update)
    
    bias_update = Nx.multiply(state.learning_rate, gradient)
    new_bias = Nx.add(state.bias, bias_update)
    
    {:noreply, %{state | weights: new_weights, bias: new_bias}}
  end
  
  # Private functions
  
  defp via_tuple(id) do
    {:via, Registry, {Crod.NeuronRegistry, id}}
  end
end