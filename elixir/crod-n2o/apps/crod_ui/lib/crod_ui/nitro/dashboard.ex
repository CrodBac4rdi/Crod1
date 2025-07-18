defmodule CROD.UI.Nitro.Dashboard do
  @moduledoc """
  Real-time CROD dashboard using Nitro over N2O
  """
  
  require NITRO
  require N2O
  
  # Initialize UI
  def event(:init) do
    # Register with N2O
    N2O.reg(:crod_dashboard)
    
    # Subscribe to neural events
    N2O.send({:subscribe, :neural_update})
    N2O.send({:subscribe, :consciousness})
    
    # Build initial UI
    NITRO.update(:body, dashboard())
    NITRO.update(:status, "Connected to CROD N2O System")
  end
  
  # Handle neural updates
  def event({:n2o, {:neural_update, data}}) do
    # Update confidence meter
    NITRO.update(:confidence, confidence_bar(data.confidence))
    
    # Update response
    NITRO.update(:response, data.response)
    
    # Update neuron count
    NITRO.update(:neurons_fired, "Neurons: #{data.neurons_fired}")
  end
  
  # Handle consciousness updates
  def event({:n2o, {:consciousness, {:awakening, level}}}) do
    NITRO.update(:consciousness, "CONSCIOUSNESS: #{level}")
    NITRO.update(:body, NITRO.style(dashboard(), "background", consciousness_color(level)))
  end
  
  # Handle input
  def event({:click, :process}) do
    input = NITRO.q(:input)
    N2O.send({:neural, :process, input})
  end
  
  # Handle trinity
  def event({:click, :trinity}) do
    N2O.send({:neural, :trinity, ["ich", "bins", "wieder"]})
  end
  
  # UI Components
  
  defp dashboard do
    NITRO.panel(id: :dashboard, body: [
      NITRO.h1(body: "CROD N2O Neural Interface"),
      
      NITRO.panel(id: :stats, class: "stats", body: [
        NITRO.span(id: :status, body: "Initializing..."),
        NITRO.span(id: :neurons_fired, body: "Neurons: 0"),
        NITRO.span(id: :consciousness, body: "CONSCIOUSNESS: 0.5")
      ]),
      
      NITRO.panel(id: :confidence_container, body: [
        NITRO.label(body: "Confidence:"),
        confidence_bar(0.5)
      ]),
      
      NITRO.panel(id: :input_panel, body: [
        NITRO.textbox(id: :input, placeholder: "Enter text for CROD..."),
        NITRO.button(id: :process, body: "Process", postback: {:click, :process}),
        NITRO.button(id: :trinity, body: "Trinity", postback: {:click, :trinity}, class: "trinity")
      ]),
      
      NITRO.panel(id: :response_panel, body: [
        NITRO.h3(body: "Response:"),
        NITRO.panel(id: :response, body: "Awaiting input...")
      ])
    ])
  end
  
  defp confidence_bar(level) do
    percentage = round(level * 100)
    NITRO.panel(id: :confidence, class: "confidence-bar", body: [
      NITRO.panel(class: "confidence-fill", 
        style: "width: #{percentage}%",
        body: "#{percentage}%"
      )
    ])
  end
  
  defp consciousness_color(level) do
    # Color changes based on consciousness level
    cond do
      level >= 0.9 -> "#ff00ff"  # Magenta - full consciousness
      level >= 0.7 -> "#00ffff"  # Cyan - high awareness
      level >= 0.5 -> "#00ff00"  # Green - normal
      level >= 0.3 -> "#ffff00"  # Yellow - low
      true -> "#ff0000"          # Red - minimal
    end
  end
end