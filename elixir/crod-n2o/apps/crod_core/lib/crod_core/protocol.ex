defmodule CROD.Core.Protocol do
  @moduledoc """
  N2O Protocol implementation for CROD
  Handles all message routing between frameworks
  """
  
  require N2O
  
  # Message types
  @type crod_msg :: 
    {:neural, atom(), any()} |
    {:api, atom(), any()} |
    {:ui, atom(), any()} |
    {:mcp, atom(), any()} |
    {:system, atom(), any()}

  @doc """
  Initialize protocol for new connection
  """
  def init(state) do
    {:ok, Map.merge(state, %{
      connected_at: DateTime.utc_now(),
      subscriptions: [],
      framework: detect_framework(state)
    })}
  end

  @doc """
  Main message handler - routes messages to appropriate framework
  """
  def info({:neural, action, payload}, state) do
    # Route to neural layer
    result = CROD.Core.Router.route(:neural, action, payload, state)
    broadcast_if_needed(result, state)
    {:ok, update_state(state, result)}
  end

  def info({:api, framework, request}, state) do
    # Route to API framework (REST, RIG, Sugar, Ash)
    result = CROD.Core.Router.route(:api, framework, request, state)
    {:ok, state}
  end

  def info({:ui, framework, update}, state) do
    # Route to UI framework (Phoenix, Nitro)
    result = CROD.Core.Router.route(:ui, framework, update, state)
    {:ok, state}
  end

  def info({:mcp, tool, params}, state) do
    # Handle MCP tool calls
    result = CROD.Core.Router.route(:mcp, tool, params, state)
    {:ok, state}
  end

  def info({:subscribe, topic}, state) do
    # Subscribe to topic
    new_state = Map.update(state, :subscriptions, [topic], &[topic | &1])
    CROD.Core.MessageBus.subscribe(topic, self())
    {:ok, new_state}
  end

  def info({:text, data}, state) do
    # Handle raw text input - process through neural
    info({:neural, :process, data}, state)
  end

  def info(message, state) do
    # Unknown message
    IO.warn("Unknown message: #{inspect(message)}")
    {:ok, state}
  end

  # Private functions

  defp detect_framework(state) do
    # Detect which framework is connecting based on headers/params
    cond do
      state[:headers]["user-agent"] =~ "MCP" -> :mcp
      state[:headers]["x-framework"] -> String.to_atom(state[:headers]["x-framework"])
      true -> :unknown
    end
  end

  defp broadcast_if_needed({:broadcast, topic, data}, state) do
    CROD.Core.MessageBus.broadcast(topic, data, exclude: [self()])
  end
  defp broadcast_if_needed(_, _), do: :ok

  defp update_state(state, {:state_update, updates}) do
    Map.merge(state, updates)
  end
  defp update_state(state, _), do: state
end