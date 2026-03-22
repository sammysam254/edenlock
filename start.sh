#!/bin/bash
# Unified start script for Render deployment

set -e  # Exit on error

echo "🚀 Starting Eden Platform..."

# Start blockchain server in background
echo "📦 Starting Blockchain Server on port ${BLOCKCHAIN_PORT:-5000}..."
cd /app/blockchain
python3 eden_blockchain_server.py > /tmp/blockchain.log 2>&1 &
BLOCKCHAIN_PID=$!
echo "Blockchain PID: $BLOCKCHAIN_PID"

# Wait for blockchain to be ready
echo "⏳ Waiting for blockchain to start..."
sleep 5

# Start blockchain listener in background
echo "🔄 Starting Blockchain Listener..."
cd /app/backend
python3 eden_blockchain_listener.py > /tmp/listener.log 2>&1 &
LISTENER_PID=$!
echo "Listener PID: $LISTENER_PID"

# Start Next.js dashboard (foreground)
echo "🌐 Starting Dashboard on port ${PORT:-3000}..."
cd /app/dashboard
npm start &
DASHBOARD_PID=$!
echo "Dashboard PID: $DASHBOARD_PID"

echo "✅ All services started!"
echo "Dashboard: http://localhost:${PORT:-3000}"
echo "Blockchain: http://localhost:${BLOCKCHAIN_PORT:-5000}"

# Function to handle shutdown
shutdown() {
    echo "🛑 Shutting down services..."
    kill $BLOCKCHAIN_PID $LISTENER_PID $DASHBOARD_PID 2>/dev/null
    exit 0
}

trap shutdown SIGTERM SIGINT

# Wait for all processes
wait $DASHBOARD_PID
