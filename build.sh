#!/bin/bash
# Unified build script for Render deployment

echo "🔨 Building Eden Platform..."

# Install Node.js dependencies and build dashboard
echo "📦 Building Dashboard..."
cd dashboard
npm install
npm run build
cd ..

# Install Python dependencies for backend
echo "🐍 Installing Backend Dependencies..."
cd backend
pip install -r requirements.txt
cd ..

# Install Python dependencies for blockchain
echo "⛓️ Installing Blockchain Dependencies..."
cd blockchain
pip install -r requirements.txt
cd ..

echo "✅ Build Complete!"
