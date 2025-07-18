defmodule Crod.MCP.Security do
  @moduledoc """
  Security for VS Code integration.
  Handles authentication and secure WebSocket connections.
  """
  use GenServer
  require Logger

  @token_file "~/.crod/auth.token"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def validate_token(token) do
    GenServer.call(__MODULE__, {:validate_token, token})
  end

  def generate_token do
    GenServer.call(__MODULE__, :generate_token)
  end

  @impl true
  def init(_opts) do
    # Ensure token directory exists
    token_path = Path.expand(@token_file)
    token_dir = Path.dirname(token_path)
    File.mkdir_p!(token_dir)
    
    # Load or generate token
    token = case File.read(token_path) do
      {:ok, existing_token} -> 
        String.trim(existing_token)
      {:error, _} ->
        new_token = generate_secure_token()
        File.write!(token_path, new_token)
        Logger.info("🔐 Generated new VS Code auth token")
        new_token
    end
    
    {:ok, %{token: token, connections: %{}}}
  end

  @impl true
  def handle_call({:validate_token, token}, {pid, _ref}, state) do
    valid = token == state.token
    
    if valid do
      # Track connection
      connections = Map.put(state.connections, pid, %{
        connected_at: DateTime.utc_now(),
        last_activity: DateTime.utc_now()
      })
      
      {:reply, {:ok, :authenticated}, %{state | connections: connections}}
    else
      Logger.warn("🚫 Invalid VS Code token attempt")
      {:reply, {:error, :invalid_token}, state}
    end
  end

  @impl true
  def handle_call(:generate_token, _from, state) do
    {:reply, state.token, state}
  end

  defp generate_secure_token do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end