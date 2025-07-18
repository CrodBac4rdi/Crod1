defmodule Crod.MCP.ServerWrapper do
  @moduledoc """
  GenServer wrapper for Hermes MCP servers.
  Provides start_link/1 compatibility for supervision tree.
  """
  
  use GenServer
  require Logger
  
  def start_link(opts) do
    {server_module, opts} = Keyword.pop!(opts, :server_module)
    GenServer.start_link(__MODULE__, {server_module, opts}, name: server_module)
  end
  
  @impl true
  def init({server_module, opts}) do
    Logger.info("Starting MCP server wrapper for #{inspect(server_module)}")
    
    # Start the Hermes server in a supervised way
    case start_hermes_server(server_module, opts) do
      {:ok, pid} ->
        {:ok, %{server_module: server_module, server_pid: pid, opts: opts}}
      
      {:error, reason} ->
        Logger.error("Failed to start #{inspect(server_module)}: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_info({:EXIT, pid, reason}, %{server_pid: pid} = state) do
    Logger.error("MCP server #{inspect(state.server_module)} crashed: #{inspect(reason)}")
    {:stop, {:server_crashed, reason}, state}
  end
  
  def handle_info(msg, state) do
    Logger.debug("ServerWrapper received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  defp start_hermes_server(server_module, opts) do
    transport = Keyword.get(opts, :transport, {:stdio, []})
    
    # Hermes servers need special initialization
    # For now, we'll just track that they should be started
    Logger.info("Would start #{inspect(server_module)} with transport #{inspect(transport)}")
    
    # Return a fake PID for now
    {:ok, self()}
  end
end