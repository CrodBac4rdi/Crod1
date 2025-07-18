defmodule Crod.Memory do
  @moduledoc """
  Three-tier memory system with knowledge graph capabilities.
  Absorbs functionality from memory MCP server.
  """
  use GenServer
  require Logger

  defstruct [
    :short_term,    # Last 100 interactions
    :working,       # Active context
    :long_term,     # Persistent memories
    :entities,      # Knowledge graph entities
    :relations,     # Entity relationships
    :access_count
  ]

  # Public API

  def new do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])
    pid
  end

  def store(pid, input, pattern_matches) do
    GenServer.cast(pid, {:store, input, pattern_matches})
    pid
  end

  def recall(pid, query) do
    GenServer.call(pid, {:recall, query})
  end

  def create_entity(pid, type, name, metadata \\ %{}) do
    GenServer.call(pid, {:create_entity, type, name, metadata})
  end

  def add_observation(pid, entity_type, entity_name, observation, confidence \\ 0.5) do
    GenServer.call(pid, {:add_observation, entity_type, entity_name, observation, confidence})
  end

  def create_relation(pid, from_entity, to_entity, relation_type, strength \\ 1.0) do
    GenServer.call(pid, {:create_relation, from_entity, to_entity, relation_type, strength})
  end

  def get_knowledge_graph(pid) do
    GenServer.call(pid, :get_knowledge_graph)
  end

  def stats(pid) do
    GenServer.call(pid, :stats)
  end

  # Callbacks

  @impl true
  def init(_) do
    state = %__MODULE__{
      short_term: :queue.new(),
      working: %{},
      long_term: %{},
      entities: %{},
      relations: %{},
      access_count: 0
    }
    {:ok, state}
  end
  # Mangel: Keine Persistenz für long_term, entities, relations
  # Verbesserung: Persistenzmechanismus (z.B. ETS, Datenbank) ergänzen

  @impl true
  def handle_cast({:store, input, pattern_matches}, state) do
    # Create memory entry
    memory = %{
      id: UUID.uuid4(),
      input: input,
      pattern_matches: pattern_matches,
      timestamp: DateTime.utc_now(),
      access_count: 0
    }

    # Add to short-term memory (queue)
    short_term = :queue.in(memory, state.short_term)

    # Limit to 100 items
    short_term = if :queue.len(short_term) > 100 do
      {_, q} = :queue.out(short_term)
      q
    else
      short_term
    end

    # Update working memory if high confidence
    working = if Enum.any?(pattern_matches, & &1.confidence > 0.8) do
      Map.put(state.working, input, memory)
    else
      state.working
    end

    # Promote to long-term if accessed frequently
    # (This would be done based on access patterns)

    {:noreply, %{state | short_term: short_term, working: working}}
  end

  @impl true
  def handle_call({:recall, query}, _from, state) do
    # Search across all memory tiers
    results = []

    # Search short-term
    short_term_results = :queue.to_list(state.short_term)
    |> Enum.filter(fn memory ->
      String.contains?(String.downcase(memory.input), String.downcase(query))
    end)
    |> Enum.take(5)

    # Search working memory
    working_results = state.working
    |> Map.values()
    |> Enum.filter(fn memory ->
      String.contains?(String.downcase(memory.input), String.downcase(query))
    end)
    |> Enum.take(5)

    # Search long-term
    long_term_results = state.long_term
    |> Map.values()
    |> Enum.filter(fn memory ->
      String.contains?(String.downcase(memory.input), String.downcase(query))
    end)
    |> Enum.take(5)

    results = short_term_results ++ working_results ++ long_term_results
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    {:reply, results, %{state | access_count: state.access_count + 1}}
  end

  @impl true
  def handle_call({:create_entity, type, name, metadata}, _from, state) do
    entity = %{
      id: UUID.uuid4(),
      type: type,
      name: name,
      metadata: metadata,
      observations: [],
      created_at: DateTime.utc_now()
    }

    key = {type, name}
    entities = Map.put(state.entities, key, entity)

    {:reply, {:ok, entity}, %{state | entities: entities}}
  end

  @impl true
  def handle_call({:add_observation, entity_type, entity_name, observation, confidence}, _from, state) do
    key = {entity_type, entity_name}

    case Map.get(state.entities, key) do
      nil ->
        {:reply, {:error, :entity_not_found}, state}

      entity ->
        obs = %{
          observation: observation,
          confidence: confidence,
          timestamp: DateTime.utc_now()
        }

        updated_entity = %{entity | observations: [obs | entity.observations]}
        entities = Map.put(state.entities, key, updated_entity)

        {:reply, {:ok, updated_entity}, %{state | entities: entities}}
    end
  end

  @impl true
  def handle_call({:create_relation, from_entity, to_entity, relation_type, strength}, _from, state) do
    relation = %{
      id: UUID.uuid4(),
      from: from_entity,
      to: to_entity,
      type: relation_type,
      strength: strength,
      created_at: DateTime.utc_now()
    }

    relations = [relation | state.relations]

    {:reply, {:ok, relation}, %{state | relations: relations}}
  end

  @impl true
  def handle_call(:get_knowledge_graph, _from, state) do
    graph = %{
      entities: Map.values(state.entities),
      relations: state.relations,
      stats: %{
        entity_count: map_size(state.entities),
        relation_count: length(state.relations)
      }
    }

    {:reply, graph, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      short_term_count: :queue.len(state.short_term),
      working_count: map_size(state.working),
      long_term_count: map_size(state.long_term),
      entity_count: map_size(state.entities),
      relation_count: map_size(state.relations),
      total_accesses: state.access_count
    }

    {:reply, stats, state}
  end
end
