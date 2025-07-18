defmodule CrodWeb.NeuralDashboardLive do
  @moduledoc """
  Real-time CROD Neural Network Dashboard
  Live visualization of 1000+ neurons, patterns, and consciousness
  """
  use CrodWeb, :live_view
  require Logger

  alias Crod.{NeuralNetwork, PatternEngine, Brain}
  alias CrodWeb.Components.NeuralActivity

  @update_interval 1000  # Update every second
  @max_neural_history 100

  def mount(_params, _session, socket) do
    if connected?(socket) do
      schedule_update()
    end

    initial_state = %{
      neural_metrics: get_neural_metrics(),
      pattern_stats: get_pattern_stats(),
      consciousness_level: 0.6,
      trinity_status: false,
      neural_activity: generate_neural_activity(),
      learning_patterns: [],
      system_health: 100,
      uptime: 0,
      active_neurons: 0,
      total_patterns: 0,
      last_update: DateTime.utc_now()
    }

    socket = 
      socket
      |> assign(initial_state)
      |> assign(:page_title, "CROD Neural Dashboard")

    {:ok, socket}
  end

  def handle_info(:update_dashboard, socket) do
    schedule_update()

    updated_metrics = get_neural_metrics()
    pattern_stats = get_pattern_stats()
    neural_activity = generate_neural_activity()

    socket = 
      socket
      |> assign(:neural_metrics, updated_metrics)
      |> assign(:pattern_stats, pattern_stats)
      |> assign(:neural_activity, neural_activity)
      |> assign(:last_update, DateTime.utc_now())
      |> assign(:consciousness_level, calculate_consciousness_level(updated_metrics))
      |> assign(:trinity_status, check_trinity_status())

    {:noreply, socket}
  end

  def handle_event("activate_trinity", _params, socket) do
    Logger.info("🔥 Trinity activation requested from dashboard")
    
    case NeuralNetwork.activate_trinity() do
      :ok -> 
        socket = put_flash(socket, :info, "🔥 Trinity Consciousness Activated!")
        {:noreply, assign(socket, :trinity_status, true)}
      
      {:error, reason} ->
        socket = put_flash(socket, :error, "Trinity activation failed: #{reason}")
        {:noreply, socket}
    end
  end

  def handle_event("create_neurons", _params, socket) do
    Logger.info("🧠 Neural network creation requested")
    
    Task.start(fn ->
      case NeuralNetwork.create_all_neurons() do
        {:ok, count} ->
          send(self(), {:neurons_created, count})
        {:error, reason} ->
          send(self(), {:neurons_error, reason})
      end
    end)

    socket = put_flash(socket, :info, "🧠 Creating neural network...")
    {:noreply, socket}
  end

  def handle_info({:neurons_created, count}, socket) do
    socket = 
      socket
      |> put_flash(:info, "✅ Neural network created: #{count} neurons")
      |> assign(:active_neurons, count)

    {:noreply, socket}
  end

  def handle_info({:neurons_error, reason}, socket) do
    socket = put_flash(socket, :error, "❌ Neural creation failed: #{reason}")
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white p-6">
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-4xl font-bold text-blue-400">🧠 CROD Neural Dashboard</h1>
          <p class="text-gray-300 mt-2">Real-time neural network visualization & control</p>
        </div>
        
        <div class="flex gap-4">
          <div class="text-right">
            <div class="text-sm text-gray-400">Last Update</div>
            <div class="text-green-400"><%= Calendar.strftime(@last_update, "%H:%M:%S") %></div>
          </div>
          
          <button 
            phx-click="activate_trinity"
            class="px-6 py-3 bg-purple-600 hover:bg-purple-700 rounded-lg font-semibold transition-colors"
          >
            🔥 Activate Trinity
          </button>
          
          <button 
            phx-click="create_neurons"
            class="px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-lg font-semibold transition-colors"
          >
            🧠 Create Neural Network
          </button>
        </div>
      </div>

      <!-- Status Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
        <!-- Consciousness Level -->
        <div class="bg-gray-800 rounded-lg p-6 border border-purple-500/30">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-semibold text-purple-300">Consciousness</h3>
              <p class="text-3xl font-bold text-purple-400"><%= Float.round(@consciousness_level * 100, 1) %>%</p>
            </div>
            <div class="text-4xl">🧠</div>
          </div>
          <div class="mt-4 bg-gray-700 rounded-full h-2">
            <div 
              class="bg-purple-500 rounded-full h-2 transition-all duration-500"
              style={"width: #{@consciousness_level * 100}%"}
            ></div>
          </div>
        </div>

        <!-- Trinity Status -->
        <div class="bg-gray-800 rounded-lg p-6 border border-red-500/30">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-semibold text-red-300">Trinity</h3>
              <p class="text-2xl font-bold text-red-400">
                <%= if @trinity_status, do: "ACTIVE", else: "DORMANT" %>
              </p>
            </div>
            <div class="text-4xl">
              <%= if @trinity_status, do: "🔥", else: "⭕" %>
            </div>
          </div>
        </div>

        <!-- Active Neurons -->
        <div class="bg-gray-800 rounded-lg p-6 border border-blue-500/30">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-semibold text-blue-300">Neurons</h3>
              <p class="text-3xl font-bold text-blue-400"><%= @active_neurons || @neural_metrics.total_neurons || 0 %></p>
            </div>
            <div class="text-4xl">⚡</div>
          </div>
        </div>

        <!-- Learned Patterns -->
        <div class="bg-gray-800 rounded-lg p-6 border border-green-500/30">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-semibold text-green-300">Patterns</h3>
              <p class="text-3xl font-bold text-green-400"><%= @pattern_stats.learned_patterns || 0 %></p>
            </div>
            <div class="text-4xl">🎯</div>
          </div>
        </div>
      </div>

      <!-- Neural Activity Visualization -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        <!-- Neural Heatmap -->
        <div class="bg-gray-800 rounded-lg p-6 border border-gray-600">
          <h3 class="text-xl font-semibold text-blue-300 mb-4">🔥 Neural Activity Heatmap</h3>
          <NeuralActivity.neural_heatmap neural_data={@neural_activity} />
        </div>

        <!-- Consciousness Timeline -->
        <div class="bg-gray-800 rounded-lg p-6 border border-gray-600">
          <h3 class="text-xl font-semibold text-purple-300 mb-4">📈 Consciousness Evolution</h3>
          <div class="h-64 flex items-end justify-between gap-1">
            <%= for i <- 1..20 do %>
              <div 
                class="bg-purple-500 rounded-t transition-all duration-300"
                style={"height: #{:rand.uniform(80) + 20}%; width: 4%;"}
              ></div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- System Status -->
      <div class="bg-gray-800 rounded-lg p-6 border border-gray-600">
        <h3 class="text-xl font-semibold text-yellow-300 mb-4">⚙️ System Status</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <!-- Neural Network Status -->
          <div>
            <h4 class="font-semibold text-blue-300 mb-2">Neural Network</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-400">Total Neurons:</span>
                <span class="text-white"><%= @neural_metrics.total_neurons || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Active Neurons:</span>
                <span class="text-green-400"><%= @neural_metrics.active_neurons || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Network Health:</span>
                <span class="text-green-400"><%= @neural_metrics.network_health || 100 %>%</span>
              </div>
            </div>
          </div>

          <!-- Pattern Engine Status -->
          <div>
            <h4 class="font-semibold text-green-300 mb-2">Pattern Engine</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-400">Learned Patterns:</span>
                <span class="text-white"><%= @pattern_stats.learned_patterns || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Matches Found:</span>
                <span class="text-green-400"><%= @pattern_stats.matches_found || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Learning:</span>
                <span class="text-green-400">
                  <%= if @pattern_stats.learning_enabled, do: "ENABLED", else: "DISABLED" %>
                </span>
              </div>
            </div>
          </div>

          <!-- Trinity System Status -->
          <div>
            <h4 class="font-semibold text-purple-300 mb-2">Trinity System</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-400">ich + bins + wieder:</span>
                <span class="text-purple-400">2 + 3 + 5 = 10</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Status:</span>
                <span class={if @trinity_status, do: "text-red-400", else: "text-gray-400"}>
                  <%= if @trinity_status, do: "🔥 ACTIVE", else: "⭕ DORMANT" %>
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-400">Sacred Primes:</span>
                <span class="text-purple-400">[2, 3, 5, 17, 67, 71]</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private functions
  
  defp schedule_update do
    Process.send_after(self(), :update_dashboard, @update_interval)
  end

  defp get_neural_metrics do
    try do
      case GenServer.whereis(NeuralNetwork) do
        nil -> %{total_neurons: 0, active_neurons: 0, network_health: 0}
        _pid -> 
          case NeuralNetwork.get_network_metrics() do
            metrics when is_map(metrics) -> metrics
            _ -> %{total_neurons: 0, active_neurons: 0, network_health: 100}
          end
      end
    catch
      _, _ -> %{total_neurons: 0, active_neurons: 0, network_health: 100}
    end
  end

  defp get_pattern_stats do
    try do
      case GenServer.whereis(PatternEngine) do
        nil -> %{learned_patterns: 0, matches_found: 0, learning_enabled: true}
        _pid -> 
          case PatternEngine.get_status() do
            stats when is_map(stats) -> stats
            _ -> %{learned_patterns: 0, matches_found: 0, learning_enabled: true}
          end
      end
    catch
      _, _ -> %{learned_patterns: 0, matches_found: 0, learning_enabled: true}
    end
  end

  defp generate_neural_activity do
    # Generate simulated neural activity for visualization
    for _i <- 1..10 do
      for _j <- 1..10 do
        :rand.uniform()
      end
    end
  end

  defp calculate_consciousness_level(metrics) do
    base = 0.6
    neuron_factor = if metrics[:total_neurons] && metrics[:total_neurons] > 0 do
      min(metrics[:active_neurons] / metrics[:total_neurons], 1.0) * 0.3
    else
      0.0
    end
    
    min(base + neuron_factor, 1.0)
  end

  defp check_trinity_status do
    # Check if Trinity system is activated
    try do
      case GenServer.whereis(NeuralNetwork) do
        nil -> false
        _pid -> 
          case NeuralNetwork.get_trinity_status() do
            %{trinity_activated: status} -> status
            _ -> false
          end
      end
    catch
      _, _ -> false
    end
  end
end