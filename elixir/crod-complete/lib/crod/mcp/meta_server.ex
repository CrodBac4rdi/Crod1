defmodule Crod.MCP.MetaServer do
  @moduledoc """
  Meta MCP Server that routes requests to specialized MCP servers.
  Acts as a single entry point for Claude while delegating to domain-specific servers.
  """
  
  use Hermes.Server
  require Logger
  
  @impl true
  def server_info do
    %{
      name: "CROD-Meta",
      version: "1.0.0",
      description: "Meta MCP server routing to specialized CROD services"
    }
  end
  
  @impl true
  def capabilities do
    %{
      roots: true,
      sampling: true
    }
  end
  
  @impl true
  def list_tools(_state) do
    # Aggregate tools from all sub-servers
    pattern_tools = Crod.MCP.PatternServer.list_tools(%{})
    memory_tools = Crod.MCP.MemoryServer.list_tools(%{})
    neural_tools = Crod.MCP.NeuralServer.list_tools(%{})
    trinity_tools = Crod.MCP.TrinityServer.list_tools(%{})
    
    # Meta tools for server management
    meta_tools = [
      %{
        name: "meta_server_status",
        description: "Get status of all MCP servers",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      },
      %{
        name: "meta_server_select",
        description: "Select specific server for direct interaction",
        inputSchema: %{
          type: "object",
          properties: %{
            server: %{
              type: "string",
              enum: ["pattern", "memory", "neural", "trinity"],
              description: "Server to select"
            }
          },
          required: ["server"]
        }
      }
    ]
    
    # Combine all tools
    meta_tools ++ pattern_tools ++ memory_tools ++ neural_tools ++ trinity_tools
  end
  
  @impl true
  def call_tool(name, args, state) do
    Logger.info("Meta-server routing tool: #{name}")
    
    # Route based on tool prefix or type
    cond do
      String.starts_with?(name, "meta_") ->
        handle_meta_tool(name, args, state)
        
      String.starts_with?(name, "pattern_") ->
        Crod.MCP.PatternServer.call_tool(name, args, state)
        
      String.starts_with?(name, "memory_") ->
        Crod.MCP.MemoryServer.call_tool(name, args, state)
        
      String.starts_with?(name, "neural_") ->
        Crod.MCP.NeuralServer.call_tool(name, args, state)
        
      String.starts_with?(name, "trinity_") ->
        Crod.MCP.TrinityServer.call_tool(name, args, state)
        
      # Fallback to unified handler for backward compatibility
      true ->
        Crod.MCP.HermesClient.handle_tool_call(name, args)
    end
  end
  
  @impl true
  def list_resources(_state) do
    # Aggregate resources from all servers
    []
  end
  
  @impl true
  def read_resource(_uri, _state) do
    {:error, "Resource not found"}
  end
  
  # Meta tool handlers
  
  defp handle_meta_tool("meta_server_status", _args, _state) do
    servers = [
      check_server_status("Pattern Server", Crod.MCP.PatternServer),
      check_server_status("Memory Server", Crod.MCP.MemoryServer),
      check_server_status("Neural Server", Crod.MCP.NeuralServer),
      check_server_status("Trinity Server", Crod.MCP.TrinityServer)
    ]
    
    {:ok, %{
      status: "ACTIVE",
      servers: servers,
      routing_mode: "automatic",
      timestamp: DateTime.utc_now()
    }}
  end
  
  defp handle_meta_tool("meta_server_select", %{"server" => server}, state) do
    case server do
      "pattern" -> {:ok, %{selected: "PatternServer", port: 8001}}
      "memory" -> {:ok, %{selected: "MemoryServer", port: 8002}}
      "neural" -> {:ok, %{selected: "NeuralServer", port: 8003}}
      "trinity" -> {:ok, %{selected: "TrinityServer", port: 8004}}
      _ -> {:error, "Unknown server: #{server}"}
    end
  end
  
  defp check_server_status(name, module) do
    case Process.whereis(module) do
      nil -> %{name: name, status: "offline", pid: nil}
      pid -> %{name: name, status: "online", pid: inspect(pid)}
    end
  end
end