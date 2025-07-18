defmodule CrodWeb.LandingLive do
  @moduledoc """
  CROD Neural Framework - Landing Page that redirects to control
  """
  use CrodWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Redirect to the new main interface
    {:ok, push_navigate(socket, to: "/main")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white flex items-center justify-center">
      <div class="text-center">
        <div class="text-4xl mb-4">🧠</div>
        <p class="text-gray-400">Redirecting to CROD Control...</p>
      </div>
    </div>
    """
  end

end