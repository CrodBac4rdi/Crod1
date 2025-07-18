defmodule Crod.Mailer do
  use Swoosh.Mailer, otp_app: :crod
  # Mangel: Keine Konfiguration für Mail-Provider, keine Error-Handling/Logging
  # Verbesserung: Konfiguration und Logging ergänzen
end
