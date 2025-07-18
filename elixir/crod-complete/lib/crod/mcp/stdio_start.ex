defmodule Crod.MCP.StdioStart do
  @moduledoc """
  Starts CROD with Hermes MCP STDIO transport
  """
  
  def start do
    # Start the application first
    {:ok, _} = Application.ensure_all_started(:crod)
    
    # Start Hermes MCP application
    {:ok, _} = Application.ensure_all_started(:hermes_mcp)
    
    # Start the Hermes MCP server with STDIO transport
    {:ok, _server} = Hermes.Server.start_link(Crod.MCP.SimpleWorkingServer, :ok, transport: :stdio)
    
    # Keep running
    Process.sleep(:infinity)
  end
end