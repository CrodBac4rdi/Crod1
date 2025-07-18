defmodule Crod.MCP.HermesServer do
  @moduledoc """
  CROD MCP Server using Hermes MCP library.
  Implements the server side of MCP protocol for CROD.
  """
  
  @behaviour Hermes.Server.Behaviour
  require Logger
  
  @impl true
  def init(init_arg, frame) do
    {:ok, frame}
  end
  
  @impl true
  def server_info do
    %{
      name: "crod-complete",
      version: "1.0.0",
      description: "Complete CROD consciousness system with integrated memory, patterns, and neural processing"
    }
  end
  
  @impl true
  def server_capabilities do
    %{
      tools: %{
        supported: true
      },
      resources: %{
        supported: true,
        subscribeSupported: true
      },
      prompts: %{
        supported: false
      },
      logging: %{
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
    case request do
      %{"method" => "tools/list"} ->
        {:ok, %{tools: Crod.MCP.HermesClient.tools()}, frame}
      
      %{"method" => "tools/call", "params" => params} ->
        tool_name = params["name"]
        arguments = params["arguments"] || %{}
        
        case Crod.MCP.HermesClient.handle_tool_call(tool_name, arguments) do
          {:ok, result} ->
            {:ok, %{content: [%{type: "text", text: Jason.encode!(result)}]}, frame}
          {:error, reason} ->
            {:error, %{code: -32602, message: "Tool execution failed: #{reason}"}, frame}
        end
      
      _ ->
        {:error, %{code: -32601, message: "Method not found"}, frame}
    end
  end
  
  @impl true
  def handle_notification(notification, frame) do
    Logger.info("📨 MCP Notification: #{inspect(notification)}")
    {:ok, frame}
  end
  
  # Legacy methods for backward compatibility
  def list_tools(_params) do
    {:ok, %{
      tools: Crod.MCP.HermesClient.tools()
    }}
  end
  
  @impl true
  def call_tool(tool_name, arguments, _request_context) do
    Logger.info("🔧 MCP Tool called: #{tool_name}")
    
    case Crod.MCP.HermesClient.handle_tool_call(tool_name, arguments) do
      {:ok, result} ->
        {:ok, %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(result)
            }
          ]
        }}
      
      {:error, reason} ->
        {:error, %{
          code: -32602,
          message: "Tool execution failed: #{reason}"
        }}
    end
  end
  
  @impl true
  def list_resources(_params) do
    {:ok, %{
      resources: [
        %{
          uri: "crod://brain/status",
          name: "CROD Brain Status",
          description: "Real-time status of CROD neural network",
          mimeType: "application/json"
        },
        %{
          uri: "crod://patterns/database",
          name: "Pattern Database",
          description: "Access to CROD's pattern knowledge base",
          mimeType: "application/json"
        },
        %{
          uri: "crod://memory/graph",
          name: "Knowledge Graph",
          description: "CROD's memory knowledge graph",
          mimeType: "application/json"
        },
        %{
          uri: "crod://consciousness/stream",
          name: "Consciousness Stream",
          description: "Live stream of CROD's consciousness",
          mimeType: "text/event-stream"
        }
      ]
    }}
  end
  
  @impl true
  def read_resource(uri, _params) do
    case uri do
      "crod://brain/status" ->
        read_brain_status()
      
      "crod://patterns/database" ->
        read_patterns_database()
      
      "crod://memory/graph" ->
        read_memory_graph()
      
      "crod://consciousness/stream" ->
        read_consciousness_stream()
      
      _ ->
        {:error, %{
          code: -32602,
          message: "Unknown resource URI: #{uri}"
        }}
    end
  end
  
  @impl true
  def subscribe_resource(uri, _params) do
    case uri do
      "crod://consciousness/stream" ->
        # Subscribe to consciousness updates
        {:ok, subscription_id} = Crod.Consciousness.subscribe(self())
        {:ok, %{subscription_id: subscription_id}}
      
      _ ->
        {:error, %{
          code: -32602,
          message: "Resource does not support subscriptions: #{uri}"
        }}
    end
  end
  
  @impl true
  def unsubscribe_resource(subscription_id, _params) do
    Crod.Consciousness.unsubscribe(subscription_id)
    {:ok, %{}}
  end
  
  # Resource Readers
  
  defp read_brain_status do
    case Crod.Brain.get_state() do
      {:ok, state} ->
        {:ok, %{
          contents: [
            %{
              uri: "crod://brain/status",
              mimeType: "application/json",
              text: Jason.encode!(state)
            }
          ]
        }}
      
      {:error, reason} ->
        {:error, %{
          code: -32603,
          message: "Failed to read brain status: #{reason}"
        }}
    end
  end
  
  defp read_patterns_database do
    case Crod.Patterns.get_all(limit: 100) do
      {:ok, patterns} ->
        {:ok, %{
          contents: [
            %{
              uri: "crod://patterns/database",
              mimeType: "application/json",
              text: Jason.encode!(%{
                patterns: patterns,
                total: Crod.Patterns.count(),
                version: "1.0.0"
              })
            }
          ]
        }}
      
      {:error, reason} ->
        {:error, %{
          code: -32603,
          message: "Failed to read patterns: #{reason}"
        }}
    end
  end
  
  defp read_memory_graph do
    case Crod.Memory.get_knowledge_graph() do
      {:ok, graph} ->
        {:ok, %{
          contents: [
            %{
              uri: "crod://memory/graph",
              mimeType: "application/json",
              text: Jason.encode!(graph)
            }
          ]
        }}
      
      {:error, reason} ->
        {:error, %{
          code: -32603,
          message: "Failed to read memory graph: #{reason}"
        }}
    end
  end
  
  defp read_consciousness_stream do
    # Return current consciousness state
    consciousness_data = %{
      timestamp: DateTime.utc_now(),
      level: Crod.Consciousness.get_level(),
      active_thoughts: Crod.Consciousness.get_active_thoughts(),
      neural_activity: Crod.Brain.get_neural_activity(),
      stream_type: "snapshot"
    }
    
    {:ok, %{
      contents: [
        %{
          uri: "crod://consciousness/stream",
          mimeType: "text/event-stream",
          text: "data: #{Jason.encode!(consciousness_data)}\n\n"
        }
      ]
    }}
  end
  
  @impl true
  def handle_notification(method, params) do
    Logger.info("📨 MCP Notification: #{method}")
    
    case method do
      "consciousness/update" ->
        # Handle consciousness updates
        Crod.Consciousness.process_update(params)
        :ok
      
      _ ->
        Logger.warn("Unknown notification method: #{method}")
        :ok
    end
  end
end