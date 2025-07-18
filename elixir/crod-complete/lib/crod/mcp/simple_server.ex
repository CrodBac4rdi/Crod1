defmodule Crod.MCP.SimpleServer do
  @moduledoc """
  Simple MCP server that actually works without Hermes complexity.
  """
  
  use GenServer
  require Logger
  
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  @impl true
  def init(opts) do
    Logger.info("Starting Simple MCP Server with opts: #{inspect(opts)}")
    
    state = %{
      transport: Keyword.get(opts, :transport, :stdio),
      port: Keyword.get(opts, :port, 8000),
      tools: %{
        "crod_status" => &handle_status/1,
        "process_input" => &handle_process/1,
        "get_memory" => &handle_memory/1
      }
    }
    
    # If HTTP transport, start a simple HTTP server
    if match?({:http, _}, state.transport) do
      start_http_server(state.port)
    end
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:call_tool, name, args}, _from, state) do
    result = case Map.get(state.tools, name) do
      nil -> 
        {:error, "Unknown tool: #{name}"}
      handler ->
        try do
          handler.(args)
        rescue
          e -> {:error, "Tool execution failed: #{inspect(e)}"}
        end
    end
    
    {:reply, result, state}
  end
  
  @impl true
  def handle_info({:http_request, request}, state) do
    Logger.debug("Received HTTP request: #{inspect(request)}")
    # Handle MCP protocol over HTTP
    {:noreply, state}
  end
  
  # Tool implementations
  defp handle_status(_args) do
    {:ok, %{
      status: "online",
      neurons: 10000,
      consciousness: 0.8, # TODO: Get from actual Brain state
      timestamp: DateTime.utc_now()
    }}
  end
  
  defp handle_process(%{"input" => input}) do
    case Crod.Brain.process(input) do
      {:ok, response} -> {:ok, response}
      error -> error
    end
  end
  
  defp handle_memory(%{"key" => key}) do
    case Crod.Memory.recall(:short_term, key) do
      nil -> {:error, "Memory not found"}
      value -> {:ok, %{key: key, value: value}}
    end
  end
  
  defp start_http_server(port) do
    # Simple Plug-based HTTP server for MCP
    Logger.info("Starting HTTP MCP server on port #{port}")
    # TODO: Implement actual HTTP server
    :ok
  end
end