defmodule CROD.API.REST.Handler do
  @moduledoc """
  REST API handler for N2O integration
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle(request, state) do
    # Process REST request through N2O
    case request do
      %{method: "GET", path: path} ->
        handle_get(path, request, state)
      %{method: "POST", path: path, body: body} ->
        handle_post(path, body, state)
      _ ->
        {:error, "Method not supported"}
    end
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Register with N2O router
    CROD.Core.Router.register_handler(:api, :rest, __MODULE__)
    
    # Subscribe to REST-specific events
    CROD.Core.MessageBus.subscribe(:rest_events, self())
    
    {:ok, %{requests: 0}}
  end

  # Private functions

  defp handle_get(path, _request, _state) do
    # Route GET requests through N2O
    CROD.Core.MessageBus.publish(:api_request, %{
      type: :rest,
      method: :get,
      path: path
    })
    
    %{status: "ok", path: path}
  end

  defp handle_post(path, body, _state) do
    # Route POST requests through N2O
    CROD.Core.MessageBus.publish(:api_request, %{
      type: :rest,
      method: :post,
      path: path,
      body: body
    })
    
    %{status: "processing", path: path}
  end
end