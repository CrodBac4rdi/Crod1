defmodule Crod.PatternPersistence do
  @moduledoc """
  Handles persistence of patterns to disk and database,
  with versioning, compression, and incremental updates.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{Patterns, Repo}
  
  @persistence_interval 300_000  # 5 minutes
  @chunk_size 1000
  @pattern_dir "data/patterns"
  @backup_dir "data/patterns/backups"
  @version_file "data/patterns/version.json"
  
  defstruct [
    :last_persist_time,
    :pending_changes,
    :current_version,
    :persistence_stats,
    :auto_persist_enabled
  ]
  
  # Database schema
  defmodule PatternRecord do
    use Ecto.Schema
    import Ecto.Changeset
    
    schema "patterns" do
      field :input, :string
      field :output, :string
      field :confidence, :float
      field :metadata, :map
      field :usage_count, :integer, default: 0
      field :last_used, :utc_datetime
      field :version, :integer
      field :checksum, :string
      
      timestamps()
    end
    
    def changeset(pattern, attrs) do
      pattern
      |> cast(attrs, [:input, :output, :confidence, :metadata, :usage_count, :last_used, :version, :checksum])
      |> validate_required([:input, :output, :confidence])
      |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
      |> unique_constraint(:input)
    end
  end
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def persist_now do
    GenServer.call(__MODULE__, :persist_now, 30_000)
  end
  
  def load_patterns do
    GenServer.call(__MODULE__, :load_patterns)
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def enable_auto_persist do
    GenServer.cast(__MODULE__, :enable_auto_persist)
  end
  
  def disable_auto_persist do
    GenServer.cast(__MODULE__, :disable_auto_persist)
  end
  
  def export_to_file(filename) do
    GenServer.call(__MODULE__, {:export_to_file, filename})
  end
  
  def import_from_file(filename) do
    GenServer.call(__MODULE__, {:import_from_file, filename})
  end
  
  # Server Callbacks
  
  def init(opts) do
    # Ensure directories exist
    File.mkdir_p!(@pattern_dir)
    File.mkdir_p!(@backup_dir)
    
    state = %__MODULE__{
      last_persist_time: DateTime.utc_now(),
      pending_changes: [],
      current_version: load_current_version(),
      persistence_stats: init_stats(),
      auto_persist_enabled: Keyword.get(opts, :auto_persist, true)
    }
    
    # Load patterns on startup
    send(self(), :initial_load)
    
    # Schedule periodic persistence
    if state.auto_persist_enabled do
      :timer.send_interval(@persistence_interval, self(), :persist_patterns)
    end
    
    # Subscribe to pattern changes
    Phoenix.PubSub.subscribe(Crod.PubSub, "patterns:changes")
    
    Logger.info("💾 Pattern Persistence initialized (version #{state.current_version})")
    
    {:ok, state}
  end
  
  def handle_call(:persist_now, _from, state) do
    {result, new_state} = perform_persistence(state)
    {:reply, result, new_state}
  end
  
  def handle_call(:load_patterns, _from, state) do
    result = load_all_patterns()
    {:reply, result, state}
  end
  
  def handle_call(:get_stats, _from, state) do
    {:reply, state.persistence_stats, state}
  end
  
  def handle_call({:export_to_file, filename}, _from, state) do
    result = export_patterns_to_file(filename)
    {:reply, result, state}
  end
  
  def handle_call({:import_from_file, filename}, _from, state) do
    case import_patterns_from_file(filename) do
      {:ok, count} ->
        new_state = increment_version(state)
        {:reply, {:ok, count}, new_state}
      error ->
        {:reply, error, state}
    end
  end
  
  def handle_cast(:enable_auto_persist, state) do
    if not state.auto_persist_enabled do
      :timer.send_interval(@persistence_interval, self(), :persist_patterns)
    end
    {:noreply, %{state | auto_persist_enabled: true}}
  end
  
  def handle_cast(:disable_auto_persist, state) do
    {:noreply, %{state | auto_persist_enabled: false}}
  end
  
  def handle_info(:initial_load, state) do
    case load_all_patterns() do
      {:ok, count} ->
        Logger.info("📚 Loaded #{count} patterns from persistence")
        new_stats = Map.put(state.persistence_stats, :patterns_loaded, count)
        {:noreply, %{state | persistence_stats: new_stats}}
      
      {:error, reason} ->
        Logger.error("Failed to load patterns: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  def handle_info(:persist_patterns, state) do
    if state.auto_persist_enabled and length(state.pending_changes) > 0 do
      {_result, new_state} = perform_persistence(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  def handle_info({:pattern_changed, change}, state) do
    # Track pattern changes for incremental updates
    new_pending = [change | state.pending_changes] |> Enum.take(10_000)
    {:noreply, %{state | pending_changes: new_pending}}
  end
  
  # Private Functions
  
  defp init_stats do
    %{
      patterns_loaded: 0,
      patterns_persisted: 0,
      persist_operations: 0,
      last_persist_duration_ms: 0,
      total_persist_time_ms: 0,
      errors: 0
    }
  end
  
  defp load_current_version do
    case File.read(@version_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"version" => version}} -> version
          _ -> 1
        end
      _ -> 1
    end
  end
  
  defp save_current_version(version) do
    content = Jason.encode!(%{
      version: version,
      updated_at: DateTime.utc_now()
    })
    
    File.write!(@version_file, content)
  end
  
  defp perform_persistence(state) do
    start_time = System.monotonic_time(:millisecond)
    
    try do
      # Get all current patterns
      all_patterns = Patterns.export_all()
      
      # Persist to both database and files
      {:ok, db_count} = persist_to_database(all_patterns, state.current_version)
      {:ok, file_count} = persist_to_files(all_patterns, state.current_version)
      
      # Create backup
      create_backup(state.current_version)
      
      # Update version
      new_version = state.current_version + 1
      save_current_version(new_version)
      
      # Calculate duration
      duration = System.monotonic_time(:millisecond) - start_time
      
      # Update stats
      new_stats = state.persistence_stats
      |> Map.update(:patterns_persisted, 0, &(&1 + max(db_count, file_count)))
      |> Map.update(:persist_operations, 0, &(&1 + 1))
      |> Map.put(:last_persist_duration_ms, duration)
      |> Map.update(:total_persist_time_ms, 0, &(&1 + duration))
      
      Logger.info("💾 Persisted #{max(db_count, file_count)} patterns in #{duration}ms (version #{new_version})")
      
      new_state = %{state |
        last_persist_time: DateTime.utc_now(),
        pending_changes: [],
        current_version: new_version,
        persistence_stats: new_stats
      }
      
      {{:ok, max(db_count, file_count)}, new_state}
    rescue
      e ->
        Logger.error("Persistence failed: #{inspect(e)}")
        new_stats = Map.update(state.persistence_stats, :errors, 0, &(&1 + 1))
        {{:error, e}, %{state | persistence_stats: new_stats}}
    end
  end
  
  defp persist_to_database(patterns, version) do
    # Batch insert/update patterns
    timestamp = DateTime.utc_now() |> DateTime.truncate(:second)
    
    pattern_records = Enum.map(patterns, fn pattern ->
      %{
        input: pattern["input"],
        output: pattern["output"],
        confidence: pattern["confidence"],
        metadata: pattern["metadata"] || %{},
        usage_count: pattern["usage_count"] || 0,
        last_used: pattern["last_used"] || timestamp,
        version: version,
        checksum: calculate_checksum(pattern),
        inserted_at: timestamp,
        updated_at: timestamp
      }
    end)
    
    # Use upsert for efficiency
    {count, _} = Repo.insert_all(
      PatternRecord,
      pattern_records,
      on_conflict: {:replace, [:output, :confidence, :metadata, :usage_count, :last_used, :version, :checksum, :updated_at]},
      conflict_target: :input
    )
    
    {:ok, count}
  end
  
  defp persist_to_files(patterns, version) do
    # Split into chunks for manageable file sizes
    chunks = Enum.chunk_every(patterns, @chunk_size)
    
    # Save each chunk
    chunk_results = chunks
    |> Enum.with_index()
    |> Enum.map(fn {chunk, index} ->
      filename = Path.join(@pattern_dir, "patterns-chunk-#{index}.json")
      save_pattern_chunk(chunk, filename, version)
    end)
    
    # Save index file
    save_pattern_index(length(chunks), version)
    
    total_saved = Enum.sum(chunk_results)
    {:ok, total_saved}
  end
  
  defp save_pattern_chunk(patterns, filename, version) do
    content = %{
      version: version,
      count: length(patterns),
      patterns: patterns,
      checksum: calculate_chunk_checksum(patterns)
    }
    
    # Compress if large
    json_content = Jason.encode!(content)
    
    final_content = if byte_size(json_content) > 1_000_000 do
      :zlib.gzip(json_content)
    else
      json_content
    end
    
    File.write!(filename, final_content)
    length(patterns)
  end
  
  defp save_pattern_index(chunk_count, version) do
    index = %{
      version: version,
      chunk_count: chunk_count,
      created_at: DateTime.utc_now(),
      pattern_files: Enum.map(0..(chunk_count - 1), fn i ->
        "patterns-chunk-#{i}.json"
      end)
    }
    
    File.write!(
      Path.join(@pattern_dir, "index.json"),
      Jason.encode!(index)
    )
  end
  
  defp load_all_patterns do
    # Try loading from database first
    case load_from_database() do
      {:ok, patterns} when length(patterns) > 0 ->
        # Load into memory
        Patterns.load_patterns(patterns)
        {:ok, length(patterns)}
      
      _ ->
        # Fall back to file loading
        load_from_files()
    end
  end
  
  defp load_from_database do
    patterns = PatternRecord
    |> Repo.all()
    |> Enum.map(fn record ->
      %{
        "input" => record.input,
        "output" => record.output,
        "confidence" => record.confidence,
        "metadata" => record.metadata,
        "usage_count" => record.usage_count,
        "last_used" => record.last_used
      }
    end)
    
    {:ok, patterns}
  rescue
    _ -> {:error, :database_unavailable}
  end
  
  defp load_from_files do
    index_file = Path.join(@pattern_dir, "index.json")
    
    case File.read(index_file) do
      {:ok, content} ->
        {:ok, index} = Jason.decode(content)
        
        patterns = index["pattern_files"]
        |> Enum.flat_map(fn filename ->
          load_pattern_file(Path.join(@pattern_dir, filename))
        end)
        
        Patterns.load_patterns(patterns)
        {:ok, length(patterns)}
      
      _ ->
        # Try loading individual chunk files
        load_legacy_chunks()
    end
  end
  
  defp load_pattern_file(filepath) do
    case File.read(filepath) do
      {:ok, content} ->
        # Check if compressed
        decoded_content = case content do
          <<0x1F, 0x8B, _::binary>> -> # gzip magic number
            :zlib.gunzip(content)
          _ ->
            content
        end
        
        case Jason.decode(decoded_content) do
          {:ok, %{"patterns" => patterns}} -> patterns
          _ -> []
        end
      
      _ -> []
    end
  end
  
  defp load_legacy_chunks do
    # Load old-style chunk files
    pattern_files = File.ls!(@pattern_dir)
    |> Enum.filter(&String.starts_with?(&1, "patterns-chunk-"))
    |> Enum.sort()
    
    patterns = Enum.flat_map(pattern_files, fn filename ->
      load_pattern_file(Path.join(@pattern_dir, filename))
    end)
    
    if length(patterns) > 0 do
      Patterns.load_patterns(patterns)
      {:ok, length(patterns)}
    else
      {:ok, 0}
    end
  end
  
  defp create_backup(version) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    backup_name = "backup-v#{version}-#{timestamp}"
    backup_path = Path.join(@backup_dir, backup_name)
    
    File.mkdir_p!(backup_path)
    
    # Copy pattern files
    File.ls!(@pattern_dir)
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.each(fn filename ->
      source = Path.join(@pattern_dir, filename)
      dest = Path.join(backup_path, filename)
      File.copy!(source, dest)
    end)
    
    # Clean old backups (keep last 10)
    clean_old_backups()
  end
  
  defp clean_old_backups do
    backups = File.ls!(@backup_dir)
    |> Enum.filter(&File.dir?(Path.join(@backup_dir, &1)))
    |> Enum.sort()
    
    if length(backups) > 10 do
      backups
      |> Enum.take(length(backups) - 10)
      |> Enum.each(fn dir ->
        File.rm_rf!(Path.join(@backup_dir, dir))
      end)
    end
  end
  
  defp calculate_checksum(pattern) do
    content = "#{pattern["input"]}:#{pattern["output"]}:#{pattern["confidence"]}"
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower) |> String.slice(0..7)
  end
  
  defp calculate_chunk_checksum(patterns) do
    content = patterns
    |> Enum.map(&calculate_checksum/1)
    |> Enum.join("")
    
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower) |> String.slice(0..15)
  end
  
  defp increment_version(state) do
    new_version = state.current_version + 1
    save_current_version(new_version)
    %{state | current_version: new_version}
  end
  
  defp export_patterns_to_file(filename) do
    patterns = Patterns.export_all()
    
    content = %{
      version: 1,
      exported_at: DateTime.utc_now(),
      pattern_count: length(patterns),
      patterns: patterns
    }
    
    File.write(filename, Jason.encode!(content, pretty: true))
    {:ok, length(patterns)}
  rescue
    e -> {:error, e}
  end
  
  defp import_patterns_from_file(filename) do
    with {:ok, content} <- File.read(filename),
         {:ok, data} <- Jason.decode(content),
         patterns when is_list(patterns) <- Map.get(data, "patterns") do
      
      # Validate patterns
      valid_patterns = Enum.filter(patterns, &valid_pattern?/1)
      
      # Load into system
      Patterns.load_patterns(valid_patterns)
      
      # Persist to database
      persist_to_database(valid_patterns, data["version"] || 1)
      
      {:ok, length(valid_patterns)}
    else
      error -> {:error, error}
    end
  end
  
  defp valid_pattern?(pattern) do
    Map.has_key?(pattern, "input") and
    Map.has_key?(pattern, "output") and
    Map.has_key?(pattern, "confidence") and
    is_number(pattern["confidence"])
  end
end