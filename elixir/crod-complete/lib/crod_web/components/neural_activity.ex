defmodule CrodWeb.Components.NeuralActivity do
  @moduledoc """
  LiveComponent for visualizing real-time neural network activity
  """
  
  use CrodWeb, :live_component
  
  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      visualization_mode: "2d",
      selected_neuron: nil,
      zoom_level: 1.0,
      show_connections: true
    )}
  end
  
  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:neurons, fn -> sample_neurons() end)
     |> assign_new(:connections, fn -> get_active_connections() end)}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="neural-activity-component">
      <div class="controls mb-4 flex items-center justify-between">
        <div class="flex space-x-2">
          <button 
            phx-click="set_mode" 
            phx-value-mode="2d"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @visualization_mode == "2d", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"}"}
          >
            2D Network
          </button>
          <button 
            phx-click="set_mode" 
            phx-value-mode="3d"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @visualization_mode == "3d", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"}"}
          >
            3D Sphere
          </button>
          <button 
            phx-click="set_mode" 
            phx-value-mode="heatmap"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @visualization_mode == "heatmap", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"}"}
          >
            Heatmap
          </button>
        </div>
        
        <div class="flex items-center space-x-4">
          <label class="flex items-center text-sm">
            <input 
              type="checkbox" 
              checked={@show_connections}
              phx-click="toggle_connections"
              phx-target={@myself}
              class="mr-2"
            />
            Show Connections
          </label>
          
          <div class="flex items-center space-x-2">
            <button 
              phx-click="zoom" 
              phx-value-direction="out"
              phx-target={@myself}
              class="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
              </svg>
            </button>
            <span class="text-sm text-gray-500"><%= round(@zoom_level * 100) %>%</span>
            <button 
              phx-click="zoom" 
              phx-value-direction="in"
              phx-target={@myself}
              class="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      
      <div class="visualization-container relative bg-gray-50 dark:bg-gray-900 rounded-lg overflow-hidden" style="height: 400px;">
        <%= case @visualization_mode do %>
          <% "2d" -> %>
            <div 
              id={"neural-viz-2d-#{@id}"} 
              phx-hook="NeuralVisualization2D"
              phx-update="ignore"
              data-neurons={Jason.encode!(@neurons)}
              data-connections={Jason.encode!(@connections)}
              data-show-connections={@show_connections}
              data-zoom={@zoom_level}
              class="w-full h-full"
            >
              <canvas class="w-full h-full"></canvas>
            </div>
          
          <% "3d" -> %>
            <div 
              id={"neural-viz-3d-#{@id}"} 
              phx-hook="NeuralVisualization3D"
              phx-update="ignore"
              data-neurons={Jason.encode!(@neurons)}
              data-connections={Jason.encode!(@connections)}
              data-zoom={@zoom_level}
              class="w-full h-full"
            />
          
          <% "heatmap" -> %>
            <div class="p-4 h-full">
              <.neural_heatmap neurons={@neurons} />
            </div>
        <% end %>
        
        <%= if @selected_neuron do %>
          <div class="absolute bottom-4 left-4 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-lg max-w-sm">
            <.neuron_details neuron={@selected_neuron} />
          </div>
        <% end %>
      </div>
      
      <div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
        <.neural_stat title="Active Neurons" value={count_active(@neurons)} />
        <.neural_stat title="Avg Activation" value={format_float(avg_activation(@neurons))} />
        <.neural_stat title="Connections" value={length(@connections)} />
        <.neural_stat title="Sync Score" value={format_percentage(calculate_sync(@neurons))} />
      </div>
    </div>
    """
  end
  
  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, visualization_mode: mode)}
  end
  
  def handle_event("toggle_connections", _params, socket) do
    {:noreply, update(socket, :show_connections, &(!&1))}
  end
  
  def handle_event("zoom", %{"direction" => direction}, socket) do
    new_zoom = case direction do
      "in" -> min(socket.assigns.zoom_level * 1.2, 3.0)
      "out" -> max(socket.assigns.zoom_level / 1.2, 0.3)
    end
    
    {:noreply, assign(socket, zoom_level: new_zoom)}
  end
  
  def handle_event("neuron_selected", %{"id" => neuron_id}, socket) do
    neuron = Enum.find(socket.assigns.neurons, &(&1.id == neuron_id))
    {:noreply, assign(socket, selected_neuron: neuron)}
  end
  
  # Private functions
  
  defp neural_heatmap(assigns) do
    grid_size = 100  # 100x100 grid
    grid = create_activation_grid(assigns.neurons, grid_size)
    
    ~H"""
    <div class="w-full h-full flex items-center justify-center">
      <div class="relative">
        <div class="grid grid-cols-100 gap-0" style="width: 300px; height: 300px;">
          <%= for {row, y} <- Enum.with_index(grid) do %>
            <%= for {value, x} <- Enum.with_index(row) do %>
              <div 
                class="w-3 h-3"
                style={"background-color: #{heatmap_color(value)}; opacity: #{value}"}
                title={"Activation: #{Float.round(value, 2)}"}
              />
            <% end %>
          <% end %>
        </div>
        <div class="absolute -bottom-8 left-0 right-0 flex justify-between text-xs text-gray-500">
          <span>Low</span>
          <span>Neural Activity</span>
          <span>High</span>
        </div>
      </div>
    </div>
    """
  end
  
  defp neuron_details(assigns) do
    ~H"""
    <div>
      <h4 class="font-semibold text-gray-900 dark:text-white mb-2">
        Neuron <%= @neuron.id %>
      </h4>
      <dl class="space-y-1 text-sm">
        <div class="flex justify-between">
          <dt class="text-gray-500 dark:text-gray-400">Prime:</dt>
          <dd class="font-medium"><%= @neuron.prime %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-500 dark:text-gray-400">Activation:</dt>
          <dd class="font-medium"><%= Float.round(@neuron.activation, 3) %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-500 dark:text-gray-400">Connections:</dt>
          <dd class="font-medium"><%= length(@neuron.connections) %></dd>
        </div>
        <%= if @neuron[:special] do %>
          <div class="flex justify-between">
            <dt class="text-gray-500 dark:text-gray-400">Type:</dt>
            <dd class="font-medium text-yellow-500"><%= @neuron.type %></dd>
          </div>
        <% end %>
      </dl>
      
      <%= if @neuron[:history] && length(@neuron.history) > 0 do %>
        <div class="mt-3">
          <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Recent Activity:</p>
          <div class="flex space-x-1">
            <%= for {activation, i} <- Enum.with_index(Enum.take(@neuron.history, 20)) do %>
              <div 
                class="w-1 bg-blue-500"
                style={"height: #{activation * 20}px; opacity: #{0.3 + (i / 20 * 0.7)}"}
                title={"#{Float.round(activation, 2)}"}
              />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
  
  defp neural_stat(assigns) do
    ~H"""
    <div class="bg-gray-100 dark:bg-gray-800 rounded p-3">
      <p class="text-xs text-gray-500 dark:text-gray-400"><%= @title %></p>
      <p class="text-lg font-semibold text-gray-900 dark:text-white"><%= @value %></p>
    </div>
    """
  end
  
  defp sample_neurons do
    # Get a representative sample of neurons for visualization
    all_neurons = Crod.Brain.get_all_neurons()
    
    # Take 100 neurons evenly distributed
    step = div(length(all_neurons), 100)
    
    all_neurons
    |> Enum.take_every(max(step, 1))
    |> Enum.take(100)
    |> Enum.map(fn neuron ->
      %{
        id: neuron.id,
        prime: neuron.prime,
        activation: neuron.activation,
        connections: Enum.take(neuron.connections, 5),  # Limit connections for performance
        x: :rand.uniform(),  # Random positions for initial layout
        y: :rand.uniform(),
        special: neuron[:special] || neuron.prime in [2, 3, 5, 17, 67, 71],
        type: cond do
          neuron.prime == 2 -> "ich"
          neuron.prime == 3 -> "bins"
          neuron.prime == 5 -> "wieder"
          neuron.prime == 17 -> "crod"
          neuron.prime == 67 -> "daniel"
          neuron.prime == 71 -> "claude"
          true -> nil
        end
      }
    end)
  end
  
  defp get_active_connections do
    # Get connections between sampled neurons
    neurons = sample_neurons()
    neuron_ids = MapSet.new(neurons, & &1.id)
    
    neurons
    |> Enum.flat_map(fn neuron ->
      neuron.connections
      |> Enum.filter(&MapSet.member?(neuron_ids, &1))
      |> Enum.map(fn target_id ->
        %{
          source: neuron.id,
          target: target_id,
          strength: :rand.uniform()
        }
      end)
    end)
    |> Enum.take(200)  # Limit connections for performance
  end
  
  defp create_activation_grid(neurons, size) do
    # Create a 2D grid representation of neural activation
    grid = for _ <- 1..size, do: for _ <- 1..size, do: 0.0
    
    # Map neurons to grid positions and spread activation
    Enum.reduce(neurons, grid, fn neuron, acc ->
      x = round(neuron.x * (size - 1))
      y = round(neuron.y * (size - 1))
      
      spread_activation(acc, x, y, neuron.activation, 3)
    end)
  end
  
  defp spread_activation(grid, x, y, activation, radius) do
    grid
    |> Enum.with_index()
    |> Enum.map(fn {row, row_idx} ->
      row
      |> Enum.with_index()
      |> Enum.map(fn {cell, col_idx} ->
        distance = :math.sqrt(:math.pow(row_idx - y, 2) + :math.pow(col_idx - x, 2))
        
        if distance <= radius do
          influence = activation * (1 - distance / radius)
          min(cell + influence, 1.0)
        else
          cell
        end
      end)
    end)
  end
  
  defp heatmap_color(value) do
    # Generate color based on activation value
    cond do
      value < 0.2 -> "#1e40af"  # Dark blue
      value < 0.4 -> "#2563eb"  # Blue
      value < 0.6 -> "#10b981"  # Green
      value < 0.8 -> "#f59e0b"  # Orange
      true -> "#ef4444"         # Red
    end
  end
  
  defp count_active(neurons) do
    Enum.count(neurons, &(&1.activation > 0.1))
  end
  
  defp avg_activation(neurons) do
    case neurons do
      [] -> 0.0
      neurons ->
        sum = Enum.sum(Enum.map(neurons, & &1.activation))
        sum / length(neurons)
    end
  end
  
  defp calculate_sync(neurons) do
    # Calculate synchronization score based on activation variance
    case neurons do
      [] -> 0.0
      [_] -> 1.0
      neurons ->
        activations = Enum.map(neurons, & &1.activation)
        mean = Enum.sum(activations) / length(activations)
        
        variance = Enum.sum(Enum.map(activations, fn a ->
          :math.pow(a - mean, 2)
        end)) / length(activations)
        
        # Lower variance = higher sync
        1.0 - min(variance, 1.0)
    end
  end
  
  defp format_float(f), do: Float.round(f, 3)
  defp format_percentage(f), do: "#{round(f * 100)}%"
end