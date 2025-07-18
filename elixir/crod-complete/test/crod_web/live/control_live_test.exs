defmodule CrodWeb.ControlLiveTest do
  use CrodWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders control interface", %{conn: conn} do
    {:ok, view, html} = live(conn, "/control")
    
    assert html =~ "CROD Neural Control"
    assert html =~ "AI Assistant (Claude)"
    assert html =~ "Auto Mode"
  end

  test "can toggle auto mode", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/control")
    
    # Toggle auto mode off
    view
    |> element("button", "Auto Mode ON")
    |> render_click()
    
    assert render(view) =~ "Auto Mode OFF"
    
    # Toggle back on
    view
    |> element("button", "Auto Mode OFF")
    |> render_click()
    
    assert render(view) =~ "Auto Mode ON"
  end

  test "can trigger AI actions", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/control")
    
    # Click analyze button
    view
    |> element("button", "Analyze")
    |> render_click()
    
    # Should show analysis in action log
    assert render(view) =~ "ANALYZE"
    assert render(view) =~ "Analyzing neural network state"
  end

  test "shows real-time updates", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/control")
    
    # Send a brain update event
    send(view.pid, %{
      topic: "brain:updates",
      payload: %{
        neuron_activations: 8500,
        confidence: 0.85
      }
    })
    
    # View should update
    html = render(view)
    assert html =~ "8500"
  end

  test "trinity activation works", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/control")
    
    # Click Trinity button
    view
    |> element("button", "Activate Trinity")
    |> render_click()
    
    # Should show Trinity active
    assert render(view) =~ "TRINITY MODE ACTIVATED"
    assert render(view) =~ "ich bins wieder"
  end
end