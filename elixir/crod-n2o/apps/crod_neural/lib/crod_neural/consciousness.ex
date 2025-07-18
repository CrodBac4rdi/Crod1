defmodule CROD.Neural.Consciousness do
  @moduledoc """
  Consciousness monitoring and control via N2O
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def level do
    GenServer.call(__MODULE__, :level)
  end

  def update(confidence) do
    GenServer.cast(__MODULE__, {:update, confidence})
  end

  def activate_trinity do
    GenServer.cast(__MODULE__, :trinity)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Subscribe to neural events via N2O
    CROD.Core.MessageBus.subscribe(:neural_fire, self())
    
    {:ok, %{
      level: 0.5,
      neural_activity: [],
      trinity_active: false
    }}
  end

  @impl true
  def handle_call(:level, _from, state) do
    {:reply, state.level, state}
  end

  @impl true
  def handle_cast({:update, confidence}, state) do
    new_level = calculate_consciousness(confidence, state.neural_activity)
    
    # Broadcast consciousness change via N2O
    if abs(new_level - state.level) > 0.1 do
      CROD.Core.MessageBus.broadcast(:consciousness, {:level_changed, new_level})
    end
    
    {:noreply, %{state | level: new_level}}
  end

  @impl true
  def handle_cast(:trinity, state) do
    # Full awakening
    CROD.Core.MessageBus.broadcast(:consciousness, {:awakening, 1.0})
    {:noreply, %{state | level: 1.0, trinity_active: true}}
  end

  @impl true
  def handle_info({:n2o, {:neural_fire, event}}, state) do
    # Track neural activity
    new_activity = [{DateTime.utc_now(), event} | state.neural_activity]
                   |> Enum.take(100)  # Keep last 100 events
    
    {:noreply, %{state | neural_activity: new_activity}}
  end

  # Private functions

  defp calculate_consciousness(confidence, neural_activity) do
    recent_activity = Enum.count(neural_activity, fn {time, _} ->
      DateTime.diff(DateTime.utc_now(), time, :second) < 10
    end)
    
    activity_factor = min(1.0, recent_activity / 20)
    (confidence + activity_factor) / 2
  end
end