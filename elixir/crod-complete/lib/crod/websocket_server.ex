defmodule Crod.WebSocketServer do
  @moduledoc """
  WebSocket server for real-time CROD communication.
  Listens on port 8888.
  """
  use GenServer
  require Logger

  @port 8888

  def start_link(brain_pid) do
    GenServer.start_link(__MODULE__, brain_pid, name: __MODULE__)
  end

  def broadcast(message) do
    GenServer.cast(__MODULE__, {:broadcast, message})
  end

  @impl true
  def init(brain_pid) do
    # For now, we'll use Phoenix Channels instead of raw WebSocket
    # This integrates better with LiveView
    Logger.info("🔌 WebSocket server initialized (using Phoenix Channels)")

    {:ok, %{brain_pid: brain_pid, clients: []}}
  end

  @impl true
  def handle_cast({:broadcast, message}, state) do
    # Broadcast via Phoenix PubSub
    CrodWeb.Endpoint.broadcast("brain:updates", "new_state", message)
    # Mangel: Keine Validierung der Nachricht und kein Error-Handling
    # Verbesserung: Validierung und Fehlerbehandlung ergänzen
    {:noreply, state}
  end

  @impl true
  def handle_info({:broadcast, message}, state) do
    # Forward broadcasts from Brain
    CrodWeb.Endpoint.broadcast("brain:updates", "new_state", message)
    # Mangel: Keine Validierung der Nachricht und kein Error-Handling
    {:noreply, state}
  end
end
