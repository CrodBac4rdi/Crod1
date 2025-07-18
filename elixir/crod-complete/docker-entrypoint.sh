#!/bin/bash
set -e

echo "🧠 CROD Elixir/Phoenix - Starting initialization..."

# Wait for PostgreSQL using DATABASE_URL
echo "⏳ Waiting for PostgreSQL..."
# Extract connection info from DATABASE_URL if available
if [ -n "$DATABASE_URL" ]; then
  export PGHOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
  export PGPORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
  export PGUSER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
fi

while ! pg_isready -h ${PGHOST:-postgres} -p ${PGPORT:-5432} -U ${PGUSER:-postgres}; do
  echo "PostgreSQL not ready, waiting..."
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get || true
mix deps.update --all || true

# Compile dependencies first
echo "🔨 Compiling dependencies..."
mix deps.compile

# Setup database
echo "🗄️ Setting up database..."
# Increase timeout for database operations
export POOL_SIZE=10
export DB_TIMEOUT=60000
mix ecto.create || true
mix ecto.migrate || true

# Install assets if directory exists
if [ -d "assets" ]; then
  echo "🎨 Installing assets..."
  cd assets && npm install && cd ..
fi

# Start the application
echo "🚀 Starting Phoenix server..."
exec mix phx.server