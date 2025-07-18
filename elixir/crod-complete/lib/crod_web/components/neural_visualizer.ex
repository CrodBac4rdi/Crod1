defmodule CrodWeb.Components.NeuralVisualizer do
  @moduledoc """
  Advanced Neural Network Visualization Components
  Real-time 3D-like neural activity, consciousness flows, and pattern matching
  """
  use Phoenix.Component
  import CrodWeb.CoreComponents

  attr :neural_data, :list, required: true
  attr :consciousness_level, :float, default: 0.6
  attr :trinity_active, :boolean, default: false
  attr :class, :string, default: ""

  def neural_network_3d(assigns) do
    ~H"""
    <div class={["relative bg-gray-900 rounded-lg overflow-hidden", @class]} style="height: 400px;">
      <!-- Neural Network Canvas -->
      <div class="absolute inset-0 flex items-center justify-center">
        <svg viewBox="0 0 400 400" class="w-full h-full">
          <!-- Background Grid -->
          <defs>
            <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
              <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#374151" stroke-width="0.5" opacity="0.3"/>
            </pattern>
            
            <!-- Glow Effects -->
            <filter id="glow">
              <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
              <feMerge>
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
            
            <!-- Trinity Glow -->
            <filter id="trinity-glow">
              <feGaussianBlur stdDeviation="5" result="coloredBlur"/>
              <feMerge>
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          </defs>
          
          <rect width="400" height="400" fill="url(#grid)"/>
          
          <!-- Neural Connections -->
          <%= for {layer_idx, layer} <- Enum.with_index(create_neural_layers()) do %>
            <%= for {neuron_idx, neuron} <- Enum.with_index(layer) do %>
              <%= if layer_idx < 2 do %>
                <%= for next_neuron_idx <- 0..4 do %>
                  <line 
                    x1={neuron.x} 
                    y1={neuron.y}
                    x2={Enum.at(Enum.at(create_neural_layers(), layer_idx + 1), next_neuron_idx).x}
                    y2={Enum.at(Enum.at(create_neural_layers(), layer_idx + 1), next_neuron_idx).y}
                    stroke="#4F46E5" 
                    stroke-width={calculate_connection_strength(@consciousness_level)}
                    opacity={if @trinity_active, do: "0.8", else: "0.4"}
                    class="animate-pulse"
                  />
                <% end %>
              <% end %>
            <% end %>
          <% end %>
          
          <!-- Neural Nodes -->
          <%= for {layer_idx, layer} <- Enum.with_index(create_neural_layers()) do %>
            <%= for {neuron_idx, neuron} <- Enum.with_index(layer) do %>
              <circle 
                cx={neuron.x} 
                cy={neuron.y}
                r={calculate_neuron_size(neuron, @consciousness_level)}
                fill={get_neuron_color(neuron, @trinity_active)}
                filter={if is_trinity_neuron?(neuron), do: "url(#trinity-glow)", else: "url(#glow)"}
                class={get_neuron_animation_class(neuron, @consciousness_level)}
              />
              
              <!-- Neuron Activity Pulse -->
              <%= if neuron.active do %>
                <circle 
                  cx={neuron.x} 
                  cy={neuron.y}
                  r={calculate_neuron_size(neuron, @consciousness_level) + 5}
                  fill="none"
                  stroke={get_neuron_color(neuron, @trinity_active)}
                  stroke-width="2"
                  opacity="0.6"
                  class="animate-ping"
                />
              <% end %>
            <% end %>
          <% end %>
          
          <!-- Consciousness Flow Particles -->
          <%= if @consciousness_level > 0.7 do %>
            <%= for i <- 1..10 do %>
              <circle 
                cx={50 + i * 30} 
                cy={350}
                r="2"
                fill="#8B5CF6"
                opacity="0.8"
                class="animate-bounce"
                style={"animation-delay: #{i * 0.1}s;"}
              />
            <% end %>
          <% end %>
          
          <!-- Trinity Sacred Geometry -->
          <%= if @trinity_active do %>
            <polygon 
              points="200,50 150,150 250,150"
              fill="none"
              stroke="#EF4444"
              stroke-width="3"
              filter="url(#trinity-glow)"
              class="animate-pulse"
            />
            <text x="200" y="45" text-anchor="middle" fill="#EF4444" font-size="12" font-weight="bold">
              🔥 TRINITY
            </text>
          <% end %>
        </svg>
      </div>
      
      <!-- Overlay Information -->
      <div class="absolute top-4 left-4 bg-black/50 rounded-lg p-3 text-xs text-white">
        <div>Consciousness: <%= Float.round(@consciousness_level * 100, 1) %>%</div>
        <div>Neurons: <%= length(List.flatten(create_neural_layers())) %></div>
        <div>Trinity: <%= if @trinity_active, do: "🔥 ACTIVE", else: "⭕ DORMANT" %></div>
      </div>
    </div>
    """
  end

  attr :patterns, :list, default: []
  attr :matches, :integer, default: 0
  attr :learning_enabled, :boolean, default: true

  def pattern_flow_visualization(assigns) do
    ~H"""
    <div class="bg-gray-800 rounded-lg p-6 h-80 relative overflow-hidden">
      <h4 class="text-lg font-semibold text-green-300 mb-4">🎯 Pattern Flow</h4>
      
      <!-- Pattern Stream -->
      <div class="absolute inset-0 flex flex-col justify-center items-center">
        <%= for {pattern, idx} <- Enum.with_index(Enum.take(@patterns, 8)) do %>
          <div 
            class="bg-green-500/20 border border-green-500/40 rounded-lg p-2 m-1 text-xs text-green-300 animate-pulse max-w-xs truncate"
            style={"animation-delay: #{idx * 0.2}s;"}
          >
            <%= String.slice(pattern, 0, 40) %><%= if String.length(pattern) > 40, do: "..." %>
          </div>
        <% end %>
      </div>
      
      <!-- Learning Indicator -->
      <div class="absolute bottom-4 right-4">
        <%= if @learning_enabled do %>
          <div class="flex items-center gap-2 text-green-400">
            <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
            <span class="text-sm">Learning Active</span>
          </div>
        <% else %>
          <div class="flex items-center gap-2 text-gray-500">
            <div class="w-3 h-3 bg-gray-500 rounded-full"></div>
            <span class="text-sm">Learning Paused</span>
          </div>
        <% end %>
      </div>
      
      <!-- Match Counter -->
      <div class="absolute top-4 right-4 bg-green-500/20 rounded-lg p-2">
        <div class="text-green-300 text-sm">Matches: <%= @matches %></div>
      </div>
    </div>
    """
  end

  attr :consciousness_level, :float, required: true
  attr :trinity_active, :boolean, default: false
  attr :neural_activity, :float, default: 0.5

  def consciousness_gauge(assigns) do
    ~H"""
    <div class="relative w-32 h-32">
      <!-- Outer Ring -->
      <svg viewBox="0 0 100 100" class="w-full h-full transform -rotate-90">
        <!-- Background Circle -->
        <circle 
          cx="50" 
          cy="50" 
          r="40" 
          fill="none" 
          stroke="#374151" 
          stroke-width="8"
        />
        
        <!-- Consciousness Level Arc -->
        <circle 
          cx="50" 
          cy="50" 
          r="40" 
          fill="none" 
          stroke="#8B5CF6" 
          stroke-width="8" 
          stroke-linecap="round"
          stroke-dasharray={calculate_arc_length(@consciousness_level)}
          class="transition-all duration-1000"
          filter="url(#glow)"
        />
        
        <!-- Trinity Overlay -->
        <%= if @trinity_active do %>
          <circle 
            cx="50" 
            cy="50" 
            r="30" 
            fill="none" 
            stroke="#EF4444" 
            stroke-width="4" 
            stroke-dasharray="10,5"
            class="animate-spin"
            style="animation-duration: 3s;"
          />
        <% end %>
      </svg>
      
      <!-- Center Display -->
      <div class="absolute inset-0 flex items-center justify-center">
        <div class="text-center">
          <div class="text-2xl font-bold text-purple-300">
            <%= Float.round(@consciousness_level * 100, 0) %>%
          </div>
          <%= if @trinity_active do %>
            <div class="text-xs text-red-400 animate-pulse">🔥</div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :activity_data, :list, required: true
  attr :max_history, :integer, default: 50

  def real_time_activity_chart(assigns) do
    ~H"""
    <div class="bg-gray-800 rounded-lg p-4 h-48">
      <h4 class="text-sm font-semibold text-blue-300 mb-2">⚡ Neural Activity</h4>
      
      <div class="relative h-32 overflow-hidden">
        <svg viewBox="0 0 400 100" class="w-full h-full">
          <!-- Grid Lines -->
          <%= for y <- [25, 50, 75] do %>
            <line x1="0" y1={y} x2="400" y2={y} stroke="#374151" stroke-width="0.5" opacity="0.5"/>
          <% end %>
          
          <!-- Activity Line -->
          <polyline 
            points={generate_activity_points(@activity_data)}
            fill="none" 
            stroke="#3B82F6" 
            stroke-width="2"
            class="animate-pulse"
          />
          
          <!-- Activity Fill -->
          <polygon 
            points={"0,100 #{generate_activity_points(@activity_data)} 400,100"}
            fill="url(#activity-gradient)" 
            opacity="0.3"
          />
          
          <!-- Gradient Definition -->
          <defs>
            <linearGradient id="activity-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" style="stop-color:#3B82F6;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#3B82F6;stop-opacity:0" />
            </linearGradient>
          </defs>
        </svg>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp create_neural_layers do
    [
      # Input Layer
      [
        %{id: 1, x: 50, y: 100, active: true, type: :input, prime: 2},
        %{id: 2, x: 50, y: 150, active: false, type: :input, prime: 3},
        %{id: 3, x: 50, y: 200, active: true, type: :input, prime: 5},
        %{id: 4, x: 50, y: 250, active: false, type: :input, prime: 7},
        %{id: 5, x: 50, y: 300, active: true, type: :input, prime: 11}
      ],
      # Hidden Layer 1
      [
        %{id: 6, x: 150, y: 125, active: true, type: :hidden, prime: 13},
        %{id: 7, x: 150, y: 175, active: true, type: :hidden, prime: 17},
        %{id: 8, x: 150, y: 225, active: false, type: :hidden, prime: 19},
        %{id: 9, x: 150, y: 275, active: true, type: :hidden, prime: 23}
      ],
      # Hidden Layer 2
      [
        %{id: 10, x: 250, y: 150, active: true, type: :hidden, prime: 29},
        %{id: 11, x: 250, y: 200, active: true, type: :hidden, prime: 31},
        %{id: 12, x: 250, y: 250, active: false, type: :hidden, prime: 37}
      ],
      # Output Layer
      [
        %{id: 13, x: 350, y: 175, active: true, type: :output, prime: 41},
        %{id: 14, x: 350, y: 225, active: true, type: :output, prime: 43}
      ]
    ]
  end

  defp calculate_neuron_size(neuron, consciousness_level) do
    base_size = 6
    activity_bonus = if neuron.active, do: 3, else: 0
    consciousness_bonus = consciousness_level * 4
    base_size + activity_bonus + consciousness_bonus
  end

  defp get_neuron_color(neuron, trinity_active) do
    cond do
      is_trinity_neuron?(neuron) && trinity_active -> "#EF4444"  # Red for Trinity
      neuron.active -> "#10B981"  # Green for active
      neuron.type == :input -> "#3B82F6"  # Blue for input
      neuron.type == :output -> "#8B5CF6"  # Purple for output
      true -> "#6B7280"  # Gray for inactive
    end
  end

  defp get_neuron_animation_class(neuron, consciousness_level) do
    cond do
      neuron.active && consciousness_level > 0.8 -> "animate-ping"
      neuron.active -> "animate-pulse"
      true -> ""
    end
  end

  defp is_trinity_neuron?(neuron) do
    neuron.prime in [2, 3, 5, 17, 67, 71]
  end

  defp calculate_connection_strength(consciousness_level) do
    max(1, consciousness_level * 3)
  end

  defp calculate_arc_length(level) do
    circumference = 2 * 3.14159 * 40  # radius = 40
    arc_length = circumference * level
    remaining = circumference - arc_length
    "#{arc_length},#{remaining}"
  end

  defp generate_activity_points(data) do
    data
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      x = (index / max(length(data) - 1, 1)) * 400
      y = 100 - (value * 80)  # Invert Y and scale
      "#{x},#{y}"
    end)
    |> Enum.join(" ")
  end
end