defmodule CrodWeb.HealthController do
  use CrodWeb, :controller

  def index(conn, _params) do
    # Check if core services are running
    brain_status = check_brain_status()
    db_status = check_database_status()
    
    status = if brain_status == :ok and db_status == :ok do
      "healthy"
    else
      "unhealthy"
    end
    
    json(conn, %{
      status: status,
      services: %{
        brain: brain_status,
        database: db_status,
        neurons: get_neuron_count(),
        uptime: get_uptime()
      },
      timestamp: DateTime.utc_now()
    })
  end

  defp check_brain_status do
    try do
      case Process.whereis(Crod.Brain) do
        nil -> :not_running
        pid when is_pid(pid) -> 
          if Process.alive?(pid), do: :ok, else: :dead
      end
    rescue
      _ -> :error
    end
  end

  defp check_database_status do
    try do
      Ecto.Adapters.SQL.query(Crod.Repo, "SELECT 1", [])
      :ok
    rescue
      _ -> :error
    end
  end

  defp get_neuron_count do
    try do
      state = Crod.Brain.get_state()
      map_size(state.neurons)
    rescue
      _ -> 0
    end
  end

  defp get_uptime do
    {uptime, _} = :erlang.statistics(:wall_clock)
    seconds = div(uptime, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    
    "#{hours}h #{rem(minutes, 60)}m #{rem(seconds, 60)}s"
  end
end