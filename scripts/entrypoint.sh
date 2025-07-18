#!/bin/sh
set -e

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
while ! pg_isready -h postgres -U postgres; do
  sleep 1
done

echo "PostgreSQL is ready!"

# Run migrations
echo "Running database migrations..."
mix ecto.create
mix ecto.migrate

# Generate VS Code auth token if not exists
if [ ! -f "/root/.crod/auth.token" ]; then
  mkdir -p /root/.crod
  openssl rand -base64 32 > /root/.crod/auth.token
  echo "Generated VS Code auth token"
fi

# Start the Phoenix server
echo "Starting CROD Brain..."
exec mix phx.server