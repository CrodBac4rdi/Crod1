defmodule CrodWeb.Components.ActivityTimeline do
  @moduledoc """
  LiveComponent for displaying activity timeline with different view modes
  """
  
  use CrodWeb, :live_component
  
  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      filter_intent: "all",
      group_by: :time,
      playback_speed: 1.0,
      is_playing: false,
      current_index: 0
    )}
  end
  
  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:view_mode, fn -> :live end)
     |> process_activities()}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="activity-timeline-component">
      <%= case @view_mode do %>
        <% :live -> %>
          <.live_view activities={@processed_activities} filter_intent={@filter_intent} myself={@myself} />
        
        <% :replay -> %>
          <.replay_view 
            activities={@processed_activities} 
            current_index={@current_index}
            is_playing={@is_playing}
            playback_speed={@playback_speed}
            myself={@myself}
          />
        
        <% :analysis -> %>
          <.analysis_view 
            activities={@processed_activities}
            group_by={@group_by}
            myself={@myself}
          />
      <% end %>
    </div>
    """
  end
  
  @impl true
  def handle_event("set_filter", %{"intent" => intent}, socket) do
    {:noreply,
     socket
     |> assign(filter_intent: intent)
     |> process_activities()}
  end
  
  def handle_event("toggle_playback", _params, socket) do
    socket = if socket.assigns.is_playing do
      # Stop playback
      socket
    else
      # Start playback
      send(self(), {:playback_tick, socket.assigns.id})
      socket
    end
    
    {:noreply, update(socket, :is_playing, &(!&1))}
  end
  
  def handle_event("set_playback_speed", %{"speed" => speed}, socket) do
    {:noreply, assign(socket, playback_speed: String.to_float(speed))}
  end
  
  def handle_event("seek", %{"index" => index}, socket) do
    {:noreply, assign(socket, current_index: String.to_integer(index))}
  end
  
  def handle_event("set_group_by", %{"group" => group}, socket) do
    {:noreply,
     socket
     |> assign(group_by: String.to_atom(group))
     |> process_activities()}
  end
  
  # View components
  
  defp live_view(assigns) do
    ~H"""
    <div>
      <div class="mb-4 flex items-center justify-between">
        <div class="flex space-x-2">
          <select 
            phx-change="set_filter"
            phx-target={@myself}
            name="intent"
            class="text-sm rounded border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800"
          >
            <option value="all" selected={@filter_intent == "all"}>All Activities</option>
            <option value="elixir_development" selected={@filter_intent == "elixir_development"}>Elixir Dev</option>
            <option value="testing" selected={@filter_intent == "testing"}>Testing</option>
            <option value="documentation" selected={@filter_intent == "documentation"}>Documentation</option>
            <option value="bug_fix" selected={@filter_intent == "bug_fix"}>Bug Fixes</option>
            <option value="configuration" selected={@filter_intent == "configuration"}>Configuration</option>
          </select>
        </div>
        
        <div class="text-sm text-gray-500">
          <%= length(@activities) %> activities
        </div>
      </div>
      
      <div class="space-y-2 max-h-96 overflow-y-auto" id="activity-timeline-live" phx-update="prepend">
        <%= for activity <- Enum.take(@activities, 100) do %>
          <.activity_item activity={activity} />
        <% end %>
      </div>
      
      <%= if length(@activities) > 100 do %>
        <div class="mt-4 text-center text-sm text-gray-500">
          Showing latest 100 activities
        </div>
      <% end %>
    </div>
    """
  end
  
  defp replay_view(assigns) do
    ~H"""
    <div>
      <div class="mb-4">
        <div class="flex items-center space-x-4 mb-4">
          <button 
            phx-click="toggle_playback"
            phx-target={@myself}
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 flex items-center"
          >
            <%= if @is_playing do %>
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6" />
              </svg>
              Pause
            <% else %>
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
              </svg>
              Play
            <% end %>
          </button>
          
          <div class="flex items-center space-x-2">
            <label class="text-sm">Speed:</label>
            <select 
              phx-change="set_playback_speed"
              phx-target={@myself}
              name="speed"
              class="text-sm rounded border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800"
            >
              <option value="0.5" selected={@playback_speed == 0.5}>0.5x</option>
              <option value="1.0" selected={@playback_speed == 1.0}>1x</option>
              <option value="2.0" selected={@playback_speed == 2.0}>2x</option>
              <option value="5.0" selected={@playback_speed == 5.0}>5x</option>
            </select>
          </div>
          
          <div class="flex-1">
            <input 
              type="range" 
              min="0" 
              max={length(@activities) - 1}
              value={@current_index}
              phx-change="seek"
              phx-target={@myself}
              name="index"
              class="w-full"
            />
          </div>
          
          <div class="text-sm text-gray-500">
            <%= @current_index + 1 %> / <%= length(@activities) %>
          </div>
        </div>
        
        <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
          <%= if activity = Enum.at(@activities, @current_index) do %>
            <.activity_details activity={activity} />
          <% else %>
            <p class="text-gray-500">No activity at this index</p>
          <% end %>
        </div>
        
        <div class="mt-4 space-y-1">
          <p class="text-sm font-medium text-gray-700 dark:text-gray-300">Upcoming Activities:</p>
          <%= for activity <- Enum.slice(@activities, @current_index + 1, 5) do %>
            <.activity_preview activity={activity} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end
  
  defp analysis_view(assigns) do
    ~H"""
    <div>
      <div class="mb-4 flex items-center justify-between">
        <select 
          phx-change="set_group_by"
          phx-target={@myself}
          name="group"
          class="text-sm rounded border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800"
        >
          <option value="time" selected={@group_by == :time}>Group by Time</option>
          <option value="intent" selected={@group_by == :intent}>Group by Intent</option>
          <option value="file" selected={@group_by == :file}>Group by File</option>
          <option value="outcome" selected={@group_by == :outcome}>Group by Outcome</option>
        </select>
      </div>
      
      <div class="space-y-4">
        <%= for {group, activities} <- group_activities(@activities, @group_by) do %>
          <.activity_group group={group} activities={activities} group_by={@group_by} />
        <% end %>
      </div>
      
      <div class="mt-6 grid grid-cols-2 gap-4">
        <.activity_stats title="Total Activities" value={length(@activities)} />
        <.activity_stats title="Success Rate" value={calculate_success_rate(@activities)} />
        <.activity_stats title="Most Common Intent" value={most_common_intent(@activities)} />
        <.activity_stats title="Avg Duration" value={format_duration(avg_duration(@activities))} />
      </div>
    </div>
    """
  end
  
  # Activity display components
  
  defp activity_item(assigns) do
    ~H"""
    <div class="flex items-start space-x-3 p-3 bg-white dark:bg-gray-800 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
      <div class={"w-2 h-2 rounded-full mt-2 #{activity_color(@activity)}"}></div>
      
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-gray-900 dark:text-white">
              <%= @activity.intent %>
            </span>
            <span class="text-xs text-gray-500">
              <%= @activity.action %>
            </span>
          </div>
          
          <span class="text-xs text-gray-400">
            <%= format_timestamp(@activity.timestamp) %>
          </span>
        </div>
        
        <p class="text-sm text-gray-600 dark:text-gray-400 truncate">
          <%= @activity.file %>
        </p>
        
        <%= if @activity[:details] do %>
          <p class="text-xs text-gray-500 dark:text-gray-500 mt-1">
            <%= @activity.details %>
          </p>
        <% end %>
        
        <%= if @activity[:outcome] do %>
          <div class="mt-1 flex items-center space-x-2">
            <span class={"px-2 py-0.5 text-xs rounded-full #{outcome_style(@activity.outcome)}"}>
              <%= @activity.outcome %>
            </span>
            <%= if @activity[:duration_ms] do %>
              <span class="text-xs text-gray-400">
                <%= @activity.duration_ms %>ms
              </span>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
  
  defp activity_details(assigns) do
    ~H"""
    <div>
      <div class="flex items-start justify-between mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
            <%= @activity.intent %>
          </h3>
          <p class="text-sm text-gray-500">
            <%= format_full_timestamp(@activity.timestamp) %>
          </p>
        </div>
        
        <%= if @activity[:outcome] do %>
          <span class={"px-3 py-1 text-sm rounded-full #{outcome_style(@activity.outcome)}"}>
            <%= @activity.outcome %>
          </span>
        <% end %>
      </div>
      
      <dl class="space-y-2">
        <div class="flex">
          <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 w-24">Action:</dt>
          <dd class="text-sm text-gray-900 dark:text-white"><%= @activity.action %></dd>
        </div>
        
        <div class="flex">
          <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 w-24">File:</dt>
          <dd class="text-sm text-gray-900 dark:text-white font-mono"><%= @activity.file %></dd>
        </div>
        
        <%= if @activity[:why] do %>
          <div class="flex">
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 w-24">Why:</dt>
            <dd class="text-sm text-gray-900 dark:text-white"><%= @activity.why %></dd>
          </div>
        <% end %>
        
        <%= if @activity[:details] do %>
          <div class="flex">
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 w-24">Details:</dt>
            <dd class="text-sm text-gray-900 dark:text-white"><%= @activity.details %></dd>
          </div>
        <% end %>
        
        <%= if @activity[:duration_ms] do %>
          <div class="flex">
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 w-24">Duration:</dt>
            <dd class="text-sm text-gray-900 dark:text-white"><%= format_duration(@activity.duration_ms) %></dd>
          </div>
        <% end %>
        
        <%= if @activity[:metadata] do %>
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Metadata:</dt>
            <dd class="text-xs bg-gray-100 dark:bg-gray-900 p-2 rounded font-mono">
              <%= Jason.encode!(@activity.metadata, pretty: true) %>
            </dd>
          </div>
        <% end %>
      </dl>
    </div>
    """
  end
  
  defp activity_preview(assigns) do
    ~H"""
    <div class="flex items-center space-x-2 text-xs text-gray-500">
      <span class="w-20"><%= format_timestamp(@activity.timestamp) %></span>
      <span class="font-medium"><%= @activity.intent %></span>
      <span>→</span>
      <span class="truncate"><%= @activity.file %></span>
    </div>
    """
  end
  
  defp activity_group(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
      <div class="flex items-center justify-between mb-3">
        <h3 class="font-medium text-gray-900 dark:text-white">
          <%= format_group_name(@group, @group_by) %>
        </h3>
        <span class="text-sm text-gray-500">
          <%= length(@activities) %> activities
        </span>
      </div>
      
      <div class="space-y-2">
        <%= for activity <- Enum.take(@activities, 5) do %>
          <.activity_summary activity={activity} />
        <% end %>
        
        <%= if length(@activities) > 5 do %>
          <p class="text-xs text-gray-400 text-center">
            ... and <%= length(@activities) - 5 %> more
          </p>
        <% end %>
      </div>
      
      <div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between text-xs">
        <span class="text-gray-500">
          Success rate: <%= calculate_success_rate(@activities) %>
        </span>
        <span class="text-gray-500">
          Avg duration: <%= format_duration(avg_duration(@activities)) %>
        </span>
      </div>
    </div>
    """
  end
  
  defp activity_summary(assigns) do
    ~H"""
    <div class="flex items-center space-x-2 text-sm">
      <div class={"w-1.5 h-1.5 rounded-full #{activity_color(@activity)}"}></div>
      <span class="text-gray-600 dark:text-gray-400"><%= @activity.action %></span>
      <span class="text-gray-900 dark:text-white truncate"><%= @activity.file %></span>
      <%= if @activity[:outcome] do %>
        <span class={"text-xs #{outcome_text_color(@activity.outcome)}"}>
          <%= @activity.outcome %>
        </span>
      <% end %>
    </div>
    """
  end
  
  defp activity_stats(assigns) do
    ~H"""
    <div class="bg-gray-100 dark:bg-gray-800 rounded p-3">
      <p class="text-xs text-gray-500 dark:text-gray-400"><%= @title %></p>
      <p class="text-lg font-semibold text-gray-900 dark:text-white"><%= @value %></p>
    </div>
    """
  end
  
  # Helper functions
  
  defp process_activities(socket) do
    activities = socket.assigns.activities || []
    
    filtered = if socket.assigns.filter_intent == "all" do
      activities
    else
      Enum.filter(activities, &(&1.intent == socket.assigns.filter_intent))
    end
    
    assign(socket, processed_activities: filtered)
  end
  
  defp group_activities(activities, group_by) do
    activities
    |> Enum.group_by(fn activity ->
      case group_by do
        :intent -> activity.intent
        :file -> Path.dirname(activity.file)
        :outcome -> activity[:outcome] || "unknown"
        :time -> 
          activity.timestamp
          |> DateTime.truncate(:second)
          |> DateTime.to_iso8601()
          |> String.slice(0..15)  # Group by minute
      end
    end)
    |> Enum.sort_by(fn {_key, activities} -> -length(activities) end)
  end
  
  defp activity_color(activity) do
    case activity[:outcome] do
      :success -> "bg-green-500"
      :failure -> "bg-red-500"
      :warning -> "bg-yellow-500"
      _ ->
        case activity.action do
          "created" -> "bg-blue-500"
          "modified" -> "bg-purple-500"
          "deleted" -> "bg-red-500"
          "read" -> "bg-gray-400"
          _ -> "bg-gray-500"
        end
    end
  end
  
  defp outcome_style(:success), do: "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"
  defp outcome_style(:failure), do: "bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200"
  defp outcome_style(:warning), do: "bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200"
  defp outcome_style(_), do: "bg-gray-100 dark:bg-gray-900 text-gray-800 dark:text-gray-200"
  
  defp outcome_text_color(:success), do: "text-green-600 dark:text-green-400"
  defp outcome_text_color(:failure), do: "text-red-600 dark:text-red-400"
  defp outcome_text_color(:warning), do: "text-yellow-600 dark:text-yellow-400"
  defp outcome_text_color(_), do: "text-gray-600 dark:text-gray-400"
  
  defp format_timestamp(timestamp) do
    case DateTime.diff(DateTime.utc_now(), timestamp) do
      diff when diff < 60 -> "#{diff}s"
      diff when diff < 3600 -> "#{div(diff, 60)}m"
      diff when diff < 86400 -> "#{div(diff, 3600)}h"
      _ -> Calendar.strftime(timestamp, "%b %d")
    end
  end
  
  defp format_full_timestamp(timestamp) do
    Calendar.strftime(timestamp, "%B %d, %Y at %I:%M:%S %p")
  end
  
  defp format_duration(nil), do: "N/A"
  defp format_duration(ms) when ms < 1000, do: "#{ms}ms"
  defp format_duration(ms) when ms < 60000, do: "#{Float.round(ms / 1000, 1)}s"
  defp format_duration(ms), do: "#{div(ms, 60000)}m #{rem(div(ms, 1000), 60)}s"
  
  defp calculate_success_rate(activities) do
    total = length(activities)
    
    if total == 0 do
      "N/A"
    else
      successes = Enum.count(activities, &(&1[:outcome] == :success))
      "#{round(successes / total * 100)}%"
    end
  end
  
  defp most_common_intent(activities) do
    activities
    |> Enum.frequencies_by(& &1.intent)
    |> Enum.max_by(fn {_intent, count} -> count end, fn -> {"None", 0} end)
    |> elem(0)
  end
  
  defp avg_duration(activities) do
    durations = activities
                |> Enum.map(& &1[:duration_ms])
                |> Enum.filter(&is_number/1)
    
    case durations do
      [] -> nil
      durations -> round(Enum.sum(durations) / length(durations))
    end
  end
  
  defp format_group_name(group, group_by) do
    case group_by do
      :time -> "Activities at #{group}"
      :file -> "#{group}/"
      _ -> String.capitalize(to_string(group))
    end
  end
end