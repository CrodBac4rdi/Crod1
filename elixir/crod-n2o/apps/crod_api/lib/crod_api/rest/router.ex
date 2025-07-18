defmodule CROD.API.REST.Router do
  @moduledoc """
  REST API Router - Traditional HTTP endpoints
  Communicates with neural layer via N2O
  """
  use Plug.Router

  plug Plug.Logger
  plug CORSPlug
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  # Health check
  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "ok", framework: "N2O-REST"}))
  end

  # Get CROD status via N2O
  get "/api/status" do
    # Query neural layer through N2O
    status = GenServer.call(CROD.Neural.Handler, {:status, %{}, %{}})
    
    send_resp(conn, 200, Jason.encode!(status))
  end

  # Process input through CROD
  post "/api/process" do
    input = conn.body_params["input"] || ""
    
    # Send to neural layer via N2O protocol
    result = GenServer.call(CROD.Neural.Handler, {:process, input, %{}})
    
    case result do
      {:broadcast, _topic, data} ->
        send_resp(conn, 200, Jason.encode!(data))
      data when is_map(data) ->
        send_resp(conn, 200, Jason.encode!(data))
      {:error, reason} ->
        send_resp(conn, 400, Jason.encode!(%{error: reason}))
    end
  end

  # Trigger trinity activation
  post "/api/trinity" do
    sequence = conn.body_params["sequence"] || []
    
    result = GenServer.call(CROD.Neural.Handler, {:trinity, sequence, %{}})
    
    case result do
      {:broadcast, _topic, data} ->
        send_resp(conn, 200, Jason.encode!(%{activated: true, data: data}))
      {:error, reason} ->
        send_resp(conn, 400, Jason.encode!(%{activated: false, error: reason}))
    end
  end

  # Learn new pattern
  post "/api/learn" do
    pattern = conn.body_params["pattern"]
    
    if pattern do
      result = GenServer.call(CROD.Neural.Handler, {:learn, pattern, %{}})
      send_resp(conn, 200, Jason.encode!(%{learned: true}))
    else
      send_resp(conn, 400, Jason.encode!(%{error: "Pattern required"}))
    end
  end

  # Catch all
  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end
end