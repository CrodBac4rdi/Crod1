defmodule CrodWeb.Router do
  use CrodWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CrodWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Claude-CROD Bridge API
  scope "/api", CrodWeb do
    pipe_through :api
    
    post "/claude/process", ClaudeBridgeController, :process
    post "/brain/process", BrainController, :process
    post "/brain/trinity", BrainController, :trinity
    get "/brain/state", BrainController, :state
  end

  # Health check endpoint
  scope "/", CrodWeb do
    get "/health", HealthController, :index
  end

  scope "/", CrodWeb do
    pipe_through :browser

    # Landing Page - Main Entry Point
    live "/", LandingLive, :index
    
    # New Main Interface - Clean Streamlit Style (PRIMARY)
    live "/main", MainLive, :index
    
    # Neural Dashboard - Real-time CROD visualization
    live "/neural-dashboard", NeuralDashboardLive, :index
    
    # All old routes now redirect to main
    live "/science", MainLive, :index
    live "/control", MainLive, :index
    live "/dashboard", MainLive, :index
    live "/neural", MainLive, :index
    live "/patterns", MainLive, :index
    live "/memory", MainLive, :index
    live "/mcp", MainLive, :index
    live "/monitoring", MainLive, :index
    live "/settings", MainLive, :index
    live "/brain", MainLive, :index
    live "/playground", MainLive, :index
    live "/collab", MainLive, :index
    live "/unified", MainLive, :index
    
    # Keep old controller route for compatibility
    get "/old", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", CrodWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:crod, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CrodWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
