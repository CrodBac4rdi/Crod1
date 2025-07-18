#!/usr/bin/env bash

# CROD Visual Command Center Launcher
echo "🧠 Starting CROD Visual Command Center..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create auth token directory if not exists
mkdir -p ~/.crod

# Generate auth token if not exists
if [ ! -f ~/.crod/auth.token ]; then
    echo "🔐 Generating VS Code auth token..."
    openssl rand -base64 32 > ~/.crod/auth.token
    echo "✅ Auth token created at ~/.crod/auth.token"
fi

echo ""
echo "📦 Building and starting services..."
echo ""

# Start all services
docker-compose up -d --build

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✅ All services started successfully!"
    echo ""
    echo "🎯 Access points:"
    echo "   • Web UI:     http://localhost:4000"
    echo "   • WebSocket:  ws://localhost:8888"
    echo "   • Database:   localhost:5432"
    echo ""
    echo "🔑 VS Code Auth Token:"
    cat ~/.crod/auth.token
    echo ""
    echo ""
    echo "📝 To connect VS Code:"
    echo "   1. Install CROD extension (if available)"
    echo "   2. Use the auth token above"
    echo "   3. Connect to ws://localhost:8888"
    echo ""
    echo "🛑 To stop: ./stop.sh"
    echo ""
    
    # Open browser
    if command -v xdg-open > /dev/null; then
        echo "🌐 Opening browser..."
        sleep 2
        xdg-open http://localhost:4000
    elif command -v open > /dev/null; then
        echo "🌐 Opening browser..."
        sleep 2
        open http://localhost:4000
    fi
else
    echo "❌ Failed to start services. Check logs with:"
    echo "   docker-compose logs"
    exit 1
fi