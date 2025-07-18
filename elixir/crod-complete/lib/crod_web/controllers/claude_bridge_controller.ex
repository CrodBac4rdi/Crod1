defmodule CrodWeb.ClaudeBridgeController do
  use CrodWeb, :controller
  require Logger

  # This endpoint processes messages through CROD before Claude sees them
  def process(conn, %{"message" => message, "context" => context} = params) do
    # Include conversation history for better context
    full_context = build_context(message, context, Map.get(params, "history", []))
    
    # Step 1: CROD analyzes the message with context
    crod_analysis = Crod.Brain.process(full_context)
    
    # Step 2: Extract patterns and mood
    analysis = %{
      original_message: message,
      crod_analysis: %{
        confidence: crod_analysis.confidence,
        patterns: crod_analysis.pattern_matches,
        mood: detect_mood(message),
        intent: detect_intent(message),
        neurons_activated: crod_analysis.neuron_activations
      },
      suggestions: %{
        tone: suggest_tone(message, crod_analysis),
        focus_on: key_points(message, crod_analysis),
        avoid: what_to_avoid(message)
      }
    }
    
    # Step 3: Log for learning
    Logger.info("Claude-CROD Bridge: Processing '#{message}'")
    # Store pattern for future learning
    GenServer.cast(Crod.Patterns, {:learn, message, context, crod_analysis.confidence})
    
    json(conn, analysis)
  end

  defp detect_mood(message) do
    cond do
      String.contains?(message, ["FUCKING", "DUMB", "FUCK"]) -> "frustrated/angry"
      String.contains?(message, ["uhm", "idk", "?"]) -> "uncertain/questioning"
      String.contains?(message, ["!", "!!", "!!!"]) -> "emphatic"
      String.contains?(message, [":)", "😊", "😄"]) -> "friendly"
      true -> "neutral"
    end
  end

  defp detect_intent(message) do
    cond do
      String.contains?(message, ["implement", "build", "create"]) -> "wants_action"
      String.contains?(message, ["why", "what", "how"]) -> "seeking_explanation"
      String.contains?(message, ["bothers me", "hate", "annoying"]) -> "expressing_frustration"
      String.contains?(message, "no") && String.contains?(message, ["?", "uhm", "um"]) -> "clarifying_disagreement"
      String.contains?(message, ["keep going", "continue", "don't stop"]) -> "wants_continuation"
      true -> "general_communication"
    end
  end

  defp build_context(message, context, history) do
    # Combine current message with recent history
    recent_messages = Enum.take(history, -3) |> Enum.map(& &1["content"]) |> Enum.join(" | ")
    context_str = case context do
      %{} -> inspect(context)
      _ -> "#{context}"
    end
    "Context: #{context_str} | History: #{recent_messages} | Current: #{message}"
  end

  defp suggest_tone(_message, crod_analysis) do
    case crod_analysis.confidence do
      c when c < 0.3 -> "Be more direct and clarifying"
      c when c < 0.6 -> "Acknowledge uncertainty, ask for clarification"
      _ -> "Respond with confidence"
    end
  end

  defp key_points(message, _crod_analysis) do
    # Extract key action items
    points = []
    
    if String.contains?(message, "implement"), do: points = ["User wants implementation" | points]
    if String.contains?(message, "live"), do: points = ["Real-time usage important" | points]
    if String.contains?(message, "use it"), do: points = ["Actually use the system" | points]
    
    points
  end

  defp what_to_avoid(message) do
    cond do
      String.contains?(message, ["FUCKING", "DUMB"]) -> 
        ["Dismissive responses", "Cheerful deflection", "Ignoring frustration"]
      String.contains?(message, "bothers me") ->
        ["Continuing the bothersome behavior", "Not acknowledging the issue"]
      true ->
        ["Overexplaining", "Not following through"]
    end
  end
end