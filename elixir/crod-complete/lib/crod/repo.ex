defmodule Crod.Repo do
  use Ecto.Repo,
    otp_app: :crod,
    adapter: Ecto.Adapters.Postgres
  # Mangel: Keine Error-Handling/Logging für Datenbankverbindung
  # Verbesserung: Überwachung und Logging ergänzen
end
