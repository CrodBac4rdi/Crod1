defmodule CROD.Core.Router do
  @moduledoc """
  Central routing system for all CROD messages
  Routes messages to appropriate framework handlers
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route(category, action, payload, state) do
    GenServer.call(__MODULE__, {:route, category, action, payload, state})
  end

  def register_handler(category, framework, module) do
    GenServer.call(__MODULE__, {:register, category, framework, module})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      handlers: %{
        neural: %{
          default: CROD.Neural.Handler
        },
        api: %{
          rest: CROD.API.REST.Handler,
          rig: CROD.API.RIG.Handler,
          sugar: CROD.API.Sugar.Handler,
          ash: CROD.API.Ash.Handler
        },
        ui: %{
          phoenix: CROD.UI.Phoenix.Handler,
          nitro: CROD.UI.Nitro.Handler
        },
        mcp: %{
          default: CROD.MCP.Handler
        }
      },
      metrics: %{
        routed: 0,
        errors: 0
      }
    }}
  end

  @impl true
  def handle_call({:route, category, action, payload, state}, _from, router_state) do
    result = do_route(category, action, payload, state, router_state)
    new_state = update_metrics(router_state, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:register, category, framework, module}, _from, state) do
    new_handlers = put_in(state.handlers[category][framework], module)
    {:reply, :ok, %{state | handlers: new_handlers}}
  end

  # Private functions

  defp do_route(:neural, action, payload, conn_state, router_state) do
    handler = get_handler(router_state, :neural, :default)
    apply_handler(handler, action, [payload, conn_state])
  end

  defp do_route(:api, framework, request, conn_state, router_state) do
    handler = get_handler(router_state, :api, framework)
    apply_handler(handler, :handle, [request, conn_state])
  end

  defp do_route(:ui, framework, update, conn_state, router_state) do
    handler = get_handler(router_state, :ui, framework)
    apply_handler(handler, :update, [update, conn_state])
  end

  defp do_route(:mcp, tool, params, conn_state, router_state) do
    handler = get_handler(router_state, :mcp, :default)
    apply_handler(handler, :call, [tool, params, conn_state])
  end

  defp get_handler(state, category, framework) do
    get_in(state.handlers, [category, framework]) || 
      raise "No handler registered for #{category}/#{framework}"
  end

  defp apply_handler(module, function, args) do
    try do
      apply(module, function, args)
    rescue
      error ->
        {:error, Exception.format(:error, error, __STACKTRACE__)}
    end
  end

  defp update_metrics(state, {:error, _}) do
    update_in(state.metrics.errors, &(&1 + 1))
  end
  defp update_metrics(state, _) do
    update_in(state.metrics.routed, &(&1 + 1))
  end
end