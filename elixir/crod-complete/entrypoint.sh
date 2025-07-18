#!/bin/bash
set -e

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
while ! pg_isready -h postgres -U postgres; do
  sleep 1
done

echo "PostgreSQL is ready!"

# Generate VS Code auth token if not exists
if [ ! -f "/root/.crod/auth.token" ]; then
  mkdir -p /root/.crod
  openssl rand -base64 32 > /root/.crod/auth.token
  echo "Generated VS Code auth token"
fi

# For Elixir releases we need different commands
if [ -f "bin/crod" ]; then
  # We're in a release
  if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Running database migrations..."
    bin/crod eval "Crod.Release.migrate()"
    echo "Migrations completed successfully"
    exit 0
  fi
  
  echo "Starting CROD Brain (Release)..."
  exec bin/crod start
else
  # Development mode with mix
  if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Running database migrations..."
    mix ecto.create
    mix ecto.migrate
    echo "Migrations completed successfully"
    exit 0
  fi
  
  echo "Starting CROD Brain (Mix)..."
  exec mix phx.server
fi