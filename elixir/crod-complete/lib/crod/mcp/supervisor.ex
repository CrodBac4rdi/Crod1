defmodule Crod.MCP.Supervisor do
  @moduledoc """
  Supervisor for CROD MCP servers.
  Manages both meta-server and individual specialized servers.
  
  Supports two modes:
  1. Meta mode: Single entry point routing to specialized servers
  2. Multi mode: Direct access to individual specialized servers
  """
  
  use Supervisor
  require Logger
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    # Get MCP mode from environment or config
    mode = System.get_env("MCP_MODE", "both") |> String.to_atom()
    
    children = case mode do
      :none ->
        # No MCP servers
        Logger.info("MCP disabled (MCP_MODE=none)")
        []
        
      :simple ->
        # Simple server only
        Logger.info("Starting MCP in SIMPLE mode - basic functionality")
        simple_server_children()
        
      :meta ->
        # Only meta server (it internally routes to others)
        Logger.info("Starting MCP in META mode - single entry point")
        meta_server_children()
        
      :multi ->
        # Individual servers on different ports
        Logger.info("Starting MCP in MULTI mode - individual servers")
        multi_server_children()
        
      :both ->
        # Both architectures running simultaneously
        Logger.info("Starting MCP in BOTH mode - meta + individual servers")
        meta_server_children() ++ multi_server_children()
        
      _ ->
        Logger.warning("Unknown MCP_MODE: #{mode}, defaulting to :simple")
        simple_server_children()
    end
    
    # Always include the Hermes client for internal use
    all_children = [
      # Skip HermesClient for now - it's not a GenServer
      # {Crod.MCP.HermesClient, transport: {:stdio, []}}
    ] ++ children
    
    Supervisor.init(all_children, strategy: :one_for_one)
  end
  
  defp simple_server_children do
    transport = get_transport(:simple)
    
    [
      {Crod.MCP.SimpleServer, name: :mcp_simple, transport: transport}
    ]
  end
  
  defp meta_server_children do
    transport = get_transport(:meta)
    
    [
      # Use simple server for now
      {Crod.MCP.SimpleServer, name: :mcp_meta, transport: transport}
    ]
  end
  
  defp multi_server_children do
    [
      # Pattern server on port 8001
      {Crod.MCP.ServerWrapper, server_module: Crod.MCP.PatternServer, transport: get_transport(:pattern)},
      
      # Memory server on port 8002
      {Crod.MCP.ServerWrapper, server_module: Crod.MCP.MemoryServer, transport: get_transport(:memory)},
      
      # Neural server on port 8003
      {Crod.MCP.ServerWrapper, server_module: Crod.MCP.NeuralServer, transport: get_transport(:neural)},
      
      # Trinity server on port 8004
      {Crod.MCP.ServerWrapper, server_module: Crod.MCP.TrinityServer, transport: get_transport(:trinity)}
    ]
  end
  
  defp get_transport(server_type) do
    base_transport = System.get_env("MCP_TRANSPORT", "stdio")
    
    case {base_transport, server_type} do
      {"stdio", _} ->
        # STDIO transport for Claude integration
        {:stdio, []}
        
      {"http", :simple} ->
        # HTTP transport for simple server
        port = System.get_env("MCP_PORT", "8000") |> String.to_integer()
        {:http, [port: port]}
        
      {"http", :meta} ->
        # HTTP transport for meta server
        port = System.get_env("MCP_PORT", "8000") |> String.to_integer()
        {:http, [port: port]}
        
      {"http", :pattern} ->
        {:http, [port: 8001]}
        
      {"http", :memory} ->
        {:http, [port: 8002]}
        
      {"http", :neural} ->
        {:http, [port: 8003]}
        
      {"http", :trinity} ->
        {:http, [port: 8004]}
        
      {"sse", server_type} ->
        # Server-Sent Events transport
        port = get_sse_port(server_type)
        {:sse, [port: port]}
        
      _ ->
        # Default to STDIO
        {:stdio, []}
    end
  end
  
  defp get_sse_port(server_type) do
    case server_type do
      :meta -> 9000
      :pattern -> 9001
      :memory -> 9002
      :neural -> 9003
      :trinity -> 9004
    end
  end
  
  @doc """
  Get status of all MCP servers
  """
  def status do
    servers = [
      check_server(:meta, Crod.MCP.MetaServer),
      check_server(:pattern, Crod.MCP.PatternServer),
      check_server(:memory, Crod.MCP.MemoryServer),
      check_server(:neural, Crod.MCP.NeuralServer),
      check_server(:trinity, Crod.MCP.TrinityServer)
    ]
    
    %{
      mode: System.get_env("MCP_MODE", "both"),
      transport: System.get_env("MCP_TRANSPORT", "stdio"),
      servers: servers,
      timestamp: DateTime.utc_now()
    }
  end
  
  defp check_server(name, module) do
    case Process.whereis(module) do
      nil -> 
        %{name: name, status: :offline, module: module}
      pid -> 
        %{
          name: name,
          status: :online,
          module: module,
          pid: inspect(pid),
          info: Process.info(pid, [:message_queue_len, :memory])
        }
    end
  end
  
  @doc """
  Switch MCP mode at runtime
  """
  def switch_mode(new_mode) when new_mode in [:simple, :meta, :multi, :both] do
    Logger.info("Switching MCP mode to: #{new_mode}")
    
    # Stop current supervisor
    Supervisor.stop(__MODULE__)
    
    # Update environment
    System.put_env("MCP_MODE", to_string(new_mode))
    
    # Restart with new mode
    start_link([])
  end
  
  @doc """
  Hot reload a specific server
  """
  def reload_server(server_name) when server_name in [:pattern, :memory, :neural, :trinity] do
    module = case server_name do
      :pattern -> Crod.MCP.PatternServer
      :memory -> Crod.MCP.MemoryServer
      :neural -> Crod.MCP.NeuralServer
      :trinity -> Crod.MCP.TrinityServer
    end
    
    # Find and restart the child
    case Enum.find(Supervisor.which_children(__MODULE__), fn {id, _, _, _} -> 
      id == module 
    end) do
      {^module, pid, _, _} when is_pid(pid) ->
        Logger.info("Reloading server: #{server_name}")
        Supervisor.terminate_child(__MODULE__, module)
        Supervisor.restart_child(__MODULE__, module)
        {:ok, :reloaded}
        
      _ ->
        {:error, :not_found}
    end
  end
end