defmodule CrodWeb.Components.Navigation do
  use Phoenix.Component

  def navbar(assigns) do
    ~H"""
    <nav class="bg-gray-900 border-b border-blue-500/30 px-6 py-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-8">
          <h1 class="text-2xl font-bold text-blue-400">🧠 CROD Neural</h1>
          <div class="flex space-x-6">
            <.nav_link href="/control" current={@current_page == :control}>
              AI Control
            </.nav_link>
            <.nav_link href="/dashboard" current={@current_page == :dashboard}>
              Dashboard
            </.nav_link>
            <.nav_link href="/neural" current={@current_page == :neural}>
              Neural View
            </.nav_link>
            <.nav_link href="/patterns" current={@current_page == :patterns}>
              Patterns
            </.nav_link>
            <.nav_link href="/memory" current={@current_page == :memory}>
              Memory
            </.nav_link>
            <.nav_link href="/mcp" current={@current_page == :mcp}>
              MCP
            </.nav_link>
            <.nav_link href="/monitoring" current={@current_page == :monitoring}>
              Monitor
            </.nav_link>
          </div>
        </div>
        <div class="flex items-center space-x-4 text-sm">
          <%= if assigns[:status] do %>
            <span class="text-green-400">● <%= @status %></span>
          <% end %>
          <%= if assigns[:extra] do %>
            <%= @extra %>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end

  defp nav_link(assigns) do
    ~H"""
    <a 
      href={@href} 
      class={[
        "pb-1 transition-colors",
        @current && "text-blue-400 border-b-2 border-blue-400" || "text-gray-400 hover:text-white"
      ]}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end