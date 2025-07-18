defmodule Crod.PatternsTest do
  use ExUnit.Case, async: true
  alias Crod.Patterns

  setup do
    {:ok, pid} = Patterns.start_link(name: nil)
    %{patterns: pid}
  end

  describe "match/2" do
    test "matches exact patterns", %{patterns: patterns} do
      # Add a test pattern
      pattern = %{
        input: "hello",
        response: "Hello! How can I help?",
        confidence: 0.9
      }
      GenServer.cast(patterns, {:add_pattern, pattern})
      :timer.sleep(50)
      
      result = GenServer.call(patterns, {:match, "hello"})
      assert result != nil
      assert result.response == "Hello! How can I help?"
    end

    test "matches partial patterns", %{patterns: patterns} do
      pattern = %{
        input: "weather",
        response: "I can help with weather information",
        confidence: 0.8
      }
      GenServer.cast(patterns, {:add_pattern, pattern})
      :timer.sleep(50)
      
      result = GenServer.call(patterns, {:match, "what's the weather like?"})
      assert result != nil
      assert result.confidence < 0.8 # Partial match has lower confidence
    end

    test "returns nil for no match", %{patterns: patterns} do
      result = GenServer.call(patterns, {:match, "completely unmatched input"})
      assert result == nil
    end
  end

  describe "learn/3" do
    test "learns new patterns", %{patterns: patterns} do
      GenServer.cast(patterns, {:learn, "test input", "test response", 0.7})
      :timer.sleep(50)
      
      result = GenServer.call(patterns, {:match, "test input"})
      assert result != nil
      assert result.response == "test response"
      assert result.confidence >= 0.7
    end

    test "updates existing patterns", %{patterns: patterns} do
      # Learn initial pattern
      GenServer.cast(patterns, {:learn, "greeting", "Hi there!", 0.6})
      :timer.sleep(50)
      
      # Update with better response
      GenServer.cast(patterns, {:learn, "greeting", "Hello! Nice to meet you!", 0.9})
      :timer.sleep(50)
      
      result = GenServer.call(patterns, {:match, "greeting"})
      assert result.response == "Hello! Nice to meet you!"
      assert result.confidence == 0.9
    end
  end

  describe "get_all/1" do
    test "returns all patterns", %{patterns: patterns} do
      # Add multiple patterns
      patterns_list = [
        %{input: "pat1", response: "resp1", confidence: 0.5},
        %{input: "pat2", response: "resp2", confidence: 0.6},
        %{input: "pat3", response: "resp3", confidence: 0.7}
      ]
      
      Enum.each(patterns_list, fn p ->
        GenServer.cast(patterns, {:add_pattern, p})
      end)
      :timer.sleep(100)
      
      all = GenServer.call(patterns, :get_all)
      assert length(all) == 3
    end
  end
end