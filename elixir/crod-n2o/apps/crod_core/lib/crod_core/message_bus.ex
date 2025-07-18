defmodule CROD.Core.MessageBus do
  @moduledoc """
  Pub/Sub message bus for inter-framework communication
  """
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(topic, pid) do
    GenServer.call(__MODULE__, {:subscribe, topic, pid})
  end

  def unsubscribe(topic, pid) do
    GenServer.call(__MODULE__, {:unsubscribe, topic, pid})
  end

  def broadcast(topic, message, opts \\ []) do
    GenServer.cast(__MODULE__, {:broadcast, topic, message, opts})
  end

  def publish(topic, message) do
    GenServer.cast(__MODULE__, {:publish, topic, message})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      subscribers: %{},
      message_log: :queue.new(),
      max_log_size: 1000
    }}
  end

  @impl true
  def handle_call({:subscribe, topic, pid}, _from, state) do
    Process.monitor(pid)
    new_subscribers = Map.update(state.subscribers, topic, [pid], &[pid | &1])
    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  @impl true
  def handle_call({:unsubscribe, topic, pid}, _from, state) do
    new_subscribers = Map.update(state.subscribers, topic, [], &List.delete(&1, pid))
    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  @impl true
  def handle_cast({:broadcast, topic, message, opts}, state) do
    exclude = Keyword.get(opts, :exclude, [])
    
    subscribers = Map.get(state.subscribers, topic, [])
    Enum.each(subscribers, fn pid ->
      unless pid in exclude do
        send(pid, {:n2o, {topic, message}})
      end
    end)
    
    new_state = log_message(state, {topic, message})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:publish, topic, message}, state) do
    handle_cast({:broadcast, topic, message, []}, state)
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Remove dead subscriber from all topics
    new_subscribers = Enum.reduce(state.subscribers, %{}, fn {topic, pids}, acc ->
      case List.delete(pids, pid) do
        [] -> acc
        remaining -> Map.put(acc, topic, remaining)
      end
    end)
    {:noreply, %{state | subscribers: new_subscribers}}
  end

  # Private functions

  defp log_message(state, message) do
    new_log = :queue.in({DateTime.utc_now(), message}, state.message_log)
    
    # Trim if too large
    trimmed_log = if :queue.len(new_log) > state.max_log_size do
      {_, smaller} = :queue.out(new_log)
      smaller
    else
      new_log
    end
    
    %{state | message_log: trimmed_log}
  end
end