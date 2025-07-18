defmodule CROD.API.Application do
  @moduledoc """
  API layer application - manages REST, GraphQL, and other API frameworks
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # REST API server
      {Plug.Cowboy, 
        scheme: :http, 
        plug: CROD.API.REST.Router, 
        options: [port: 4001]
      },
      
      # API handlers that register with N2O
      {CROD.API.REST.Handler, name: CROD.API.REST.Handler},
      
      # Future: RIG, Sugar, Ash handlers
      # {CROD.API.RIG.Handler, name: CROD.API.RIG.Handler},
      # {CROD.API.Sugar.Handler, name: CROD.API.Sugar.Handler},
      # {CROD.API.Ash.Handler, name: CROD.API.Ash.Handler}
    ]

    opts = [strategy: :one_for_one, name: CROD.API.Supervisor]
    Supervisor.start_link(children, opts)
  end
end