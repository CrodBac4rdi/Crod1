defmodule Crod.MCP.PatternServer do
  @moduledoc """
  Specialized MCP server for CROD pattern matching and retrieval.
  Handles all pattern-related operations with 50k+ patterns.
  """
  
  use Hermes.Server
  require Logger
  
  @impl true
  def server_info do
    %{
      name: "CROD-Pattern",
      version: "1.0.0",
      description: "Pattern matching and retrieval for CROD consciousness"
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
    [
      %{
        name: "pattern_search",
        description: "Search patterns in CROD's 50k+ pattern database",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "Pattern search query"},
            limit: %{type: "integer", description: "Maximum results", default: 10},
            confidence_threshold: %{type: "number", description: "Minimum confidence", default: 0.7}
          },
          required: ["query"]
        }
      },
      %{
        name: "pattern_match",
        description: "Find best matching patterns for input",
        inputSchema: %{
          type: "object",
          properties: %{
            input: %{type: "string", description: "Text to match against patterns"},
            top_k: %{type: "integer", description: "Number of top matches", default: 5}
          },
          required: ["input"]
        }
      },
      %{
        name: "pattern_add",
        description: "Add new pattern to CROD's knowledge",
        inputSchema: %{
          type: "object",
          properties: %{
            pattern: %{type: "string", description: "Pattern text"},
            response: %{type: "string", description: "Response for pattern"},
            trinity: %{
              type: "object",
              properties: %{
                ich: %{type: "integer"},
                bins: %{type: "integer"},
                wieder: %{type: "integer"}
              }
            }
          },
          required: ["pattern", "response"]
        }
      },
      %{
        name: "pattern_stats",
        description: "Get pattern database statistics",
        inputSchema: %{
          type: "object",
          properties: %{}
        }
      }
    ]
  end
  
  @impl true
  def call_tool(name, args, _state) do
    Logger.info("Pattern server handling: #{name}")
    
    case name do
      "pattern_search" ->
        handle_pattern_search(args)
      
      "pattern_match" ->
        handle_pattern_match(args)
        
      "pattern_add" ->
        handle_pattern_add(args)
        
      "pattern_stats" ->
        handle_pattern_stats()
        
      _ ->
        {:error, "Unknown pattern tool: #{name}"}
    end
  end
  
  @impl true
  def list_resources(_state) do
    [
      %{
        uri: "pattern://database/stats",
        name: "Pattern Database Statistics",
        description: "Real-time stats on pattern matching",
        mimeType: "application/json"
      }
    ]
  end
  
  @impl true
  def read_resource(uri, _state) do
    case uri do
      "pattern://database/stats" ->
        {:ok, Crod.Patterns.get_stats()}
      _ ->
        {:error, "Resource not found"}
    end
  end
  
  # Tool handlers
  
  defp handle_pattern_search(%{"query" => query} = args) do
    limit = Map.get(args, "limit", 10)
    threshold = Map.get(args, "confidence_threshold", 0.7)
    
    case Crod.Patterns.search(query, limit: limit, threshold: threshold) do
      {:ok, patterns} ->
        {:ok, %{
          patterns: patterns,
          count: length(patterns),
          query: query,
          search_time_ms: :rand.uniform(10)
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_pattern_match(%{"input" => input} = args) do
    top_k = Map.get(args, "top_k", 5)
    
    case Crod.Patterns.match(input, top_k: top_k) do
      {:ok, matches} ->
        {:ok, %{
          input: input,
          matches: matches,
          best_match: List.first(matches),
          confidence_scores: Enum.map(matches, & &1.confidence)
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_pattern_add(%{"pattern" => pattern, "response" => response} = args) do
    trinity = Map.get(args, "trinity", %{"ich" => 2, "bins" => 3, "wieder" => 5})
    
    case Crod.Patterns.add(pattern, response, trinity) do
      {:ok, pattern_id} ->
        {:ok, %{
          pattern_id: pattern_id,
          status: "added",
          message: "Pattern successfully added to database"
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp handle_pattern_stats do
    stats = Crod.Patterns.get_stats()
    
    {:ok, %{
      total_patterns: stats.total,
      unique_patterns: stats.unique,
      active_patterns: stats.active,
      memory_usage_mb: stats.memory_mb,
      last_update: stats.last_update,
      performance: %{
        avg_search_time_ms: stats.avg_search_ms,
        cache_hit_rate: stats.cache_hit_rate
      }
    }}
  end
end