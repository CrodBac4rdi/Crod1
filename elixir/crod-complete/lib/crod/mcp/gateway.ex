defmodule Crod.MCP.Gateway do
  @moduledoc """
  MCP Gateway Router - Single entry point that routes to specialized servers
  Based on mcp-server-swarm-architecture-elixir.md
  """
  
  use Hermes.Server
  require Logger
  
  @impl true
  def server_info do
    %{
      name: "CROD-Gateway",
      version: "1.0.0",
      description: "MCP Gateway Router - Routes to specialized CROD servers"
    }
  end
  
  @impl true
  def server_capabilities do
    %{
      tools: true,
      resources: true,
      prompts: false,
      logging: true
    }
  end
  
  @impl true
  def init(transport, _options) do
    Logger.info("🚀 CROD Gateway Router started")
    
    # Server mapping configuration
    state = %{
      transport: transport,
      servers: %{
        neural: System.get_env("NEURAL_SERVER", "http://mcp-neural:3001"),
        git: System.get_env("GIT_SERVER", "http://mcp-git:3002"),
        memory: System.get_env("MEMORY_SERVER", "http://mcp-memory:3003"),
        canvas: System.get_env("CANVAS_SERVER", "http://mcp-canvas:3004"),
        database: System.get_env("DATABASE_SERVER", "http://mcp-database:3005")
      },
      health_checks: %{},
      routing_stats: %{}
    }
    
    # Start health check timer
    Process.send_after(self(), :health_check, 30_000)
    
    {:ok, state}
  end
  
  @impl true
  def handle_request(%{"method" => "tools/list"} = _request, state) do
    # Aggregate all tools from all servers
    tools = aggregate_all_tools(state)
    
    {:ok, %{
      tools: tools
    }, state}
  end
  
  @impl true
  def handle_request(%{"method" => "tools/call", "params" => %{"name" => tool_name} = params} = _request, state) do
    Logger.info("🔧 Gateway routing tool: #{tool_name}")
    
    # Route to appropriate server
    case route_tool_request(tool_name, params, state) do
      {:ok, result} ->
        # Update routing stats
        state = update_routing_stats(state, tool_name, :success)
        {:ok, result, state}
        
      {:error, reason} ->
        state = update_routing_stats(state, tool_name, :error)
        {:error, %{
          code: -32000,
          message: "Tool execution failed",
          data: %{tool: tool_name, reason: reason}
        }, state}
    end
  end
  
  @impl true
  def handle_request(%{"method" => "gateway/status"} = _request, state) do
    {:ok, %{
      gateway: "active",
      servers: state.servers,
      health: state.health_checks,
      routing_stats: state.routing_stats,
      timestamp: DateTime.utc_now()
    }, state}
  end
  
  @impl true
  def handle_notification(_notification, state) do
    {:noreply, state}
  end
  
  # Routing logic
  
  defp route_tool_request(tool_name, params, state) do
    case determine_server(tool_name) do
      {:neural, _} ->
        forward_to_server(state.servers.neural, tool_name, params)
        
      {:git, _} ->
        forward_to_server(state.servers.git, tool_name, params)
        
      {:memory, _} ->
        forward_to_server(state.servers.memory, tool_name, params)
        
      {:canvas, _} ->
        forward_to_server(state.servers.canvas, tool_name, params)
        
      {:database, _} ->
        forward_to_server(state.servers.database, tool_name, params)
        
      {:unknown, _} ->
        {:error, "Unknown tool category: #{tool_name}"}
    end
  end
  
  defp determine_server(tool_name) do
    cond do
      # CROD Neural tools
      String.starts_with?(tool_name, "crod_") or 
      String.starts_with?(tool_name, "neural_") or
      String.starts_with?(tool_name, "trinity_") ->
        {:neural, :neural}
        
      # Git tools
      String.starts_with?(tool_name, "git_") ->
        {:git, :git}
        
      # Memory/Cache tools
      String.starts_with?(tool_name, "memory_") or 
      String.starts_with?(tool_name, "cache_") ->
        {:memory, :memory}
        
      # Canvas/Visual tools
      String.starts_with?(tool_name, "canvas_") or 
      String.starts_with?(tool_name, "visual_") ->
        {:canvas, :canvas}
        
      # Database tools
      String.starts_with?(tool_name, "db_") or 
      String.starts_with?(tool_name, "query_") ->
        {:database, :database}
        
      true ->
        {:unknown, nil}
    end
  end
  
  defp forward_to_server(server_url, tool_name, params) do
    payload = %{
      jsonrpc: "2.0",
      method: "tools/call",
      params: %{
        name: tool_name,
        arguments: Map.get(params, "arguments", %{})
      },
      id: UUID.uuid4()
    }
    
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post(
      "#{server_url}/mcp",
      Jason.encode!(payload),
      headers,
      timeout: 30_000,
      recv_timeout: 30_000
    ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} ->
            {:ok, result}
            
          {:ok, %{"error" => error}} ->
            {:error, error["message"] || "Server error"}
            
          _ ->
            {:error, "Invalid response from server"}
        end
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to forward to #{server_url}: #{inspect(reason)}")
        {:error, "Server unavailable: #{reason}"}
    end
  end
  
  defp aggregate_all_tools(state) do
    # For now, return a static list
    # In production, would query each server's tools/list endpoint
    [
      # Neural/CROD tools
      %{
        name: "crod_process",
        description: "Process input through CROD neural network",
        inputSchema: %{
          type: "object",
          properties: %{
            input: %{type: "string", description: "Text to process"}
          },
          required: ["input"]
        }
      },
      %{
        name: "crod_status",
        description: "Get CROD brain status",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      },
      %{
        name: "trinity_activate",
        description: "Activate trinity consciousness",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      },
      
      # Memory tools
      %{
        name: "memory_store",
        description: "Store data in memory system",
        inputSchema: %{
          type: "object",
          properties: %{
            key: %{type: "string"},
            value: %{type: "object"}
          },
          required: ["key", "value"]
        }
      },
      %{
        name: "memory_recall",
        description: "Recall data from memory",
        inputSchema: %{
          type: "object",
          properties: %{
            key: %{type: "string"}
          },
          required: ["key"]
        }
      },
      
      # Pattern tools
      %{
        name: "pattern_search",
        description: "Search patterns in CROD database",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string"},
            limit: %{type: "integer", default: 10}
          },
          required: ["query"]
        }
      }
    ]
  end
  
  defp update_routing_stats(state, tool_name, status) do
    stats = Map.get(state.routing_stats, tool_name, %{success: 0, error: 0})
    
    updated_stats = case status do
      :success -> %{stats | success: stats.success + 1}
      :error -> %{stats | error: stats.error + 1}
    end
    
    put_in(state, [:routing_stats, tool_name], updated_stats)
  end
  
  # Health checks
  
  def handle_info(:health_check, state) do
    # Check health of all servers
    health_checks = Enum.map(state.servers, fn {name, url} ->
      health = check_server_health(url)
      {name, health}
    end)
    |> Enum.into(%{})
    
    state = %{state | health_checks: health_checks}
    
    # Schedule next health check
    Process.send_after(self(), :health_check, 30_000)
    
    {:noreply, state}
  end
  
  defp check_server_health(server_url) do
    case HTTPoison.get("#{server_url}/health", [], timeout: 5_000) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        %{status: :healthy, last_check: DateTime.utc_now()}
        
      _ ->
        %{status: :unhealthy, last_check: DateTime.utc_now()}
    end
  end
end