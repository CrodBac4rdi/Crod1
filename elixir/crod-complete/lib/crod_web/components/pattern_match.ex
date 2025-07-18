defmodule CrodWeb.Components.PatternMatch do
  @moduledoc """
  LiveComponent for displaying pattern matching results in real-time
  """
  
  use CrodWeb, :live_component
  
  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      filter: "all",
      sort_by: :score,
      expanded_patterns: MapSet.new()
    )}
  end
  
  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:limit, fn -> 10 end)
     |> filter_and_sort_patterns()}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="pattern-match-component">
      <div class="mb-4 flex items-center justify-between">
        <div class="flex space-x-2">
          <button 
            phx-click="set_filter" 
            phx-value-filter="all"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @filter == "all", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}"}
          >
            All
          </button>
          <button 
            phx-click="set_filter" 
            phx-value-filter="high_confidence"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @filter == "high_confidence", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}"}
          >
            High Confidence
          </button>
          <button 
            phx-click="set_filter" 
            phx-value-filter="recent"
            phx-target={@myself}
            class={"px-3 py-1 text-sm rounded transition-colors #{if @filter == "recent", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}"}
          >
            Recent
          </button>
        </div>
        
        <select 
          phx-change="change_sort"
          phx-target={@myself}
          class="text-sm rounded border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800"
        >
          <option value="score" selected={@sort_by == :score}>Sort by Score</option>
          <option value="confidence" selected={@sort_by == :confidence}>Sort by Confidence</option>
          <option value="timestamp" selected={@sort_by == :timestamp}>Sort by Time</option>
        </select>
      </div>
      
      <div class="space-y-2 max-h-96 overflow-y-auto">
        <%= if length(@filtered_patterns) == 0 do %>
          <div class="text-center py-8 text-gray-500 dark:text-gray-400">
            <p>No patterns matched yet</p>
            <p class="text-sm mt-2">Patterns will appear here as they are matched</p>
          </div>
        <% else %>
          <%= for pattern <- @filtered_patterns do %>
            <div 
              class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer"
              phx-click="toggle_expand"
              phx-value-id={pattern.id}
              phx-target={@myself}
            >
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center space-x-2">
                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                      <%= truncate(pattern["input"], 50) %>
                    </span>
                    <%= if pattern[:category] do %>
                      <span class="px-2 py-0.5 text-xs rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                        <%= pattern.category %>
                      </span>
                    <% end %>
                  </div>
                  
                  <div class="mt-1 flex items-center space-x-4 text-xs text-gray-500 dark:text-gray-400">
                    <span>
                      Score: <span class="font-medium"><%= format_score(pattern[:match_score]) %></span>
                    </span>
                    <span>
                      Confidence: <span class="font-medium"><%= format_percentage(pattern["confidence"]) %></span>
                    </span>
                    <span>
                      <%= format_time_ago(pattern[:timestamp]) %>
                    </span>
                  </div>
                  
                  <%= if MapSet.member?(@expanded_patterns, pattern.id) do %>
                    <div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
                      <div class="space-y-2">
                        <div>
                          <p class="text-xs text-gray-500 dark:text-gray-400">Output:</p>
                          <p class="text-sm text-gray-700 dark:text-gray-300"><%= pattern["output"] %></p>
                        </div>
                        
                        <%= if pattern["metadata"] do %>
                          <div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">Metadata:</p>
                            <div class="mt-1 flex flex-wrap gap-1">
                              <%= for {key, value} <- pattern["metadata"] do %>
                                <span class="px-2 py-0.5 text-xs rounded bg-gray-200 dark:bg-gray-700">
                                  <%= key %>: <%= inspect(value) %>
                                </span>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                        
                        <div class="flex items-center space-x-2 pt-2">
                          <button 
                            phx-click="test_pattern"
                            phx-value-id={pattern.id}
                            phx-target={@myself}
                            class="px-3 py-1 text-xs bg-blue-500 text-white rounded hover:bg-blue-600"
                          >
                            Test
                          </button>
                          <button 
                            phx-click="improve_pattern"
                            phx-value-id={pattern.id}
                            phx-target={@myself}
                            class="px-3 py-1 text-xs bg-green-500 text-white rounded hover:bg-green-600"
                          >
                            Improve
                          </button>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
                
                <div class="ml-2">
                  <svg 
                    class={"w-4 h-4 text-gray-400 transition-transform #{if MapSet.member?(@expanded_patterns, pattern.id), do: "rotate-180"}"}
                    fill="none" 
                    stroke="currentColor" 
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
      
      <%= if length(@patterns) > @limit do %>
        <div class="mt-4 text-center">
          <button 
            phx-click="load_more"
            phx-target={@myself}
            class="text-sm text-blue-500 hover:text-blue-600"
          >
            Show more (<%= length(@patterns) - @limit %> hidden)
          </button>
        </div>
      <% end %>
    </div>
    """
  end
  
  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    {:noreply, 
     socket
     |> assign(filter: filter)
     |> filter_and_sort_patterns()}
  end
  
  def handle_event("change_sort", %{"value" => sort_by}, socket) do
    {:noreply,
     socket
     |> assign(sort_by: String.to_atom(sort_by))
     |> filter_and_sort_patterns()}
  end
  
  def handle_event("toggle_expand", %{"id" => pattern_id}, socket) do
    expanded = socket.assigns.expanded_patterns
    
    new_expanded = if MapSet.member?(expanded, pattern_id) do
      MapSet.delete(expanded, pattern_id)
    else
      MapSet.put(expanded, pattern_id)
    end
    
    {:noreply, assign(socket, expanded_patterns: new_expanded)}
  end
  
  def handle_event("test_pattern", %{"id" => pattern_id}, socket) do
    pattern = Enum.find(socket.assigns.patterns, &(&1.id == pattern_id))
    
    if pattern do
      # Test the pattern with Brain
      result = Crod.Brain.process(pattern["input"])
      
      send_update(self(), __MODULE__,
        id: socket.assigns.id,
        test_result: %{
          pattern_id: pattern_id,
          result: result
        }
      )
    end
    
    {:noreply, socket}
  end
  
  def handle_event("improve_pattern", %{"id" => pattern_id}, socket) do
    pattern = Enum.find(socket.assigns.patterns, &(&1.id == pattern_id))
    
    if pattern do
      # Learn improved pattern
      Crod.Patterns.learn_pattern(
        pattern["input"],
        pattern["output"],
        metadata: Map.put(pattern["metadata"] || %{}, "improved", true)
      )
      
      # Notify user
      send(self(), {:put_flash, :info, "Pattern improved and relearned"})
    end
    
    {:noreply, socket}
  end
  
  def handle_event("load_more", _params, socket) do
    new_limit = min(socket.assigns.limit + 10, length(socket.assigns.patterns))
    {:noreply, assign(socket, limit: new_limit) |> filter_and_sort_patterns()}
  end
  
  # Private functions
  
  defp filter_and_sort_patterns(socket) do
    patterns = socket.assigns.patterns || []
    
    filtered = case socket.assigns.filter do
      "high_confidence" ->
        Enum.filter(patterns, &(&1["confidence"] >= 0.8))
      
      "recent" ->
        one_minute_ago = DateTime.add(DateTime.utc_now(), -60, :second)
        Enum.filter(patterns, &(DateTime.compare(&1[:timestamp] || DateTime.utc_now(), one_minute_ago) == :gt))
      
      _ ->
        patterns
    end
    
    sorted = case socket.assigns.sort_by do
      :confidence ->
        Enum.sort_by(filtered, & &1["confidence"], :desc)
      
      :timestamp ->
        Enum.sort_by(filtered, & &1[:timestamp], {:desc, DateTime})
      
      _ -> # :score
        Enum.sort_by(filtered, & &1[:match_score] || 0, :desc)
    end
    
    limited = Enum.take(sorted, socket.assigns.limit)
    
    assign(socket, filtered_patterns: limited)
  end
  
  defp truncate(text, max_length) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end
  
  defp format_score(nil), do: "N/A"
  defp format_score(score) when is_float(score), do: Float.round(score, 2)
  defp format_score(score), do: score
  
  defp format_percentage(nil), do: "N/A"
  defp format_percentage(value) when is_float(value), do: "#{round(value * 100)}%"
  defp format_percentage(value), do: "#{value}%"
  
  defp format_time_ago(nil), do: "Unknown"
  defp format_time_ago(timestamp) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), timestamp)
    
    cond do
      seconds_ago < 60 ->
        "#{seconds_ago}s ago"
      
      seconds_ago < 3600 ->
        "#{div(seconds_ago, 60)}m ago"
      
      seconds_ago < 86400 ->
        "#{div(seconds_ago, 3600)}h ago"
      
      true ->
        "#{div(seconds_ago, 86400)}d ago"
    end
  end
end