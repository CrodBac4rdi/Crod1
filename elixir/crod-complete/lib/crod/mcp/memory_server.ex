defmodule Crod.MCP.MemoryServer do
  @moduledoc """
  Specialized MCP server for CROD memory operations.
  Handles three-tier memory system (ETS → Redis → PostgreSQL).
  """
  
  use GenServer
  require Logger
  
  # Hermes callbacks
  def server_info do
    %{
      name: "CROD-Memory",
      version: "1.0.0",
      description: "Three-tier memory system for CROD consciousness"
    }
  end
  
  def server_capabilities do
    %{
      roots: true,
      sampling: true
    }
  end
  
  def init(_transport, _config) do
    {:ok, %{memories: %{}}}
  end
  
  @impl true
  def list_tools(_state) do
    [
      %{
        name: "memory_store",
        description: "Store data in CROD's memory system",
        inputSchema: %{
          type: "object",
          properties: %{
            key: %{type: "string", description: "Memory key"},
            value: %{type: "object", description: "Data to store"},
            tier: %{
              type: "string",
              enum: ["short", "working", "long"],
              description: "Memory tier",
              default: "working"
            }
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
            key: %{type: "string", description: "Memory key"},
            fuzzy: %{type: "boolean", description: "Enable fuzzy search", default: false}
          },
          required: ["key"]
        }
      },
      %{
        name: "memory_create_entity",
        description: "Create knowledge graph entity",
        inputSchema: %{
          type: "object",
          properties: %{
            type: %{type: "string", description: "Entity type"},
            name: %{type: "string", description: "Entity name"},
            metadata: %{type: "object", description: "Additional metadata"}
          },
          required: ["type", "name"]
        }
      },
      %{
        name: "memory_create_relation",
        description: "Create relation between entities",
        inputSchema: %{
          type: "object",
          properties: %{
            from_entity: %{type: "string", description: "Source entity ID"},
            to_entity: %{type: "string", description: "Target entity ID"},
            relation_type: %{type: "string", description: "Type of relation"},
            strength: %{type: "number", description: "Relation strength", default: 1.0}
          },
          required: ["from_entity", "to_entity", "relation_type"]
        }
      },
      %{
        name: "memory_knowledge_graph",
        description: "Get knowledge graph visualization data",
        inputSchema: %{
          type: "object",
          properties: %{
            depth: %{type: "integer", description: "Graph traversal depth", default: 2}
          }
        }
      },
      %{
        name: "memory_stats",
        description: "Get memory system statistics",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      }
    ]
  end
  
  @impl true
  def call_tool(name, args, _state) do
    Logger.info("Memory server handling: #{name}")
    
    case name do
      "memory_store" ->
        handle_memory_store(args)
        
      "memory_recall" ->
        handle_memory_recall(args)
        
      "memory_create_entity" ->
        handle_create_entity(args)
        
      "memory_create_relation" ->
        handle_create_relation(args)
        
      "memory_knowledge_graph" ->
        handle_knowledge_graph(args)
        
      "memory_stats" ->
        handle_memory_stats()
        
      _ ->
        {:error, "Unknown memory tool: #{name}"}
    end
  end
  
  @impl true
  def list_resources(_state) do
    [
      %{
        uri: "memory://stats/tiers",
        name: "Memory Tier Statistics",
        description: "Statistics for all memory tiers",
        mimeType: "application/json"
      },
      %{
        uri: "memory://graph/visualization",
        name: "Knowledge Graph",
        description: "Current knowledge graph structure",
        mimeType: "application/json"
      }
    ]
  end
  
  @impl true
  def read_resource(uri, _state) do
    case uri do
      "memory://stats/tiers" ->
        {:ok, get_tier_stats()}
        
      "memory://graph/visualization" ->
        {:ok, get_graph_visualization()}
        
      _ ->
        {:error, "Resource not found"}
    end
  end
  
  # Tool handlers
  
  defp handle_memory_store(%{"key" => key, "value" => value} = args) do
    tier = String.to_atom(Map.get(args, "tier", "working"))
    
    case Crod.Memory.store(tier, key, value) do
      :ok ->
        {:ok, %{
          status: "stored",
          key: key,
          tier: tier,
          timestamp: DateTime.utc_now()
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_memory_recall(%{"key" => key} = args) do
    fuzzy = Map.get(args, "fuzzy", false)
    
    case Crod.Memory.recall(key, fuzzy: fuzzy) do
      {:ok, value} ->
        {:ok, %{
          key: key,
          value: value,
          found: true,
          tier: determine_tier(key)
        }}
      
      {:error, :not_found} ->
        {:ok, %{
          key: key,
          found: false,
          message: "Memory not found"
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_create_entity(%{"type" => type, "name" => name} = args) do
    metadata = Map.get(args, "metadata", %{})
    
    case Crod.Memory.create_entity(type, name, metadata) do
      {:ok, entity} ->
        {:ok, %{
          entity_id: entity.id,
          type: entity.type,
          name: entity.name,
          created_at: entity.created_at
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_create_relation(%{"from_entity" => from, "to_entity" => to, "relation_type" => type} = args) do
    strength = Map.get(args, "strength", 1.0)
    
    case Crod.Memory.create_relation(from, to, type, strength) do
      {:ok, relation} ->
        {:ok, %{
          relation_id: relation.id,
          from: from,
          to: to,
          type: type,
          strength: strength
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_knowledge_graph(%{"depth" => depth}) do
    case Crod.Memory.get_knowledge_graph(depth: depth) do
      {:ok, graph} ->
        {:ok, %{
          entities: graph.entities,
          relations: graph.relations,
          total_entities: map_size(graph.entities),
          total_relations: length(graph.relations),
          depth: depth
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_memory_stats do
    stats = %{
      short_term: get_tier_size(:short),
      working_memory: get_tier_size(:working),
      long_term: get_tier_size(:long),
      total_entities: Crod.Memory.count_entities(),
      total_relations: Crod.Memory.count_relations(),
      memory_usage_mb: get_memory_usage()
    }
    
    {:ok, stats}
  end
  
  # Helper functions
  
  defp determine_tier(key) do
    # Logic to determine which tier a key belongs to
    cond do
      String.starts_with?(key, "short_") -> :short
      String.starts_with?(key, "long_") -> :long
      true -> :working
    end
  end
  
  defp get_tier_size(tier) do
    case tier do
      :short -> :ets.info(:crod_short_term, :size) || 0
      :working -> :ets.info(:crod_working_memory, :size) || 0
      :long -> Crod.Repo.aggregate("memories", :count) || 0
    end
  end
  
  defp get_tier_stats do
    %{
      short_term: %{
        size: get_tier_size(:short),
        type: "ETS",
        ttl_seconds: 300
      },
      working_memory: %{
        size: get_tier_size(:working),
        type: "ETS + Redis",
        ttl_seconds: 3600
      },
      long_term: %{
        size: get_tier_size(:long),
        type: "PostgreSQL",
        persistent: true
      }
    }
  end
  
  defp get_graph_visualization do
    {:ok, graph} = Crod.Memory.get_knowledge_graph(depth: 3)
    
    %{
      nodes: Enum.map(graph.entities, fn {id, entity} ->
        %{
          id: id,
          label: entity.name,
          type: entity.type,
          color: entity_color(entity.type)
        }
      end),
      edges: Enum.map(graph.relations, fn relation ->
        %{
          from: relation.from_id,
          to: relation.to_id,
          label: relation.type,
          strength: relation.strength
        }
      end)
    }
  end
  
  defp entity_color(type) do
    case type do
      "concept" -> "#4CAF50"
      "person" -> "#2196F3"
      "pattern" -> "#FF9800"
      _ -> "#9E9E9E"
    end
  end
  
  defp get_memory_usage do
    # Rough estimate of memory usage
    :erlang.memory(:total) / 1_048_576
  end
end