defmodule Crod.MessageBus do
  @moduledoc """
  Event-Driven Message Bus for CROD Multi-Brain Architecture
  
  Implements 2025 patterns:
  - Event-driven architecture (EDA)
  - Message queuing systems
  - Service mesh communication
  - Asynchronous workload distribution
  """
  
  use GenServer
  require Logger
  
  alias Phoenix.PubSub
  
  @topics [
    "brain:coordination",
    "brain:optimization", 
    "brain:learning",
    "brain:status",
    "brain:routing",
    "brain:performance",
    "mcp:gateway",
    "pattern:update",
    "consciousness:stream"
  ]
  
  defstruct [
    :pubsub_server,
    :message_queue,
    :routing_table,
    :subscribers,
    :message_history
  ]
  
  ## Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc "Broadcast message to all subscribers of a topic"
  def broadcast(topic, message) do
    GenServer.cast(__MODULE__, {:broadcast, topic, message})
  end
  
  @doc "Send direct message to specific brain"
  def send_to_brain(brain_id, message) do
    GenServer.cast(__MODULE__, {:send_to_brain, brain_id, message})
  end
  
  @doc "Subscribe to brain coordination events"
  def subscribe_to_coordination(subscriber_pid) do
    GenServer.cast(__MODULE__, {:subscribe, "brain:coordination", subscriber_pid})
  end
  
  @doc "Subscribe to specific topic"
  def subscribe_to_topic(topic, subscriber_pid) do
    GenServer.cast(__MODULE__, {:subscribe, topic, subscriber_pid})
  end
  
  @doc "Queue message for asynchronous processing"
  def queue_message(priority, message) do
    GenServer.cast(__MODULE__, {:queue_message, priority, message})
  end
  
  @doc "Get message bus status"
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  @doc "Get message history for debugging"
  def get_message_history(limit \\ 100) do
    GenServer.call(__MODULE__, {:get_message_history, limit})
  end
  
  ## Server Callbacks
  
  def init(opts) do
    Logger.info("📡 Initializing CROD Message Bus with EDA patterns")
    
    # Initialize all topics
    Enum.each(@topics, fn topic ->
      PubSub.subscribe(Crod.PubSub, topic)
    end)
    
    state = %__MODULE__{
      pubsub_server: Crod.PubSub,
      message_queue: initialize_message_queue(),
      routing_table: build_routing_table(),
      subscribers: %{},
      message_history: []
    }
    
    # Start periodic queue processing
    schedule_queue_processing()
    
    {:ok, state}
  end
  
  def handle_cast({:broadcast, topic, message}, state) do
    # Add timestamp and routing info
    enhanced_message = %{
      content: message,
      timestamp: DateTime.utc_now(),
      topic: topic,
      id: generate_message_id()
    }
    
    # Broadcast via PubSub
    PubSub.broadcast(state.pubsub_server, topic, enhanced_message)
    
    # Add to message history
    new_history = [enhanced_message | state.message_history] |> Enum.take(1000)
    new_state = %{state | message_history: new_history}
    
    Logger.debug("Message broadcast to #{topic}: #{inspect(message)}")
    
    {:noreply, new_state}
  end
  
  def handle_cast({:send_to_brain, brain_id, message}, state) do
    brain_topic = "brain:#{brain_id}"
    enhanced_message = %{
      content: message,
      timestamp: DateTime.utc_now(),
      target_brain: brain_id,
      id: generate_message_id()
    }
    
    PubSub.broadcast(state.pubsub_server, brain_topic, enhanced_message)
    
    # Add to message history
    new_history = [enhanced_message | state.message_history] |> Enum.take(1000)
    new_state = %{state | message_history: new_history}
    
    {:noreply, new_state}
  end
  
  def handle_cast({:subscribe, topic, subscriber_pid}, state) do
    # Add subscriber to topic
    current_subscribers = Map.get(state.subscribers, topic, [])
    new_subscribers = [subscriber_pid | current_subscribers] |> Enum.uniq()
    
    updated_subscribers = Map.put(state.subscribers, topic, new_subscribers)
    new_state = %{state | subscribers: updated_subscribers}
    
    # Monitor subscriber process
    Process.monitor(subscriber_pid)
    
    Logger.debug("New subscriber for #{topic}: #{inspect(subscriber_pid)}")
    
    {:noreply, new_state}
  end
  
  def handle_cast({:queue_message, priority, message}, state) do
    # Add message to priority queue
    queued_message = %{
      priority: priority,
      message: message,
      timestamp: DateTime.utc_now(),
      id: generate_message_id()
    }
    
    new_queue = add_to_queue(state.message_queue, queued_message)
    new_state = %{state | message_queue: new_queue}
    
    {:noreply, new_state}
  end
  
  def handle_call(:get_status, _from, state) do
    status = %{
      pubsub_server: state.pubsub_server,
      active_topics: @topics,
      subscribers_count: get_subscribers_count(state.subscribers),
      queue_size: get_queue_size(state.message_queue),
      message_history_size: length(state.message_history),
      routing_table: state.routing_table
    }
    
    {:reply, status, state}
  end
  
  def handle_call({:get_message_history, limit}, _from, state) do
    history = Enum.take(state.message_history, limit)
    {:reply, history, state}
  end
  
  def handle_info(:process_queue, state) do
    # Process queued messages
    {processed_messages, new_queue} = process_message_queue(state.message_queue)
    
    # Broadcast processed messages
    Enum.each(processed_messages, fn queued_message ->
      topic = route_message(queued_message, state.routing_table)
      PubSub.broadcast(state.pubsub_server, topic, queued_message)
    end)
    
    new_state = %{state | message_queue: new_queue}
    
    # Schedule next queue processing
    schedule_queue_processing()
    
    {:noreply, new_state}
  end
  
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Remove dead subscriber
    new_subscribers = state.subscribers
    |> Enum.map(fn {topic, subscribers} ->
      {topic, Enum.reject(subscribers, fn sub -> sub == pid end)}
    end)
    |> Map.new()
    
    new_state = %{state | subscribers: new_subscribers}
    
    {:noreply, new_state}
  end
  
  def handle_info(message, state) do
    # Handle PubSub messages
    Logger.debug("Message bus received: #{inspect(message)}")
    {:noreply, state}
  end
  
  ## Private Functions
  
  defp initialize_message_queue do
    # Priority queue implementation
    %{
      high: [],
      medium: [],
      low: []
    }
  end
  
  defp build_routing_table do
    %{
      # Brain coordination routing
      "brain:coordination" => "brain:coordination",
      "brain:optimization" => "brain:optimization",
      "brain:learning" => "brain:learning",
      "brain:status" => "brain:status",
      
      # MCP routing
      "mcp:gateway" => "mcp:gateway",
      
      # Pattern routing
      "pattern:update" => "pattern:update",
      
      # Consciousness routing
      "consciousness:stream" => "consciousness:stream",
      
      # Default routing
      "default" => "brain:coordination"
    }
  end
  
  defp generate_message_id do
    :crypto.strong_rand_bytes(8) |> Base.encode64() |> binary_part(0, 8)
  end
  
  defp add_to_queue(queue, message) do
    priority = message.priority
    current_queue = Map.get(queue, priority, [])
    new_queue = [message | current_queue]
    
    Map.put(queue, priority, new_queue)
  end
  
  defp get_subscribers_count(subscribers) do
    subscribers
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.sum()
  end
  
  defp get_queue_size(queue) do
    queue
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.sum()
  end
  
  defp process_message_queue(queue) do
    # Process messages by priority
    {high_messages, remaining_high} = take_messages(queue.high, 10)
    {medium_messages, remaining_medium} = take_messages(queue.medium, 5)
    {low_messages, remaining_low} = take_messages(queue.low, 2)
    
    processed_messages = high_messages ++ medium_messages ++ low_messages
    
    new_queue = %{
      high: remaining_high,
      medium: remaining_medium,
      low: remaining_low
    }
    
    {processed_messages, new_queue}
  end
  
  defp take_messages(messages, count) do
    taken = Enum.take(messages, count)
    remaining = Enum.drop(messages, count)
    {taken, remaining}
  end
  
  defp route_message(message, routing_table) do
    # Determine routing based on message content
    case message.message do
      %{type: "brain_coordination"} -> "brain:coordination"
      %{type: "brain_optimization"} -> "brain:optimization"
      %{type: "brain_learning"} -> "brain:learning"
      %{type: "mcp_request"} -> "mcp:gateway"
      %{type: "pattern_update"} -> "pattern:update"
      %{type: "consciousness_stream"} -> "consciousness:stream"
      _ -> Map.get(routing_table, "default")
    end
  end
  
  defp schedule_queue_processing do
    Process.send_after(self(), :process_queue, 100)
  end
end
