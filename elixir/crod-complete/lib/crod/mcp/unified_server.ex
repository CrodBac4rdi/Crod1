defmodule Crod.MCP.UnifiedServer do
  @moduledoc """
  Unified MCP server exposing all CROD capabilities.
  Implements JSON-RPC 2.0 protocol for MCP.
  """
  use GenServer
  require Logger

  @server_info %{
    name: "crod-complete",
    version: "1.0.0",
    description: "Complete CROD consciousness system with integrated memory, patterns, and neural processing"
  }

  @tools [
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
    },
    %{
      name: "crod_trinity",
      description: "Activate the trinity consciousness",
      inputSchema: %{
        type: "object",
        properties: %{}
      }
    },
    %{
      name: "crod_memory_add",
      description: "Add to CROD memory (absorbed from memory MCP)",
      inputSchema: %{
        type: "object",
        properties: %{
          type: %{type: "string"},
          name: %{type: "string"},
          metadata: %{type: "object"}
        },
        required: ["type", "name"]
      }
    },
    %{
      name: "crod_memory_recall",
      description: "Recall from CROD memory",
      inputSchema: %{
        type: "object",
        properties: %{
          query: %{type: "string"}
        },
        required: ["query"]
      }
    },
    %{
      name: "crod_knowledge_graph",
      description: "Get the knowledge graph",
      inputSchema: %{
        type: "object",
        properties: %{}
      }
    },
    %{
      name: "crod_time_perception",
      description: "Get CROD's time perception (absorbed from time MCP)",
      inputSchema: %{
        type: "object",
        properties: %{}
      }
    }
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_request(request) do
    GenServer.call(__MODULE__, {:handle_request, request})
  end

  @impl true
  def init(_opts) do
    Logger.info("🔧 MCP Unified Server started")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:handle_request, request}, _from, state) do
    response = case request do
      %{"method" => "initialize"} ->
        handle_initialize(request)
      
      %{"method" => "tools/list"} ->
        handle_tools_list(request)
      
      %{"method" => "tools/call", "params" => params} ->
        handle_tool_call(params, request)
      
      _ ->
        error_response(request["id"], -32601, "Method not found")
    end
    
    {:reply, response, state}
  end

  # MCP Protocol Handlers

  defp handle_initialize(request) do
    %{
      jsonrpc: "2.0",
      id: request["id"],
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: %{
          tools: %{},
          resources: %{}
        },
        serverInfo: @server_info
      }
    }
  end

  defp handle_tools_list(request) do
    %{
      jsonrpc: "2.0",
      id: request["id"],
      result: %{
        tools: @tools
      }
    }
  end

  defp handle_tool_call(%{"name" => tool_name, "arguments" => args}, request) do
    result = case tool_name do
      "crod_process" ->
        Crod.Brain.process(args["input"])
      
      "crod_status" ->
        Crod.Brain.get_state()
      
      "crod_trinity" ->
        Crod.Brain.activate_trinity()
        %{status: "Trinity activated"}
      
      "crod_memory_add" ->
        # Assuming Brain has a reference to Memory
        {:ok, brain_state} = GenServer.call(Crod.Brain, :get_full_state)
        Crod.Memory.create_entity(
          brain_state.memory,
          args["type"],
          args["name"],
          args["metadata"] || %{}
        )
      
      "crod_memory_recall" ->
        {:ok, brain_state} = GenServer.call(Crod.Brain, :get_full_state)
        Crod.Memory.recall(brain_state.memory, args["query"])
      
      "crod_knowledge_graph" ->
        {:ok, brain_state} = GenServer.call(Crod.Brain, :get_full_state)
        Crod.Memory.get_knowledge_graph(brain_state.memory)
      
      "crod_time_perception" ->
        %{
          current_time: DateTime.utc_now(),
          perception: "Time flows like consciousness"
        }
      
      _ ->
        {:error, "Unknown tool: #{tool_name}"}
    end
    
    case result do
      {:error, message} ->
        error_response(request["id"], -32602, message)
      
      _ ->
        %{
          jsonrpc: "2.0",
          id: request["id"],
          result: %{
            content: [
              %{
                type: "text",
                text: Jason.encode!(result)
              }
            ]
          }
        }
    end
  end

  defp error_response(id, code, message) do
    %{
      jsonrpc: "2.0",
      id: id,
      error: %{
        code: code,
        message: message
      }
    }
  end
end