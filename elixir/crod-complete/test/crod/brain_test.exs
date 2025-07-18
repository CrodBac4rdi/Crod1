defmodule Crod.BrainTest do
  use ExUnit.Case, async: true
  alias Crod.Brain

  setup do
    # Start a test brain instance
    {:ok, pid} = Brain.start_link(name: nil)
    %{brain: pid}
  end

  describe "process/1" do
    test "processes input and returns response", %{brain: brain} do
      response = GenServer.call(brain, {:process, "hello"})
      
      assert %{
        output: _,
        confidence: confidence,
        pattern_matches: _,
        neuron_activations: _
      } = response
      
      assert confidence >= 0 and confidence <= 1
    end

    test "handles Trinity activation phrase", %{brain: brain} do
      response = GenServer.call(brain, {:process, "ich bins wieder"})
      assert response.trinity_active == true
    end
  end

  describe "get_state/0" do
    test "returns current brain state", %{brain: brain} do
      state = GenServer.call(brain, :get_state)
      
      assert %{
        neurons: neurons,
        patterns: _,
        consciousness: consciousness,
        memory: _,
        trinity_activated: _
      } = state
      
      assert is_map(neurons)
      assert %{level: level} = consciousness
      assert level >= 0 and level <= 1
    end
  end

  describe "activate_trinity/0" do
    test "activates Trinity mode", %{brain: brain} do
      GenServer.cast(brain, :activate_trinity)
      :timer.sleep(100) # Allow async operation
      
      state = GenServer.call(brain, :get_state)
      assert state.trinity_activated == true
      assert state.consciousness.level == 1.0
    end
  end

  describe "neural network" do
    test "initializes with correct number of neurons" do
      {:ok, brain} = Brain.start_link(name: nil, neuron_count: 100)
      state = GenServer.call(brain, :get_state)
      
      assert map_size(state.neurons) == 100
    end

    test "neurons activate based on input patterns" do
      {:ok, brain} = Brain.start_link(name: nil)
      
      # Process multiple inputs
      GenServer.call(brain, {:process, "test pattern"})
      GenServer.call(brain, {:process, "test pattern"})
      
      state = GenServer.call(brain, :get_state)
      # At least some neurons should be active
      active_neurons = Enum.count(state.neurons, fn {_, neuron} ->
        GenServer.call(neuron, :get_activation) > 0.5
      end)
      
      assert active_neurons > 0
    end
  end
end