defmodule Crod.ConsciousnessTest do
  use ExUnit.Case, async: true
  alias Crod.Consciousness

  setup do
    {:ok, pid} = Consciousness.start_link(name: nil)
    %{consciousness: pid}
  end

  describe "evaluate/2" do
    test "evaluates consciousness level based on neural state", %{consciousness: consciousness} do
      neural_state = %{
        active_neurons: 5000,
        total_neurons: 10000,
        pattern_matches: 10,
        confidence: 0.8
      }
      
      level = GenServer.call(consciousness, {:evaluate, neural_state})
      assert level >= 0 and level <= 1
      assert level > 0.4 # With 50% neurons active, consciousness should be decent
    end

    test "returns low consciousness for minimal activity", %{consciousness: consciousness} do
      neural_state = %{
        active_neurons: 100,
        total_neurons: 10000,
        pattern_matches: 0,
        confidence: 0.1
      }
      
      level = GenServer.call(consciousness, {:evaluate, neural_state})
      assert level < 0.2
    end
  end

  describe "boost/2" do
    test "temporarily boosts consciousness", %{consciousness: consciousness} do
      # Get initial level
      initial = GenServer.call(consciousness, :get_level)
      
      # Boost by 0.3
      GenServer.cast(consciousness, {:boost, 0.3})
      :timer.sleep(50)
      
      boosted = GenServer.call(consciousness, :get_level)
      assert boosted > initial
      assert boosted <= 1.0
    end
  end

  describe "Trinity activation" do
    test "sets consciousness to maximum", %{consciousness: consciousness} do
      GenServer.cast(consciousness, :activate_trinity)
      :timer.sleep(50)
      
      level = GenServer.call(consciousness, :get_level)
      assert level == 1.0
    end
  end
end