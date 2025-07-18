defmodule CrodWeb.Components.NeuralCharts do
  @moduledoc """
  Neural Network Data Visualization Components
  Using proper charting libraries for Streamlit-like visualizations
  """
  use Phoenix.Component
  use CrodWeb, :verified_routes

  @doc """
  Real-time neural activity chart using Chart.js
  """
  def neural_activity_chart(assigns) do
    ~H"""
    <div class="crod-card">
      <h3 class="crod-subtitle mb-4">Neural Activity Over Time</h3>
      <div class="h-64 w-full">
        <canvas 
          id="neural-activity-chart" 
          phx-hook="NeuralActivityChart"
          data-neurons={@neurons}
          data-activity={@activity_data}
          class="w-full h-full"
        ></canvas>
      </div>
    </div>
    """
  end

  @doc """
  Neural network topology visualization using D3.js
  """
  def neural_network_topology(assigns) do
    ~H"""
    <div class="crod-card">
      <h3 class="crod-subtitle mb-4">Neural Network Topology</h3>
      <div class="h-96 w-full">
        <div 
          id="neural-topology" 
          phx-hook="NeuralTopology"
          data-nodes={@nodes}
          data-connections={@connections}
          class="w-full h-full bg-crod-darker rounded-lg"
        ></div>
      </div>
    </div>
    """
  end

  @doc """
  Memory usage visualization with interactive pie chart
  """
  def memory_usage_chart(assigns) do
    ~H"""
    <div class="crod-card">
      <h3 class="crod-subtitle mb-4">Memory Distribution</h3>
      <div class="h-64 w-full">
        <canvas 
          id="memory-chart" 
          phx-hook="MemoryChart"
          data-short-term={@memory_stats.short_term}
          data-working={@memory_stats.working}
          data-long-term={@memory_stats.long_term}
          class="w-full h-full"
        ></canvas>
      </div>
    </div>
    """
  end

  @doc """
  Pattern confidence heatmap using ECharts
  """
  def pattern_confidence_heatmap(assigns) do
    ~H"""
    <div class="crod-card">
      <h3 class="crod-subtitle mb-4">Pattern Confidence Heatmap</h3>
      <div class="h-80 w-full">
        <div 
          id="pattern-heatmap" 
          phx-hook="PatternHeatmap"
          data-patterns={@patterns}
          class="w-full h-full"
        ></div>
      </div>
    </div>
    """
  end

  @doc """
  System performance metrics dashboard
  """
  def performance_dashboard(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-6">
      <!-- CPU Usage Gauge -->
      <div class="crod-card">
        <h4 class="crod-subtitle mb-4">CPU Usage</h4>
        <div class="h-48 w-full">
          <canvas 
            id="cpu-gauge" 
            phx-hook="CPUGauge"
            data-usage={@system_metrics.cpu_usage}
            class="w-full h-full"
          ></canvas>
        </div>
      </div>

      <!-- Memory Usage Gauge -->
      <div class="crod-card">
        <h4 class="crod-subtitle mb-4">Memory Usage</h4>
        <div class="h-48 w-full">
          <canvas 
            id="memory-gauge" 
            phx-hook="MemoryGauge"
            data-usage={@system_metrics.memory_usage}
            class="w-full h-full"
          ></canvas>
        </div>
      </div>

      <!-- Network I/O Chart -->
      <div class="crod-card col-span-2">
        <h4 class="crod-subtitle mb-4">Network I/O</h4>
        <div class="h-48 w-full">
          <canvas 
            id="network-chart" 
            phx-hook="NetworkChart"
            data-in={@system_metrics.network_in}
            data-out={@system_metrics.network_out}
            class="w-full h-full"
          ></canvas>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Interactive neural grid with proper visualization
  """
  def interactive_neural_grid(assigns) do
    ~H"""
    <div class="crod-card">
      <div class="flex items-center justify-between mb-4">
        <h3 class="crod-subtitle">Neural Grid (10,000 Neurons)</h3>
        <div class="flex space-x-2">
          <button class="crod-btn-secondary" phx-click="zoom_in">Zoom In</button>
          <button class="crod-btn-secondary" phx-click="zoom_out">Zoom Out</button>
          <button class="crod-btn-secondary" phx-click="reset_view">Reset</button>
        </div>
      </div>
      
      <div class="h-96 w-full overflow-hidden">
        <div 
          id="neural-grid-canvas" 
          phx-hook="NeuralGridCanvas"
          data-neurons={@neurons}
          data-zoom={@zoom_level}
          class="w-full h-full bg-crod-darker rounded-lg cursor-crosshair"
        ></div>
      </div>
      
      <!-- Legend -->
      <div class="mt-4 flex items-center justify-center space-x-6 text-sm">
        <div class="flex items-center space-x-2">
          <div class="w-4 h-4 bg-neural-active rounded"></div>
          <span class="crod-text">High Activity</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-4 h-4 bg-neural-high rounded"></div>
          <span class="crod-text">Medium Activity</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-4 h-4 bg-neural-mid rounded"></div>
          <span class="crod-text">Low Activity</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-4 h-4 bg-neural-low rounded"></div>
          <span class="crod-text">Inactive</span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Consciousness level visualization with animated circles
  """
  def consciousness_visualization(assigns) do
    ~H"""
    <div class="crod-card text-center">
      <h3 class="crod-subtitle mb-6">Consciousness Level</h3>
      <div class="relative w-48 h-48 mx-auto">
        <div 
          id="consciousness-viz" 
          phx-hook="ConsciousnessViz"
          data-level={@consciousness_level}
          data-trinity={@trinity_active}
          class="w-full h-full"
        ></div>
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="text-center">
            <div class="text-4xl font-bold text-white mb-2">
              <%= Float.round(@consciousness_level * 100, 0) %>%
            </div>
            <div class="text-sm text-crod-blue-accent">
              <%= if @trinity_active, do: "Trinity Active", else: "Active" %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end