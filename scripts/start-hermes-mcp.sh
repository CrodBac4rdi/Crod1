#!/usr/bin/env bash
# Start Hermes MCP Server for CROD Neural System

cd /home/bacardi/crodidocker/elixir/crod-complete

# Start the Elixir MCP server
exec elixir --no-halt -S mix run --no-start -e "
  Application.ensure_all_started(:crod)
  Crod.MCP.StdioStart.start()
"