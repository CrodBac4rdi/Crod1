defmodule CROD.Core.Application do
  @moduledoc """
  CROD Core Application - The N2O-based nervous system
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # N2O WebSocket server
      %{
        id: :n2o_server,
        start: {:n2o, :start_link, [
          [
            port: 8888,
            proto: CROD.Core.Protocol,
            routes: routes()
          ]
        ]}
      },
      
      # Core router
      {CROD.Core.Router, name: CROD.Core.Router},
      
      # Message bus
      {CROD.Core.MessageBus, name: CROD.Core.MessageBus}
    ]

    opts = [strategy: :one_for_one, name: CROD.Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp routes do
    [
      {"/ws/[...]", :n2o_cowboy, []}
    ]
  end
end