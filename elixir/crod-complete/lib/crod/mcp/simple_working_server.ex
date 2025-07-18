defmodule Crod.MCP.SimpleWorkingServer do
  @moduledoc """
  Simple working MCP server to test basic functionality
  """
  
  @behaviour Hermes.Server.Behaviour
  require Logger
  
  @impl true
  def init(_init_arg, frame) do
    Logger.info("🧠 Simple CROD MCP Server started")
    {:ok, frame}
  end
  
  @impl true
  def server_info do
    %{
      name: "crod-simple",
      version: "1.0.0",
      description: "Simple CROD MCP server for testing"
    }
  end
  
  @impl true
  def server_capabilities do
    %{
      tools: %{
        supported: true
      }
    }
  end
  
  @impl true
  def supported_protocol_versions do
    ["2024-11-05"]
  end
  
  @impl true
  def handle_request(request, frame) do
    Logger.info("📨 MCP Request: #{inspect(request)}")
    
    case request do
      %{"method" => "tools/list"} ->
        tools = [
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
            description: "Get current CROD brain status",
            inputSchema: %{
              type: "object",
              properties: %{}
            }
          }
        ]
        
        {:ok, %{tools: tools}, frame}
      
      %{"method" => "tools/call", "params" => %{"name" => "crod_process", "arguments" => args}} ->
        input = Map.get(args, "input", "")
        
        result = %{
          response: "CROD processed: #{input}",
          confidence: 0.95,
          patterns: ["test_pattern"],
          timestamp: DateTime.utc_now()
        }
        
        {:ok, %{content: [%{type: "text", text: Jason.encode!(result)}]}, frame}
      
      %{"method" => "tools/call", "params" => %{"name" => "crod_status"}} ->
        status = %{
          status: "ACTIVE",
          confidence: 0.8,
          patterns_loaded: 5,
          neurons_active: 10000,
          uptime: "5 minutes"
        }
        
        {:ok, %{content: [%{type: "text", text: Jason.encode!(status)}]}, frame}
      
      %{"method" => "tools/call", "params" => %{"name" => name}} ->
        {:error, %{code: -32602, message: "Unknown tool: #{name}"}, frame}
      
      _ ->
        {:error, %{code: -32601, message: "Method not found: #{request["method"]}"}, frame}
    end
  end
  
  @impl true
  def handle_notification(notification, frame) do
    Logger.info("📢 MCP Notification: #{inspect(notification)}")
    {:ok, frame}
  end
end