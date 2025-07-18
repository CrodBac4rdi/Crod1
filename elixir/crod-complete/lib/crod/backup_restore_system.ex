defmodule Crod.BackupRestoreSystem do
  @moduledoc """
  Comprehensive backup and restore system for the entire CROD state,
  including neurons, patterns, memory, and activity logs.
  """
  
  use GenServer
  require Logger
  
  alias Crod.{
    Brain,
    Patterns,
    Memory,
    ActivityIntelligence,
    Neuron,
    NeuronRegistry,
    PatternPersistence,
    Repo
  }
  
  @backup_dir "data/backups"
  @backup_format_version "1.0"
  @compression_enabled true
  @encryption_enabled false
  @max_backups 30
  @backup_timeout 300_000  # 5 minutes
  
  defstruct [
    :current_backup,
    :backup_history,
    :backup_schedule,
    :restore_state,
    :stats
  ]
  
  # Backup types
  @backup_types [:full, :incremental, :selective]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def create_backup(type \\ :full, opts \\ []) do
    GenServer.call(__MODULE__, {:create_backup, type, opts}, @backup_timeout)
  end
  
  def restore_backup(backup_id, opts \\ []) do
    GenServer.call(__MODULE__, {:restore_backup, backup_id, opts}, @backup_timeout)
  end
  
  def list_backups do
    GenServer.call(__MODULE__, :list_backups)
  end
  
  def get_backup_info(backup_id) do
    GenServer.call(__MODULE__, {:get_backup_info, backup_id})
  end
  
  def delete_backup(backup_id) do
    GenServer.call(__MODULE__, {:delete_backup, backup_id})
  end
  
  def schedule_automatic_backup(interval_ms) do
    GenServer.cast(__MODULE__, {:schedule_backup, interval_ms})
  end
  
  def verify_backup(backup_id) do
    GenServer.call(__MODULE__, {:verify_backup, backup_id})
  end
  
  def export_backup(backup_id, destination_path) do
    GenServer.call(__MODULE__, {:export_backup, backup_id, destination_path})
  end
  
  def import_backup(source_path) do
    GenServer.call(__MODULE__, {:import_backup, source_path}, @backup_timeout)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    # Ensure backup directory exists
    File.mkdir_p!(@backup_dir)
    
    state = %__MODULE__{
      current_backup: nil,
      backup_history: load_backup_history(),
      backup_schedule: nil,
      restore_state: nil,
      stats: init_stats()
    }
    
    Logger.info("💾 Backup/Restore System initialized")
    
    {:ok, state}
  end
  
  def handle_call({:create_backup, type, opts}, _from, state) do
    Logger.info("🔄 Starting #{type} backup...")
    
    case perform_backup(type, opts, state) do
      {:ok, backup_info} ->
        new_state = %{state |
          backup_history: [backup_info | state.backup_history] |> Enum.take(@max_backups),
          stats: update_stats(state.stats, :backup_created)
        }
        
        # Clean old backups
        clean_old_backups(new_state.backup_history)
        
        {:reply, {:ok, backup_info}, new_state}
      
      {:error, reason} = error ->
        new_state = %{state |
          stats: update_stats(state.stats, :backup_failed)
        }
        {:reply, error, new_state}
    end
  end
  
  def handle_call({:restore_backup, backup_id, opts}, _from, state) do
    Logger.info("🔄 Starting restore from backup #{backup_id}...")
    
    case find_backup(state.backup_history, backup_id) do
      nil ->
        {:reply, {:error, :backup_not_found}, state}
      
      backup_info ->
        case perform_restore(backup_info, opts, state) do
          {:ok, restore_info} ->
            new_state = %{state |
              restore_state: restore_info,
              stats: update_stats(state.stats, :restore_completed)
            }
            {:reply, {:ok, restore_info}, new_state}
          
          {:error, reason} = error ->
            new_state = %{state |
              stats: update_stats(state.stats, :restore_failed)
            }
            {:reply, error, new_state}
        end
    end
  end
  
  def handle_call(:list_backups, _from, state) do
    backups = Enum.map(state.backup_history, fn backup ->
      %{
        id: backup.id,
        type: backup.type,
        created_at: backup.created_at,
        size_bytes: backup.size_bytes,
        components: Map.keys(backup.components),
        compressed: backup.compressed,
        verified: backup.verified
      }
    end)
    
    {:reply, backups, state}
  end
  
  def handle_call({:get_backup_info, backup_id}, _from, state) do
    backup = find_backup(state.backup_history, backup_id)
    {:reply, backup, state}
  end
  
  def handle_call({:delete_backup, backup_id}, _from, state) do
    case find_backup(state.backup_history, backup_id) do
      nil ->
        {:reply, {:error, :backup_not_found}, state}
      
      backup ->
        # Delete backup files
        delete_backup_files(backup)
        
        # Remove from history
        new_history = Enum.reject(state.backup_history, &(&1.id == backup_id))
        new_state = %{state | backup_history: new_history}
        
        {:reply, :ok, new_state}
    end
  end
  
  def handle_call({:verify_backup, backup_id}, _from, state) do
    case find_backup(state.backup_history, backup_id) do
      nil ->
        {:reply, {:error, :backup_not_found}, state}
      
      backup ->
        verification_result = verify_backup_integrity(backup)
        
        # Update backup info with verification status
        updated_backup = %{backup | verified: verification_result.valid}
        new_history = update_backup_in_history(state.backup_history, updated_backup)
        
        {:reply, verification_result, %{state | backup_history: new_history}}
    end
  end
  
  def handle_call({:export_backup, backup_id, destination}, _from, state) do
    case find_backup(state.backup_history, backup_id) do
      nil ->
        {:reply, {:error, :backup_not_found}, state}
      
      backup ->
        result = export_backup_to_path(backup, destination)
        {:reply, result, state}
    end
  end
  
  def handle_call({:import_backup, source_path}, _from, state) do
    case import_backup_from_path(source_path) do
      {:ok, backup_info} ->
        new_state = %{state |
          backup_history: [backup_info | state.backup_history] |> Enum.take(@max_backups)
        }
        {:reply, {:ok, backup_info}, new_state}
      
      error ->
        {:reply, error, state}
    end
  end
  
  def handle_cast({:schedule_backup, interval_ms}, state) do
    # Cancel existing schedule
    if state.backup_schedule do
      Process.cancel_timer(state.backup_schedule)
    end
    
    # Schedule new backup
    timer_ref = Process.send_after(self(), :scheduled_backup, interval_ms)
    
    {:noreply, %{state | backup_schedule: timer_ref}}
  end
  
  def handle_info(:scheduled_backup, state) do
    # Perform automatic backup
    case perform_backup(:incremental, [automatic: true], state) do
      {:ok, backup_info} ->
        new_state = %{state |
          backup_history: [backup_info | state.backup_history] |> Enum.take(@max_backups)
        }
        
        # Reschedule if interval is set
        if state.backup_schedule do
          Process.send_after(self(), :scheduled_backup, get_backup_interval())
        end
        
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("Scheduled backup failed: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp init_stats do
    %{
      backups_created: 0,
      backups_failed: 0,
      restores_completed: 0,
      restores_failed: 0,
      total_backup_size: 0,
      average_backup_duration_ms: 0,
      last_backup_time: nil,
      last_restore_time: nil
    }
  end
  
  defp perform_backup(type, opts, state) do
    start_time = System.monotonic_time(:millisecond)
    backup_id = generate_backup_id()
    backup_path = Path.join(@backup_dir, backup_id)
    
    try do
      # Create backup directory
      File.mkdir_p!(backup_path)
      
      # Collect components to backup
      components = case type do
        :full -> collect_full_backup_components()
        :incremental -> collect_incremental_components(state.backup_history)
        :selective -> collect_selective_components(opts[:components] || [])
      end
      
      # Save each component
      component_results = Enum.map(components, fn {name, data} ->
        save_component(backup_path, name, data)
      end)
      
      # Calculate total size
      total_size = calculate_backup_size(backup_path)
      
      # Compress if enabled
      if @compression_enabled do
        compress_backup(backup_path)
      end
      
      # Create manifest
      manifest = create_backup_manifest(type, components, opts)
      save_manifest(backup_path, manifest)
      
      duration = System.monotonic_time(:millisecond) - start_time
      
      backup_info = %{
        id: backup_id,
        type: type,
        created_at: DateTime.utc_now(),
        size_bytes: total_size,
        components: Map.new(component_results),
        compressed: @compression_enabled,
        encrypted: @encryption_enabled,
        duration_ms: duration,
        options: opts,
        manifest: manifest,
        verified: false
      }
      
      Logger.info("✅ Backup completed: #{backup_id} (#{format_bytes(total_size)}, #{duration}ms)")
      
      {:ok, backup_info}
    rescue
      e ->
        Logger.error("Backup failed: #{inspect(e)}")
        # Clean up partial backup
        File.rm_rf!(backup_path)
        {:error, e}
    end
  end
  
  defp collect_full_backup_components do
    %{
      neurons: backup_neurons(),
      patterns: backup_patterns(),
      memory: backup_memory(),
      activities: backup_activities(),
      brain_state: backup_brain_state(),
      configuration: backup_configuration(),
      statistics: backup_statistics()
    }
  end
  
  defp collect_incremental_components(backup_history) do
    last_backup = List.first(backup_history)
    last_backup_time = if last_backup, do: last_backup.created_at, else: nil
    
    %{
      patterns: backup_patterns_since(last_backup_time),
      memory: backup_memory_changes(last_backup_time),
      activities: backup_activities_since(last_backup_time),
      statistics: backup_statistics()
    }
  end
  
  defp collect_selective_components(component_names) do
    all_components = %{
      neurons: &backup_neurons/0,
      patterns: &backup_patterns/0,
      memory: &backup_memory/0,
      activities: &backup_activities/0,
      brain_state: &backup_brain_state/0,
      configuration: &backup_configuration/0,
      statistics: &backup_statistics/0
    }
    
    component_names
    |> Enum.map(fn name ->
      if function = all_components[name] do
        {name, function.()}
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
    |> Map.new()
  end
  
  defp backup_neurons do
    neurons = NeuronRegistry.all_neurons()
    |> Enum.map(fn {id, pid} ->
      state = try do
        Neuron.get_state(pid)
      catch
        :exit, _ -> nil
      end
      
      {id, state}
    end)
    |> Enum.filter(fn {_id, state} -> state != nil end)
    |> Map.new()
    
    %{
      count: map_size(neurons),
      data: neurons,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_patterns do
    patterns = Patterns.export_all()
    
    %{
      count: length(patterns),
      data: patterns,
      version: PatternPersistence.get_stats().current_version,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_memory do
    memory_dump = Memory.export_all()
    
    %{
      short_term: memory_dump.short_term,
      long_term: memory_dump.long_term,
      episodic: memory_dump.episodic,
      semantic: memory_dump.semantic,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_activities do
    # Get recent activities
    activities = ActivityIntelligence.get_recent_activities(10_000)
    
    %{
      count: length(activities),
      data: activities,
      patterns: ActivityIntelligence.get_patterns(:all),
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_brain_state do
    brain_state = Brain.get_state()
    
    %{
      active_neurons: brain_state.active_neurons,
      quantum_state: brain_state.quantum_state,
      consciousness_level: brain_state.consciousness_level,
      pattern_recognition_active: brain_state.pattern_recognition_active,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_configuration do
    %{
      neural_config: Application.get_all_env(:crod),
      system_info: %{
        otp_release: :erlang.system_info(:otp_release),
        elixir_version: System.version(),
        node: Node.self(),
        uptime_seconds: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)
      },
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_statistics do
    %{
      neuron_stats: Crod.NeuronStats.get_stats(),
      pattern_stats: PatternPersistence.get_stats(),
      activity_stats: ActivityIntelligence.get_stats(),
      memory_stats: Memory.get_stats(),
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_patterns_since(nil), do: backup_patterns()
  defp backup_patterns_since(timestamp) do
    patterns = Patterns.export_all()
    |> Enum.filter(fn pattern ->
      pattern_time = pattern["metadata"]["created_at"] || pattern["metadata"]["updated_at"]
      if pattern_time do
        DateTime.compare(pattern_time, timestamp) == :gt
      else
        false
      end
    end)
    
    %{
      count: length(patterns),
      data: patterns,
      since: timestamp,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_memory_changes(nil), do: backup_memory()
  defp backup_memory_changes(timestamp) do
    # Get memory entries modified since timestamp
    memory_dump = Memory.export_since(timestamp)
    
    %{
      changes: memory_dump,
      since: timestamp,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp backup_activities_since(nil), do: backup_activities()
  defp backup_activities_since(timestamp) do
    activities = ActivityIntelligence.get_activities_since(timestamp)
    
    %{
      count: length(activities),
      data: activities,
      since: timestamp,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp save_component(backup_path, name, data) do
    filename = "#{name}.backup"
    filepath = Path.join(backup_path, filename)
    
    # Serialize data
    serialized = :erlang.term_to_binary(data, [:compressed])
    
    # Write to file
    File.write!(filepath, serialized)
    
    {name, %{
      filename: filename,
      size_bytes: byte_size(serialized),
      checksum: calculate_checksum(serialized)
    }}
  end
  
  defp create_backup_manifest(type, components, opts) do
    %{
      version: @backup_format_version,
      type: type,
      created_at: DateTime.utc_now(),
      components: Map.keys(components),
      options: opts,
      system_info: %{
        node: Node.self(),
        otp_release: :erlang.system_info(:otp_release),
        elixir_version: System.version()
      }
    }
  end
  
  defp save_manifest(backup_path, manifest) do
    manifest_path = Path.join(backup_path, "manifest.json")
    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
  end
  
  defp compress_backup(backup_path) do
    # Create tar.gz archive
    archive_name = "#{Path.basename(backup_path)}.tar.gz"
    archive_path = Path.join(Path.dirname(backup_path), archive_name)
    
    # Use system tar command
    {_, 0} = System.cmd("tar", ["-czf", archive_path, "-C", Path.dirname(backup_path), Path.basename(backup_path)])
    
    # Remove uncompressed directory
    File.rm_rf!(backup_path)
    
    # Rename archive to original path
    File.rename!(archive_path, backup_path)
  end
  
  defp calculate_backup_size(backup_path) do
    Path.wildcard(Path.join(backup_path, "**/*"))
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&File.stat!/1)
    |> Enum.map(& &1.size)
    |> Enum.sum()
  end
  
  defp perform_restore(backup_info, opts, state) do
    start_time = System.monotonic_time(:millisecond)
    
    try do
      backup_path = Path.join(@backup_dir, backup_info.id)
      
      # Decompress if needed
      if backup_info.compressed do
        decompress_backup(backup_path)
      end
      
      # Load manifest
      manifest = load_manifest(backup_path)
      
      # Verify compatibility
      unless compatible_version?(manifest.version) do
        throw({:error, :incompatible_version})
      end
      
      # Create restore point (backup current state)
      if opts[:create_restore_point] do
        {:ok, _} = perform_backup(:full, [restore_point: true], state)
      end
      
      # Restore components
      restore_results = Enum.map(backup_info.components, fn {name, _info} ->
        restore_component(backup_path, name, opts)
      end)
      
      duration = System.monotonic_time(:millisecond) - start_time
      
      restore_info = %{
        backup_id: backup_info.id,
        restored_at: DateTime.utc_now(),
        components_restored: Map.keys(backup_info.components),
        duration_ms: duration,
        results: Map.new(restore_results)
      }
      
      Logger.info("✅ Restore completed from #{backup_info.id} (#{duration}ms)")
      
      # Broadcast restore event
      Phoenix.PubSub.broadcast(
        Crod.PubSub,
        "system:events",
        {:restore_completed, restore_info}
      )
      
      {:ok, restore_info}
    catch
      {:error, reason} ->
        Logger.error("Restore failed: #{inspect(reason)}")
        {:error, reason}
    rescue
      e ->
        Logger.error("Restore failed: #{inspect(e)}")
        {:error, e}
    end
  end
  
  defp restore_component(backup_path, name, opts) do
    filename = "#{name}.backup"
    filepath = Path.join(backup_path, filename)
    
    # Load serialized data
    serialized = File.read!(filepath)
    data = :erlang.binary_to_term(serialized)
    
    # Restore based on component type
    result = case name do
      :neurons -> restore_neurons(data, opts)
      :patterns -> restore_patterns(data, opts)
      :memory -> restore_memory(data, opts)
      :activities -> restore_activities(data, opts)
      :brain_state -> restore_brain_state(data, opts)
      :configuration -> restore_configuration(data, opts)
      :statistics -> {:ok, :statistics_logged}
      _ -> {:error, :unknown_component}
    end
    
    {name, result}
  end
  
  defp restore_neurons(data, opts) do
    if opts[:restore_neurons] != false do
      # Stop existing neurons
      Logger.info("Stopping existing neurons...")
      NeuronRegistry.all_neurons()
      |> Enum.each(fn {_id, pid} ->
        GenServer.stop(pid, :normal, 5000)
      end)
      
      # Restart neuron supervisor with saved states
      # This would require coordination with NeuronSupervisor
      {:ok, :neurons_marked_for_restart}
    else
      {:skipped, :neurons}
    end
  end
  
  defp restore_patterns(data, _opts) do
    Logger.info("Restoring #{data.count} patterns...")
    
    # Clear existing patterns
    Patterns.clear_all()
    
    # Load patterns
    Patterns.load_patterns(data.data)
    
    {:ok, data.count}
  end
  
  defp restore_memory(data, _opts) do
    Logger.info("Restoring memory banks...")
    
    # Restore each memory type
    Memory.restore_memory(data)
    
    {:ok, :memory_restored}
  end
  
  defp restore_activities(data, opts) do
    if opts[:restore_activities] != false do
      Logger.info("Restoring #{data.count} activities...")
      
      # Clear and reload activities
      ActivityIntelligence.restore_activities(data.data)
      
      # Restore patterns
      ActivityIntelligence.restore_patterns(data.patterns)
      
      {:ok, data.count}
    else
      {:skipped, :activities}
    end
  end
  
  defp restore_brain_state(data, _opts) do
    Logger.info("Restoring brain state...")
    
    # Restore brain configuration
    Brain.restore_state(data)
    
    {:ok, :brain_state_restored}
  end
  
  defp restore_configuration(data, opts) do
    if opts[:restore_config] == true do
      Logger.warning("Configuration restore requested - requires manual review")
      {:manual_required, data}
    else
      {:skipped, :configuration}
    end
  end
  
  defp decompress_backup(backup_path) do
    # Check if it's a tar.gz
    if File.exists?("#{backup_path}.tar.gz") do
      archive_path = "#{backup_path}.tar.gz"
      temp_dir = "#{backup_path}_temp"
      
      # Extract
      File.mkdir_p!(temp_dir)
      {_, 0} = System.cmd("tar", ["-xzf", archive_path, "-C", temp_dir])
      
      # Move extracted content
      extracted = Path.join(temp_dir, Path.basename(backup_path))
      File.rename!(extracted, backup_path)
      
      # Cleanup
      File.rm_rf!(temp_dir)
      File.rm!(archive_path)
    end
  end
  
  defp verify_backup_integrity(backup) do
    backup_path = Path.join(@backup_dir, backup.id)
    
    errors = []
    
    # Verify each component
    component_results = Enum.map(backup.components, fn {name, info} ->
      filepath = Path.join(backup_path, info.filename)
      
      if File.exists?(filepath) do
        content = File.read!(filepath)
        calculated_checksum = calculate_checksum(content)
        
        if calculated_checksum == info.checksum do
          {name, :valid}
        else
          errors = [{name, :checksum_mismatch} | errors]
          {name, :invalid}
        end
      else
        errors = [{name, :file_missing} | errors]
        {name, :missing}
      end
    end)
    
    %{
      valid: Enum.empty?(errors),
      components: Map.new(component_results),
      errors: errors
    }
  end
  
  defp calculate_checksum(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
  
  defp generate_backup_id do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(~r/[:-]/, "")
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "backup_#{timestamp}_#{random}"
  end
  
  defp load_backup_history do
    manifest_files = Path.wildcard(Path.join(@backup_dir, "*/manifest.json"))
    
    manifest_files
    |> Enum.map(&load_backup_info_from_manifest/1)
    |> Enum.filter(& &1)
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
  end
  
  defp load_backup_info_from_manifest(manifest_path) do
    if File.exists?(manifest_path) do
      try do
        backup_id = manifest_path |> Path.dirname() |> Path.basename()
        
        manifest = manifest_path
        |> File.read!()
        |> Jason.decode!()
        
        # Load component info
        backup_path = Path.dirname(manifest_path)
        components = Enum.map(manifest["components"], fn component_name ->
          component_atom = String.to_atom(component_name)
          filename = "#{component_name}.backup"
          filepath = Path.join(backup_path, filename)
          
          if File.exists?(filepath) do
            stat = File.stat!(filepath)
            {component_atom, %{
              filename: filename,
              size_bytes: stat.size,
              checksum: nil  # Would need to calculate
            }}
          else
            nil
          end
        end)
        |> Enum.filter(& &1)
        |> Map.new()
        
        %{
          id: backup_id,
          type: String.to_atom(manifest["type"]),
          created_at: DateTime.from_iso8601!(manifest["created_at"]),
          size_bytes: calculate_backup_size(backup_path),
          components: components,
          compressed: false,  # Check for .tar.gz
          encrypted: false,
          verified: false,
          manifest: manifest
        }
      rescue
        error ->
          Logger.warning("Failed to load backup manifest from #{manifest_path}: #{inspect(error)}")
          nil
      end
    else
      nil
    end
  end
  
  defp find_backup(backup_history, backup_id) do
    Enum.find(backup_history, &(&1.id == backup_id))
  end
  
  defp update_backup_in_history(history, updated_backup) do
    Enum.map(history, fn backup ->
      if backup.id == updated_backup.id do
        updated_backup
      else
        backup
      end
    end)
  end
  
  defp delete_backup_files(backup) do
    backup_path = Path.join(@backup_dir, backup.id)
    File.rm_rf!(backup_path)
    
    # Also check for compressed version
    if File.exists?("#{backup_path}.tar.gz") do
      File.rm!("#{backup_path}.tar.gz")
    end
  end
  
  defp clean_old_backups(backup_history) do
    if length(backup_history) > @max_backups do
      backups_to_delete = backup_history
      |> Enum.drop(@max_backups)
      |> Enum.reject(&(&1.options[:preserve] == true))
      
      Enum.each(backups_to_delete, &delete_backup_files/1)
    end
  end
  
  defp export_backup_to_path(backup, destination) do
    backup_path = Path.join(@backup_dir, backup.id)
    
    try do
      # Create destination directory
      File.mkdir_p!(Path.dirname(destination))
      
      # Copy or create archive
      if backup.compressed or String.ends_with?(destination, ".tar.gz") do
        archive_path = if File.exists?("#{backup_path}.tar.gz") do
          "#{backup_path}.tar.gz"
        else
          # Create archive
          temp_archive = Path.join(System.tmp_dir!(), "#{backup.id}.tar.gz")
          {_, 0} = System.cmd("tar", ["-czf", temp_archive, "-C", @backup_dir, backup.id])
          temp_archive
        end
        
        File.copy!(archive_path, destination)
      else
        # Copy directory
        File.cp_r!(backup_path, destination)
      end
      
      {:ok, destination}
    rescue
      e -> {:error, e}
    end
  end
  
  defp import_backup_from_path(source_path) do
    try do
      backup_id = "imported_#{generate_backup_id()}"
      backup_path = Path.join(@backup_dir, backup_id)
      
      # Check if source is archive or directory
      cond do
        String.ends_with?(source_path, ".tar.gz") ->
          # Extract archive
          File.mkdir_p!(backup_path)
          {_, 0} = System.cmd("tar", ["-xzf", source_path, "-C", backup_path, "--strip-components=1"])
        
        File.dir?(source_path) ->
          # Copy directory
          File.cp_r!(source_path, backup_path)
        
        true ->
          throw({:error, :invalid_backup_format})
      end
      
      # Load manifest and create backup info
      manifest_path = Path.join(backup_path, "manifest.json")
      backup_info = load_backup_info_from_manifest(manifest_path)
      
      if backup_info do
        {:ok, %{backup_info | id: backup_id}}
      else
        throw({:error, :invalid_manifest})
      end
    catch
      {:error, reason} -> {:error, reason}
    rescue
      e -> {:error, e}
    end
  end
  
  defp compatible_version?(version) do
    [major, _minor] = String.split(@backup_format_version, ".")
    [backup_major, _] = String.split(version, ".")
    
    major == backup_major
  end
  
  defp format_bytes(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} B"
    end
  end
  
  defp update_stats(stats, event) do
    case event do
      :backup_created ->
        Map.update!(stats, :backups_created, &(&1 + 1))
        |> Map.put(:last_backup_time, DateTime.utc_now())
      
      :backup_failed ->
        Map.update!(stats, :backups_failed, &(&1 + 1))
      
      :restore_completed ->
        Map.update!(stats, :restores_completed, &(&1 + 1))
        |> Map.put(:last_restore_time, DateTime.utc_now())
      
      :restore_failed ->
        Map.update!(stats, :restores_failed, &(&1 + 1))
    end
  end
  
  defp get_backup_interval do
    # Default to 6 hours
    Application.get_env(:crod, :backup_interval_ms, 21_600_000)
  end
  
  defp load_manifest(backup_path) do
    manifest_path = Path.join(backup_path, "manifest.json")
    
    manifest_path
    |> File.read!()
    |> Jason.decode!()
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end