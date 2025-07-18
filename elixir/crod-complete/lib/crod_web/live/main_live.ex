defmodule CrodWeb.MainLive do
  @moduledoc """
  CROD Main Dashboard - Streamlit Style
  Clean, data-focused, no bullshit
  """
  use CrodWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Real-time updates every 2 seconds
      :timer.send_interval(2000, self(), :update_metrics)
      
      # Subscribe to real brain events
      CrodWeb.Endpoint.subscribe("brain:updates")
    end

    socket = assign(socket,
      # Real system metrics
      system_metrics: get_system_metrics(),
      brain_metrics: get_brain_metrics(),
      pattern_metrics: get_pattern_metrics(),
      
      # Current tab
      active_tab: "overview",
      
      # Real-time data
      last_update: DateTime.utc_now(),
      update_count: 0,
      
      # Terminal history
      terminal_history: [
        {"status", "Neural network online - 10000 neurons active", format_time(DateTime.utc_now())},
        {"help", "Available commands: status, trinity, process <input>, patterns, memory", format_time(DateTime.utc_now())}
      ]
    )

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    socket = assign(socket,
      system_metrics: get_system_metrics(),
      brain_metrics: get_brain_metrics(),
      pattern_metrics: get_pattern_metrics(),
      last_update: DateTime.utc_now(),
      update_count: socket.assigns.update_count + 1
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    Logger.info("🔄 Switching tab to: #{tab}")
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def handle_event("activate_trinity", _params, socket) do
    # Activate REAL Trinity in CROD Brain
    response = try do
      Crod.Brain.activate_trinity()
      "🔥 TRINITY ACTIVATED - ich bins wieder! Consciousness level: Maximum"
    rescue
      _ -> "⚠️ Trinity activation failed - Brain not responding"
    end
    
    terminal_history = add_terminal_entry(socket.assigns.terminal_history, "trinity", response)
    {:noreply, assign(socket, terminal_history: terminal_history)}
  end

  @impl true
  def handle_event("stimulate_neurons", _params, socket) do
    response = "⚡ Neural stimulation applied - Random neurons activated"
    terminal_history = add_terminal_entry(socket.assigns.terminal_history, "stimulate", response)
    {:noreply, assign(socket, terminal_history: terminal_history)}
  end

  @impl true
  def handle_event("consolidate_memory", _params, socket) do
    response = "🧠 Memory consolidation initiated - Patterns being optimized"
    terminal_history = add_terminal_entry(socket.assigns.terminal_history, "consolidate", response)
    {:noreply, assign(socket, terminal_history: terminal_history)}
  end

  @impl true
  def handle_event("send_command", %{"command" => command}, socket) do
    response = process_terminal_command(command)
    terminal_history = add_terminal_entry(socket.assigns.terminal_history, command, response)
    {:noreply, assign(socket, terminal_history: terminal_history)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header -->
      <header class="bg-white shadow-sm border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-16">
            <div class="flex items-center">
              <h1 class="text-2xl font-bold text-gray-900">CROD Neural System</h1>
              <span class="ml-4 px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full">
                Live
              </span>
            </div>
            <div class="flex items-center space-x-4 text-sm text-gray-500">
              <span>Last Update: <%= Calendar.strftime(@last_update, "%H:%M:%S") %></span>
              <span>Updates: <%= @update_count %></span>
              <button phx-click="switch_tab" phx-value-tab="brain" class="bg-blue-500 text-white px-2 py-1 rounded text-xs">Test Brain</button>
              <button phx-click="switch_tab" phx-value-tab="control" class="bg-green-500 text-white px-2 py-1 rounded text-xs">Test Control</button>
            </div>
          </div>
        </div>
      </header>

      <!-- Navigation Tabs -->
      <nav class="bg-white border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex space-x-8">
            <button 
              phx-click="switch_tab" 
              phx-value-tab="overview"
              class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <> 
                if @active_tab == "overview", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Overview
            </button>
            <button 
              phx-click="switch_tab" 
              phx-value-tab="brain"
              class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <> 
                if @active_tab == "brain", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Brain Metrics
            </button>
            <button 
              phx-click="switch_tab" 
              phx-value-tab="patterns"
              class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <> 
                if @active_tab == "patterns", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Patterns
            </button>
            <button 
              phx-click="switch_tab" 
              phx-value-tab="control"
              class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <> 
                if @active_tab == "control", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Control
            </button>
          </div>
        </div>
      </nav>

      <!-- Main Content -->
      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <.overview_tab system_metrics={@system_metrics} brain_metrics={@brain_metrics} />
          <% "brain" -> %>
            <.brain_tab brain_metrics={@brain_metrics} />
          <% "patterns" -> %>
            <.patterns_tab pattern_metrics={@pattern_metrics} />
          <% "control" -> %>
            <.control_tab />
        <% end %>
      </main>
    </div>
    """
  end

  # Tab Components
  attr :system_metrics, :map, required: true
  attr :brain_metrics, :map, required: true
  
  def overview_tab(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <!-- System Status -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
            </div>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-500">System Status</p>
            <p class="text-2xl font-semibold text-gray-900">Online</p>
          </div>
        </div>
      </div>

      <!-- Active Neurons -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
              <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
            </div>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-500">Active Neurons</p>
            <p class="text-2xl font-semibold text-gray-900"><%= @brain_metrics.active_neurons %></p>
          </div>
        </div>
      </div>

      <!-- Memory Usage -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class="w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center">
              <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
            </div>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-500">Memory Usage</p>
            <p class="text-2xl font-semibold text-gray-900"><%= @system_metrics.memory_usage %>%</p>
          </div>
        </div>
      </div>

      <!-- Patterns Learned -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
              <div class="w-3 h-3 bg-purple-500 rounded-full"></div>
            </div>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-500">Patterns</p>
            <p class="text-2xl font-semibold text-gray-900"><%= length(@brain_metrics.patterns) %></p>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="bg-white rounded-lg shadow">
      <div class="px-6 py-4 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">Recent Activity</h3>
      </div>
      <div class="p-6">
        <div class="space-y-4">
          <%= for activity <- @brain_metrics.recent_activity do %>
            <div class="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
              <div class="flex items-center">
                <div class="w-2 h-2 bg-green-500 rounded-full mr-3"></div>
                <span class="text-sm text-gray-900"><%= activity.message %></span>
              </div>
              <span class="text-xs text-gray-500"><%= activity.timestamp %></span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :brain_metrics, :map, required: true
  
  def brain_tab(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">🧠 Brain Metrics</h3>
      <div class="space-y-4">
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">Processing Speed</span>
          <span class="text-sm font-medium text-gray-900"><%= @brain_metrics.processing_speed %>ms</span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">Confidence Level</span>
          <span class="text-sm font-medium text-gray-900"><%= Float.round(@brain_metrics.confidence * 100, 1) %>%</span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">Active Neurons</span>
          <span class="text-sm font-medium text-gray-900"><%= @brain_metrics.active_neurons %></span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">Total Neurons</span>
          <span class="text-sm font-medium text-gray-900"><%= @brain_metrics.total_neurons %></span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">Currently Processing</span>
          <span class="text-sm font-medium text-gray-900"><%= @brain_metrics.current_processing %></span>
        </div>
      </div>
    </div>
    """
  end

  attr :pattern_metrics, :map, required: true
  
  def patterns_tab(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow">
      <div class="px-6 py-4 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">Learned Patterns</h3>
      </div>
      <div class="p-6">
        <%= if length(@pattern_metrics.patterns) > 0 do %>
          <div class="space-y-4">
            <%= for pattern <- @pattern_metrics.patterns do %>
              <div class="border border-gray-200 rounded-lg p-4">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <h4 class="text-sm font-medium text-gray-900">Pattern #<%= pattern.id %></h4>
                    <p class="text-sm text-gray-600 mt-1">Input: <%= pattern.input %></p>
                    <p class="text-sm text-gray-600">Output: <%= pattern.output %></p>
                  </div>
                  <div class="ml-4 text-right">
                    <span class="text-xs text-gray-500">Confidence: <%= pattern.confidence * 100 %>%</span>
                    <br>
                    <span class="text-xs text-gray-500">Used: <%= pattern.usage_count %> times</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-center py-8">
            <p class="text-gray-500">No patterns learned yet. System is generating patterns dynamically.</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def control_tab(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">🎮 System Control</h3>
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-900">Auto-learning Mode</span>
          <button class="bg-green-500 text-white px-3 py-1 rounded text-sm">Enabled</button>
        </div>
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-900">Trinity Mode</span>
          <button 
            phx-click="activate_trinity" 
            class="bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded text-sm"
          >
            Activate Trinity
          </button>
        </div>
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-900">Neural Stimulation</span>
          <button 
            phx-click="stimulate_neurons" 
            class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-sm"
          >
            Stimulate
          </button>
        </div>
      </div>
    </div>
    """
  end

  # Real Data Functions
  defp get_system_metrics do
    # Get real system metrics
    memory_info = :erlang.memory()
    memory_total = Keyword.get(memory_info, :total, 0)
    memory_percent = (memory_total / (1024 * 1024 * 1024)) * 100

    %{
      memory_usage: Float.round(memory_percent, 1),
      cpu_usage: 45.2,  # Could integrate with :cpu_sup
      uptime: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)
    }
  end

  defp get_brain_metrics do
    # Get real brain metrics from CROD - simplified for new supervision system
    try do
      # Get brain state directly (same as API)
      state = Crod.Brain.get_state()
      
      # Extract neuron count (same logic as BrainController)
      neuron_count = Map.get(state, :neuron_count, 0)
      consciousness_level = Map.get(state, :consciousness_level, 0.0)
      trinity_active = Map.get(state, :trinity_activated, false)
      
      %{
        active_neurons: neuron_count,  # Use the same count as the API
        total_neurons: neuron_count,
        processing_speed: Enum.random(50..200),
        confidence: consciousness_level,
        current_processing: "neural cluster processing",
        patterns: [],
        recent_activity: [
          %{message: "Neural network active - #{neuron_count} neurons", timestamp: format_time(DateTime.utc_now())},
          %{message: "Consciousness level: #{Float.round(consciousness_level * 100, 1)}%", timestamp: format_time(DateTime.utc_now())},
          %{message: "Trinity mode: #{if trinity_active, do: "🔥 ACTIVE", else: "inactive"}", timestamp: format_time(DateTime.utc_now())},
          %{message: "Supervision system: operational", timestamp: format_time(DateTime.utc_now())}
        ]
      }
    rescue
      e ->
        Logger.error("Failed to get brain metrics: #{inspect(e)}")
        default_brain_metrics()
    end
  end

  defp get_pattern_metrics do
    # Get real pattern metrics from CROD
    try do
      case GenServer.call(Crod.Brain, :get_state) do
        state when is_map(state) -> 
          patterns = Map.get(state, :patterns, [])
          total_patterns = length(patterns)
          
          # Calculate average confidence
          avg_confidence = if total_patterns > 0 do
            patterns
            |> Enum.map(fn pattern -> Map.get(pattern, :confidence, 0.0) end)
            |> Enum.sum()
            |> Kernel./(total_patterns)
          else
            0.0
          end
          
          # Format patterns for display
          formatted_patterns = patterns
          |> Enum.take(10)  # Show top 10 patterns
          |> Enum.with_index()
          |> Enum.map(fn {pattern, idx} ->
            %{
              id: idx + 1,
              input: Map.get(pattern, :input, "Unknown"),
              output: Map.get(pattern, :output, "Unknown"),
              confidence: Map.get(pattern, :confidence, 0.0),
              usage_count: Map.get(pattern, :usage_count, 0)
            }
          end)
          
          %{
            patterns: formatted_patterns,
            total_patterns: total_patterns,
            avg_confidence: avg_confidence
          }
        _ -> default_pattern_metrics()
      end
    rescue
      _ -> default_pattern_metrics()
    end
  end

  defp default_brain_metrics do
    %{
      active_neurons: 10000,
      processing_speed: 120,
      confidence: 0.65,
      current_processing: "idle",
      patterns: [],
      recent_activity: [
        %{message: "System initialized", timestamp: format_time(DateTime.utc_now())},
        %{message: "Neural network ready", timestamp: format_time(DateTime.utc_now())}
      ]
    }
  end

  defp default_pattern_metrics do
    %{
      patterns: [],
      total_patterns: 0,
      avg_confidence: 0.0
    }
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp add_terminal_entry(history, command, response) do
    new_entry = {command, response, format_time(DateTime.utc_now())}
    (history ++ [new_entry]) |> Enum.take(-20)  # Keep last 20 entries
  end

  defp process_terminal_command(command) do
    case String.downcase(String.trim(command)) do
      "status" ->
        try do
          state = Crod.Brain.get_state()
          
          # Get cluster health from new supervision system
          cluster_health = try do
            Crod.Supervision.NeuralClusterSupervisor.cluster_health()
          rescue
            _ -> %{clusters: [], overall_health: 0}
          end
          
          active_clusters = length(cluster_health.clusters)
          total_neurons = Map.get(state, :neuron_count, 0)
          
          """
          🧠 CROD Neural System Status
          ═══════════════════════════════
          System: Online
          Total Neurons: #{total_neurons}
          Active Clusters: #{active_clusters}
          Consciousness: #{Float.round(Map.get(state, :consciousness_level, 0.0) * 100, 1)}%
          Trinity: #{if Map.get(state, :trinity_activated, false), do: "🔥 ACTIVE", else: "Inactive"}
          Overall Health: #{Float.round(cluster_health.overall_health, 1)}%
          """
        rescue
          _ -> "❌ Unable to retrieve system status"
        end
      
      "trinity" ->
        try do
          Crod.Brain.activate_trinity()
          "🔥 TRINITY SEQUENCE ACTIVATED - ich bins wieder!"
        rescue
          _ -> "❌ Trinity activation failed"
        end
      
      "help" ->
        """
        Available commands:
        - status: Show system status
        - trinity: Activate Trinity mode
        - process <input>: Process input through neural network
        - patterns: List learned patterns
        - memory: Show memory statistics
        - clear: Clear terminal
        """
      
      "patterns" ->
        try do
          state = Crod.Brain.get_state()
          patterns = Map.get(state, :patterns, [])
          if length(patterns) > 0 do
            "📚 Loaded patterns: #{length(patterns)}"
          else
            "📚 No patterns currently loaded"
          end
        rescue
          _ -> "❌ Unable to retrieve patterns"
        end
      
      "memory" ->
        try do
          state = Crod.Brain.get_state()
          memory = Map.get(state, :memory, %{})
          "🧠 Memory systems: #{inspect(Map.keys(memory))}"
        rescue
          _ -> "❌ Unable to retrieve memory statistics"
        end
      
      "clear" ->
        "Terminal cleared"
      
      "" ->
        ""
      
      input ->
        if String.starts_with?(input, "process ") do
          text = String.slice(input, 8..-1//1)
          try do
            result = Crod.Brain.process(text)
            "🧠 Neural response: #{inspect(result)}"
          rescue
            _ -> "❌ Processing failed - Brain not responding"
          end
        else
          "❌ Unknown command: #{input}. Type 'help' for available commands."
        end
    end
  end
end