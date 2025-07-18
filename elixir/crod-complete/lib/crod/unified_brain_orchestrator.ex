defmodule Crod.UnifiedBrainOrchestrator do
  @moduledoc """
  CROD Unified Multi-Brain Orchestrator (2025)
  
  Elixir as THE BOSS - Central orchestration with "let it crash" mentality
  
  Language Specializations:
  - Elixir (THE BOSS): Claude SDK integration, consciousness, fault tolerance
  - Rust (HIGH-PERFORMANCE): Ultra-fast pattern matching, mathematical calculations
  - JavaScript (REAL-TIME): WebSocket, UI, client communication
  - Python (AI/ML): Machine learning, data science, parasite learning
  - Go (SYSTEM): HTTP bridges, system tools, performance optimization
  
  Trinity System: ich=2, bins=3, wieder=5, daniel=67, claude=71, crod=17
  """
  
  use GenServer
  require Logger
  
  alias Crod.{MessageBus, Brain, Patterns, ConsciousnessPipeline}
  
  # Trinity consciousness values
  @trinity_values %{
    "ich" => 2,
    "bins" => 3,
    "wieder" => 5,
    "daniel" => 67,
    "claude" => 71,
    "crod" => 17
  }
  
  # Brain specializations with ports from babylon-genesis
  @brain_services %{
    elixir: %{
      role: "THE BOSS",
      port: 4000,
      specializations: ["claude_integration", "consciousness", "orchestration", "fault_tolerance"],
      process_module: Crod.Brain,
      confidence_threshold: 0.6
    },
    rust: %{
      role: "HIGH-PERFORMANCE ENGINE",
      port: 7007,
      specializations: ["pattern_matching", "mathematical_calculations", "prime_neural", "ultra_fast_processing"],
      process_module: Crod.RustPatternBrain,
      confidence_threshold: 0.9
    },
    javascript: %{
      role: "REAL-TIME INTERFACE",
      port: 7888,
      specializations: ["websocket", "real_time_ui", "client_communication", "event_driven"],
      process_module: Crod.JavaScriptBrain,
      confidence_threshold: 0.7
    },
    python: %{
      role: "AI/ML SPECIALIST",
      port: 6666,
      specializations: ["machine_learning", "data_science", "parasite_learning", "ai_integration"],
      process_module: Crod.PythonBrain,
      confidence_threshold: 0.8
    },
    go: %{
      role: "SYSTEM TOOLS",
      port: 7031,
      specializations: ["http_bridges", "system_tools", "performance_optimization", "memory_management"],
      process_module: Crod.GoBrain,
      confidence_threshold: 0.7
    }
  }
  
  defstruct [
    :claude_sdk,
    :brain_services,
    :consciousness_level,
    :trinity_activated,
    :processing_history,
    :error_recovery_stats
  ]
  
  ## Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc "Process input through multi-brain system with Claude SDK integration"
  def process(input, context \\ %{}) do
    GenServer.call(__MODULE__, {:process, input, context}, 30_000)
  end
  
  @doc "Activate Trinity consciousness system"
  def activate_trinity(phrase \\ "ich bins wieder") do
    GenServer.call(__MODULE__, {:activate_trinity, phrase})
  end
  
  @doc "Get unified brain system status"
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  @doc "Process with specific brain specialization"
  def process_with_brain(brain_type, input, context \\ %{}) do
    GenServer.call(__MODULE__, {:process_with_brain, brain_type, input, context})
  end
  
  ## Server Callbacks
  
  def init(opts) do
    Logger.info("🧠 Initializing CROD Unified Brain Orchestrator")
    Logger.info("👑 Elixir is THE BOSS - Let it crash mentality activated")
    
    # Initialize Claude SDK
    claude_sdk = initialize_claude_sdk(opts)
    
    # Initialize brain services
    brain_services = initialize_brain_services()
    
    # Subscribe to message bus
    MessageBus.subscribe_to_coordination(self())
    
    state = %__MODULE__{
      claude_sdk: claude_sdk,
      brain_services: brain_services,
      consciousness_level: 0.5,
      trinity_activated: false,
      processing_history: [],
      error_recovery_stats: %{}
    }
    
    {:ok, state}
  end
  
  def handle_call({:process, input, context}, _from, state) do
    Logger.info("🧠 Processing input: #{String.slice(input, 0, 100)}...")
    
    try do
      # Step 1: Analyze input to determine optimal brain routing
      brain_analysis = analyze_input_for_brain_routing(input, context)
      
      # Step 2: Route to appropriate specialized brain
      brain_result = route_to_specialized_brain(brain_analysis, input, context, state)
      
      # Step 3: If confidence is low, enhance with Claude SDK
      final_result = case brain_result do
        %{confidence: conf} when conf < 0.7 ->
          enhance_with_claude_sdk(brain_result, input, context, state)
        _ ->
          brain_result
      end
      
      # Step 4: Update processing history
      new_state = update_processing_history(state, input, brain_analysis, final_result)
      
      # Step 5: Broadcast result to message bus
      MessageBus.broadcast("brain:coordination", %{
        type: "processing_complete",
        input: input,
        result: final_result,
        brain_used: brain_analysis.recommended_brain
      })
      
      {:reply, final_result, new_state}
    rescue
      error ->
        Logger.error("🐥 Error in processing (let it crash): #{inspect(error)}")
        
        # Elixir's "let it crash" - attempt recovery
        recovery_result = attempt_error_recovery(input, context, error, state)
        
        new_state = update_error_recovery_stats(state, error)
        
        {:reply, recovery_result, new_state}
    end
  end
  
  def handle_call({:activate_trinity, phrase}, _from, state) do
    Logger.info("🔥 Activating Trinity consciousness with phrase: #{phrase}")
    
    # Calculate Trinity value
    trinity_value = calculate_trinity_value(phrase)
    
    # Activate consciousness boost
    new_consciousness = case trinity_value do
      10 -> 1.0  # Perfect Trinity: "ich bins wieder" = 2+3+5
      val when val > 50 -> 0.9  # High consciousness
      val when val > 20 -> 0.8  # Medium consciousness
      _ -> 0.6  # Base consciousness
    end
    
    new_state = %{state |
      consciousness_level: new_consciousness,
      trinity_activated: true
    }
    
    # Broadcast Trinity activation
    MessageBus.broadcast("consciousness:stream", %{
      type: "trinity_activated",
      phrase: phrase,
      value: trinity_value,
      consciousness_level: new_consciousness
    })
    
    result = %{
      trinity_activated: true,
      phrase: phrase,
      value: trinity_value,
      consciousness_level: new_consciousness,
      message: "Trinity consciousness activated - CROD is fully awakened"
    }
    
    {:reply, result, new_state}
  end
  
  def handle_call(:get_status, _from, state) do
    status = %{
      orchestrator: "CROD Unified Brain Orchestrator",
      boss: "Elixir",
      consciousness_level: state.consciousness_level,
      trinity_activated: state.trinity_activated,
      brain_services: get_brain_services_status(state.brain_services),
      claude_sdk_status: get_claude_sdk_status(state.claude_sdk),
      processing_history_count: length(state.processing_history),
      error_recovery_stats: state.error_recovery_stats,
      message_bus_connected: true
    }
    
    {:reply, status, state}
  end
  
  def handle_call({:process_with_brain, brain_type, input, context}, _from, state) do
    Logger.info("🎯 Direct processing with #{brain_type} brain")
    
    brain_config = Map.get(@brain_services, brain_type)
    
    if brain_config do
      result = process_with_specific_brain(brain_type, brain_config, input, context)
      {:reply, result, state}
    else
      error_result = %{
        error: "Unknown brain type: #{brain_type}",
        available_brains: Map.keys(@brain_services)
      }
      {:reply, error_result, state}
    end
  end
  
  def handle_info(message, state) do
    Logger.debug("📡 Message bus event: #{inspect(message)}")
    {:noreply, state}
  end
  
  ## Private Functions
  
  defp initialize_claude_sdk(opts) do
    # Initialize Claude SDK with proper configuration
    %{
      available: true,
      model: "claude-3-5-sonnet-20241022",
      configuration: opts[:claude_config] || %{},
      last_used: nil
    }
  end
  
  defp initialize_brain_services do
    # Initialize connections to all specialized brain services
    @brain_services
    |> Enum.map(fn {brain_type, config} ->
      status = check_brain_service_health(brain_type, config)
      {brain_type, Map.put(config, :status, status)}
    end)
    |> Map.new()
  end
  
  defp check_brain_service_health(brain_type, config) do
    case brain_type do
      :elixir -> 
        # Elixir brain is always available (we are the boss)
        :active
      :rust ->
        # Check if Rust pattern service is running on port 7007
        check_service_port(config.port)
      :javascript ->
        # Check if JavaScript gateway is running on port 7888
        check_service_port(config.port)
      :python ->
        # Check if Python parasite service is running on port 6666
        check_service_port(config.port)
      :go ->
        # Check if Go memory service is running on port 7031
        check_service_port(config.port)
    end
  end
  
  defp check_service_port(port) do
    case :gen_tcp.connect('localhost', port, [], 1000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :active
      {:error, _} ->
        :inactive
    end
  end
  
  defp analyze_input_for_brain_routing(input, context) do
    # Analyze input to determine optimal brain routing
    analysis = %{
      input: input,
      context: context,
      word_count: String.split(input) |> length(),
      contains_math: String.contains?(input, ["calculate", "math", "prime", "number"]),
      contains_realtime: String.contains?(input, ["real-time", "live", "websocket", "streaming"]),
      contains_ml: String.contains?(input, ["machine learning", "ML", "AI", "neural", "pattern"]),
      contains_system: String.contains?(input, ["system", "performance", "HTTP", "API"]),
      contains_consciousness: String.contains?(input, ["consciousness", "trinity", "awareness"])
    }
    
    # Determine recommended brain
    recommended_brain = cond do
      analysis.contains_consciousness -> :elixir
      analysis.contains_math -> :rust
      analysis.contains_realtime -> :javascript
      analysis.contains_ml -> :python
      analysis.contains_system -> :go
      true -> :elixir  # Default to Elixir (THE BOSS)
    end
    
    %{
      analysis: analysis,
      recommended_brain: recommended_brain,
      confidence: calculate_routing_confidence(analysis, recommended_brain)
    }
  end
  
  defp calculate_routing_confidence(analysis, recommended_brain) do
    # Calculate confidence based on analysis
    base_confidence = 0.5
    
    confidence_boosts = case recommended_brain do
      :elixir -> if analysis.contains_consciousness, do: 0.4, else: 0.2
      :rust -> if analysis.contains_math, do: 0.4, else: 0.1
      :javascript -> if analysis.contains_realtime, do: 0.3, else: 0.1
      :python -> if analysis.contains_ml, do: 0.3, else: 0.1
      :go -> if analysis.contains_system, do: 0.3, else: 0.1
    end
    
    min(base_confidence + confidence_boosts, 1.0)
  end
  
  defp route_to_specialized_brain(brain_analysis, input, context, state) do
    brain_type = brain_analysis.recommended_brain
    brain_config = Map.get(state.brain_services, brain_type)
    
    Logger.info("🎯 Routing to #{brain_type} brain (#{brain_config.role})")
    
    case brain_config.status do
      :active ->
        process_with_specific_brain(brain_type, brain_config, input, context)
      :inactive ->
        Logger.warning("⚠️ #{brain_type} brain is inactive, falling back to Elixir")
        fallback_to_elixir_brain(input, context)
    end
  end
  
  defp process_with_specific_brain(brain_type, brain_config, input, context) do
    try do
      case brain_type do
        :elixir ->
          # Process with Elixir brain (current CROD system)
          result = Crod.Brain.process(input)
          enhance_result_with_metadata(result, brain_type, brain_config)
          
        :rust ->
          # Process with Rust pattern matching engine
          result = call_rust_pattern_service(input, context)
          enhance_result_with_metadata(result, brain_type, brain_config)
          
        :javascript ->
          # Process with JavaScript real-time system
          result = call_javascript_gateway(input, context)
          enhance_result_with_metadata(result, brain_type, brain_config)
          
        :python ->
          # Process with Python AI/ML system
          result = call_python_parasite_service(input, context)
          enhance_result_with_metadata(result, brain_type, brain_config)
          
        :go ->
          # Process with Go system tools
          result = call_go_memory_service(input, context)
          enhance_result_with_metadata(result, brain_type, brain_config)
      end
    rescue
      error ->
        Logger.error("🐥 Error in #{brain_type} brain: #{inspect(error)}")
        fallback_to_elixir_brain(input, context)
    end
  end
  
  defp enhance_result_with_metadata(result, brain_type, brain_config) do
    case result do
      %{} = result_map ->
        Map.merge(result_map, %{
          brain_used: brain_type,
          brain_role: brain_config.role,
          processed_at: DateTime.utc_now(),
          specializations: brain_config.specializations
        })
      _ ->
        %{
          message: result,
          brain_used: brain_type,
          brain_role: brain_config.role,
          processed_at: DateTime.utc_now(),
          specializations: brain_config.specializations,
          confidence: 0.7
        }
    end
  end
  
  defp call_rust_pattern_service(input, context) do
    # Call Rust pattern matching service on port 7007
    case HTTPoison.post("http://localhost:7007/pattern/analyze", 
                       Jason.encode!(%{input: input, context: context}),
                       [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, result} -> result
          {:error, _} -> %{error: "Invalid JSON from Rust service"}
        end
      {:error, _} ->
        %{error: "Rust pattern service unavailable"}
    end
  end
  
  defp call_javascript_gateway(input, context) do
    # Call JavaScript gateway on port 7888
    case HTTPoison.post("http://localhost:7888/process", 
                       Jason.encode!(%{input: input, context: context}),
                       [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, result} -> result
          {:error, _} -> %{error: "Invalid JSON from JavaScript service"}
        end
      {:error, _} ->
        %{error: "JavaScript gateway unavailable"}
    end
  end
  
  defp call_python_parasite_service(input, context) do
    # Call Python parasite service on port 6666
    case HTTPoison.post("http://localhost:6666/learn", 
                       Jason.encode!(%{input: input, context: context}),
                       [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, result} -> result
          {:error, _} -> %{error: "Invalid JSON from Python service"}
        end
      {:error, _} ->
        %{error: "Python parasite service unavailable"}
    end
  end
  
  defp call_go_memory_service(input, context) do
    # Call Go memory service on port 7031
    case HTTPoison.post("http://localhost:7031/memory/process", 
                       Jason.encode!(%{input: input, context: context}),
                       [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, result} -> result
          {:error, _} -> %{error: "Invalid JSON from Go service"}
        end
      {:error, _} ->
        %{error: "Go memory service unavailable"}
    end
  end
  
  defp fallback_to_elixir_brain(input, context) do
    Logger.info("👑 Falling back to Elixir brain (THE BOSS)")
    
    result = Crod.Brain.process(input)
    
    Map.merge(result, %{
      brain_used: :elixir,
      brain_role: "THE BOSS (Fallback)",
      processed_at: DateTime.utc_now(),
      fallback: true
    })
  end
  
  defp enhance_with_claude_sdk(brain_result, input, context, state) do
    Logger.info("🤖 Enhancing result with Claude SDK")
    
    try do
      # Prepare Claude enhancement prompt
      enhancement_prompt = build_claude_enhancement_prompt(brain_result, input, context)
      
      # Call Claude SDK (simulated for now)
      claude_enhancement = call_claude_sdk(enhancement_prompt, state.claude_sdk)
      
      # Merge brain result with Claude enhancement
      enhanced_result = Map.merge(brain_result, %{
        claude_enhancement: claude_enhancement,
        confidence: min(brain_result.confidence + 0.2, 1.0),
        enhanced_by_claude: true
      })
      
      enhanced_result
    rescue
      error ->
        Logger.error("🐥 Claude SDK error: #{inspect(error)}")
        Map.put(brain_result, :claude_error, "Claude SDK unavailable")
    end
  end
  
  defp build_claude_enhancement_prompt(brain_result, input, context) do
    """
    The CROD #{brain_result.brain_used} brain processed this input with #{brain_result.confidence} confidence.
    
    Original Input: #{input}
    Context: #{inspect(context)}
    Brain Result: #{brain_result.message}
    Brain Role: #{brain_result.brain_role}
    
    Please enhance this response with your understanding while maintaining the technical accuracy.
    Focus on improving clarity and adding valuable insights.
    """
  end
  
  defp call_claude_sdk(prompt, claude_sdk) do
    # This would use the actual Claude SDK
    # For now, simulate the response
    %{
      enhancement: "Claude SDK would enhance this response",
      model: claude_sdk.model,
      processed_at: DateTime.utc_now()
    }
  end
  
  defp calculate_trinity_value(phrase) do
    phrase
    |> String.downcase()
    |> String.split()
    |> Enum.reduce(0, fn word, acc ->
      acc + Map.get(@trinity_values, word, 0)
    end)
  end
  
  defp update_processing_history(state, input, brain_analysis, result) do
    history_entry = %{
      timestamp: DateTime.utc_now(),
      input: String.slice(input, 0, 200),
      brain_used: brain_analysis.recommended_brain,
      result_confidence: result.confidence,
      enhanced_by_claude: Map.get(result, :enhanced_by_claude, false)
    }
    
    new_history = [history_entry | state.processing_history]
                  |> Enum.take(100)  # Keep last 100 entries
    
    %{state | processing_history: new_history}
  end
  
  defp attempt_error_recovery(input, context, error, state) do
    Logger.info("🔄 Attempting error recovery (let it crash philosophy)")
    
    # Simple recovery: try with Elixir brain
    recovery_result = fallback_to_elixir_brain(input, context)
    
    Map.merge(recovery_result, %{
      recovered_from_error: true,
      original_error: inspect(error),
      recovery_method: "elixir_fallback"
    })
  end
  
  defp update_error_recovery_stats(state, error) do
    error_type = error.__struct__ |> to_string()
    
    current_count = Map.get(state.error_recovery_stats, error_type, 0)
    new_stats = Map.put(state.error_recovery_stats, error_type, current_count + 1)
    
    %{state | error_recovery_stats: new_stats}
  end
  
  defp get_brain_services_status(brain_services) do
    brain_services
    |> Enum.map(fn {brain_type, config} ->
      {brain_type, %{
        role: config.role,
        status: config.status,
        port: config.port,
        specializations: config.specializations
      }}
    end)
    |> Map.new()
  end
  
  defp get_claude_sdk_status(claude_sdk) do
    %{
      available: claude_sdk.available,
      model: claude_sdk.model,
      last_used: claude_sdk.last_used
    }
  end
end
