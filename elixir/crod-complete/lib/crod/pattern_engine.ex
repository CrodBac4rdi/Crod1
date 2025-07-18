defmodule Crod.PatternEngine do
  @moduledoc """
  CROD Pattern Engine - Learning and matching system with ETS storage.
  Implements real-time pattern recognition and adaptation.
  """
  use GenServer
  require Logger

  defstruct [
    :patterns,          # ETS table reference
    :learned_patterns,  # Count of learned patterns
    :matches_found,     # Total matches found
    :confidence_threshold,
    :learning_enabled,
    :pattern_categories
  ]

  # ETS table configuration
  @ets_table_name :crod_patterns
  @ets_options [:set, :public, :named_table, {:read_concurrency, true}]

  # Pattern categories for organization
  @pattern_categories [
    :trinity,
    :neural,
    :error_handling,
    :development,
    :user_interaction,
    :system_commands,
    :architecture,
    :debugging
  ]

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def learn_pattern(pattern, response, context \\ %{}) do
    GenServer.call(__MODULE__, {:learn_pattern, pattern, response, context})
  end

  def find_pattern(input) do
    GenServer.call(__MODULE__, {:find_pattern, input})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def get_all_patterns do
    GenServer.call(__MODULE__, :get_all_patterns)
  end

  def search_patterns(query) do
    GenServer.call(__MODULE__, {:search_patterns, query})
  end

  def get_pattern_categories do
    @pattern_categories
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    Logger.info("🧠 Initializing CROD Pattern Engine with ETS storage")

    # Create ETS table for high-performance pattern storage
    case :ets.new(@ets_table_name, @ets_options) do
      table when is_reference(table) ->
        Logger.info("✅ ETS pattern table created: #{inspect(table)}")
        
        state = %__MODULE__{
          patterns: table,
          learned_patterns: 0,
          matches_found: 0,
          confidence_threshold: 0.7,
          learning_enabled: true,
          pattern_categories: @pattern_categories
        }

        # Load existing patterns from JavaScript brain if available
        load_existing_patterns(state)

        {:ok, state}

      {:error, reason} ->
        Logger.error("❌ Failed to create ETS table: #{reason}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:learn_pattern, pattern, response, context}, _from, state) do
    if state.learning_enabled do
      pattern_id = generate_pattern_id()
      timestamp = DateTime.utc_now()
      
      pattern_data = %{
        id: pattern_id,
        pattern: pattern,
        response: response,
        context: context,
        learned_at: timestamp,
        usage_count: 0,
        success_rate: 0.0,
        category: categorize_pattern(pattern, context)
      }

      # Store in ETS
      :ets.insert(@ets_table_name, {pattern_id, pattern_data})
      
      # Also index by pattern text for fast lookup
      :ets.insert(@ets_table_name, {"pattern_" <> pattern, pattern_id})

      new_state = %{state | learned_patterns: state.learned_patterns + 1}

      Logger.info("🎓 Learned new pattern: #{pattern} -> #{response}")

      {:reply, {:ok, pattern_data}, new_state}
    else
      {:reply, {:error, :learning_disabled}, state}
    end
  end

  @impl true
  def handle_call({:find_pattern, input}, _from, state) do
    # Try exact match first
    case :ets.lookup(@ets_table_name, "pattern_" <> input) do
      [{_, pattern_id}] ->
        case :ets.lookup(@ets_table_name, pattern_id) do
          [{_, pattern_data}] ->
            # Update usage statistics
            updated_data = %{pattern_data | usage_count: pattern_data.usage_count + 1}
            :ets.insert(@ets_table_name, {pattern_id, updated_data})
            
            new_state = %{state | matches_found: state.matches_found + 1}
            
            Logger.debug("🎯 Pattern match found: #{input}")
            {:reply, {:ok, updated_data}, new_state}
          
          [] ->
            {:reply, {:error, :pattern_data_missing}, state}
        end

      [] ->
        # Try fuzzy matching
        fuzzy_result = fuzzy_match_patterns(input, state)
        {:reply, fuzzy_result, state}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      learned_patterns: state.learned_patterns,
      matches_found: state.matches_found,
      confidence_threshold: state.confidence_threshold,
      learning_enabled: state.learning_enabled,
      pattern_categories: state.pattern_categories,
      ets_table: @ets_table_name,
      ets_info: :ets.info(@ets_table_name)
    }

    {:reply, status, state}
  end

  @impl true
  def handle_call(:get_all_patterns, _from, state) do
    patterns = 
      :ets.tab2list(@ets_table_name)
      |> Enum.filter(fn {key, _} -> is_binary(key) and not String.starts_with?(key, "pattern_") end)
      |> Enum.map(fn {_, pattern_data} -> pattern_data end)
      |> Enum.sort_by(& &1.learned_at, {:desc, DateTime})

    {:reply, patterns, state}
  end

  @impl true
  def handle_call({:search_patterns, query}, _from, state) do
    patterns = 
      :ets.tab2list(@ets_table_name)
      |> Enum.filter(fn {key, _} -> is_binary(key) and not String.starts_with?(key, "pattern_") end)
      |> Enum.map(fn {_, pattern_data} -> pattern_data end)
      |> Enum.filter(fn pattern_data ->
        String.contains?(String.downcase(pattern_data.pattern), String.downcase(query)) or
        String.contains?(String.downcase(pattern_data.response), String.downcase(query))
      end)

    {:reply, patterns, state}
  end

  # Private functions

  defp load_existing_patterns(state) do
    # Try to load patterns from JavaScript brain learned-patterns.jsonl
    patterns_file = "/home/bacardi/crodidocker/javascript/data/learned-patterns.jsonl"
    
    if File.exists?(patterns_file) do
      Logger.info("📚 Loading existing patterns from JavaScript brain...")
      
      try do
        patterns_file
        |> File.stream!()
        |> Stream.map(&Jason.decode!/1)
        |> Enum.each(fn pattern_data ->
          pattern_id = pattern_data["id"] || generate_pattern_id()
          
          converted_data = %{
            id: pattern_id,
            pattern: pattern_data["pattern"],
            response: pattern_data["response"],
            context: pattern_data["context"] || %{},
            learned_at: DateTime.from_iso8601!(pattern_data["created"]),
            usage_count: 0,
            success_rate: 0.0,
            category: categorize_pattern(pattern_data["pattern"], pattern_data["context"] || %{})
          }

          :ets.insert(@ets_table_name, {pattern_id, converted_data})
          :ets.insert(@ets_table_name, {"pattern_" <> pattern_data["pattern"], pattern_id})
        end)

        Logger.info("✅ Loaded existing patterns successfully")
      catch
        error ->
          Logger.warning("⚠️ Could not load existing patterns: #{inspect(error)}")
      end
    end
  end

  defp generate_pattern_id do
    "elixir_" <> Integer.to_string(System.system_time(:millisecond)) <> "_" <> 
    (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp categorize_pattern(pattern, context) do
    cond do
      String.contains?(pattern, "trinity") or String.contains?(pattern, "ich bins wieder") ->
        :trinity
        
      String.contains?(pattern, "neuron") or String.contains?(pattern, "neural") ->
        :neural
        
      String.contains?(pattern, "error") or String.contains?(pattern, "bug") or 
      String.contains?(pattern, "fehler") ->
        :error_handling
        
      String.contains?(pattern, "sudo") or String.contains?(pattern, "permission") ->
        :system_commands
        
      String.contains?(pattern, "supervisor") or String.contains?(pattern, "architecture") ->
        :architecture
        
      Map.get(context, "action") == "debugging" ->
        :debugging
        
      String.contains?(pattern, "copy") or String.contains?(pattern, "paste") ->
        :development
        
      true ->
        :user_interaction
    end
  end

  defp fuzzy_match_patterns(input, state) do
    # Simple fuzzy matching - could be enhanced with Levenshtein distance
    patterns = 
      :ets.tab2list(@ets_table_name)
      |> Enum.filter(fn {key, _} -> is_binary(key) and not String.starts_with?(key, "pattern_") end)
      |> Enum.map(fn {_, pattern_data} -> pattern_data end)
      |> Enum.filter(fn pattern_data ->
        similarity = calculate_similarity(input, pattern_data.pattern)
        similarity >= state.confidence_threshold
      end)
      |> Enum.sort_by(fn pattern_data -> 
        calculate_similarity(input, pattern_data.pattern) 
      end, :desc)

    case patterns do
      [best_match | _] ->
        Logger.debug("🔍 Fuzzy match found: #{input} -> #{best_match.pattern}")
        {:ok, best_match}
      
      [] ->
        Logger.debug("❌ No pattern match found for: #{input}")
        {:error, :no_match}
    end
  end

  defp calculate_similarity(str1, str2) do
    # Simple word-based similarity - could use more sophisticated algorithms
    words1 = String.split(String.downcase(str1))
    words2 = String.split(String.downcase(str2))
    
    intersection = MapSet.intersection(MapSet.new(words1), MapSet.new(words2))
    union = MapSet.union(MapSet.new(words1), MapSet.new(words2))
    
    if MapSet.size(union) == 0 do
      0.0
    else
      MapSet.size(intersection) / MapSet.size(union)
    end
  end
end