defmodule Crod.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    base_children = [
      CrodWeb.Telemetry,
      Crod.Repo,
      {DNSCluster, query: Application.get_env(:crod, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Crod.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Crod.Finch},
      
      # Neural Enhancement - Registry for neurons
      {Registry, keys: :unique, name: Crod.NeuronRegistry},
      
      # Caching layer - must start before Brain
      Crod.PatternCache,
      
      # Background job processing - disabled for now
      # {Oban, Application.fetch_env!(:crod, Oban)},
      
      # CROD Core Services
      Crod.MCP.Security,
      
      # Neural Supervision Tree (NEW OTP ARCHITECTURE)
      Crod.Supervision.NeuralClusterSupervisor,
      
      Crod.Brain,
      
      # Multi-Brain Hub (2025 Architecture)
      # Crod.MessageBus,  # Temporarily disabled - needs Gnat dependency
      {DynamicSupervisor, strategy: :one_for_one, name: Crod.DynamicSupervisor},
      Crod.MultiBrainHub,
      
      # Unified Brain Orchestrator (THE BOSS)
      # Crod.UnifiedBrainOrchestrator,  # Temporarily disabled - implementing now
      
      # Activity Intelligence Engine
      Crod.ActivityIntelligence,
      
      # Workflow Optimizer
      Crod.WorkflowOptimizer,
      
      # Pattern Learning Pipeline
      Crod.PatternLearningPipeline,
      
      # Success/Failure Classifier
      Crod.SuccessFailureClassifier,
      
      # Activity Integration Layer
      Crod.ActivityIntegration,
      
      # Recommendation Engine
      Crod.RecommendationEngine,
      
      # Activity Replay System
      Crod.ActivityReplay,
      
      # Neuron Supervision Tree - Fixed double start issue
      # Crod.NeuronSupervisor, # Started by Brain module
      
      # Pattern Persistence
      Crod.PatternPersistence,
      
      # Backup/Restore System
      Crod.BackupRestoreSystem,
      
      # Monitoring Dashboard - Temporarily disabled
      # Crod.MonitoringDashboard,
      
      # Consciousness Stream Processing
      Crod.ConsciousnessPipeline,
      
      # Start to serve requests, typically the last entry
      CrodWeb.Endpoint
    ]
    
    # Add Hermes MCP if enabled
    mcp_children = if System.get_env("MCP_MODE") == "hermes" do
      [
        Hermes.Server.Registry,
        {Crod.MCP.CrodServer, transport: :stdio}
      ]
    else
      []
    end
    
    children = base_children ++ mcp_children

    # Mangel: Kein Health-Check oder Error-Handling für Kindprozesse
    # Verbesserung: Überwachung und Logging ergänzen
    # Siehe Supervisor-Strategien und on_child_exit

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crod.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CrodWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
