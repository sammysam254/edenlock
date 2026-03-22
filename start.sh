#!/bin/bash
# Unified start script for Render deployment

echo "🚀 Starting Eden Platform..."

# Start blockchain server in background
echo "📦 Starting Blockchain Server on port 5000..."
cd blockchain && python eden_blockchain_server.py &
BLOCKCHAIN_PID=$!

# Wait for blockchain to be ready
sleep 5

# Start blockchain listener in background
echo "🔄 Starting Blockchain Listener..."
cd ../backend && python eden_blockchain_listener.py &
LISTENER_PID=$!

# Start Next.js dashboard (foreground)
echo "🌐 Starting Dashboard on port 3000..."
cd ../dashboard && npm start &
DASHBOARD_PID=$!

# Wait for all processes
wait $BLOCKCHAIN_PID $LISTENER_PID $DASHBOARD_PID
