#!/usr/bin/env bash
set -e

echo "🔄 CROD Neural Framework - System Reset"
echo "======================================"

cd "$(dirname "$0")/../docker"

echo "🛑 Stopping all services..."
docker-compose down --remove-orphans

echo "🗑️ Removing containers and volumes..."
docker-compose down -v

echo "🧹 Cleaning up Docker resources..."
docker system prune -f

echo "🔄 Rebuilding and starting fresh..."
docker-compose up --build -d

echo "✅ CROD system has been reset and restarted!"
echo "Visit http://localhost:4000 when ready"