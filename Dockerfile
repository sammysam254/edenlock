# Multi-stage Dockerfile for Eden Platform
FROM node:20-bullseye-slim

# Install Python and required tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy ALL dashboard files (simpler and more reliable)
COPY dashboard/ dashboard/

# Install dependencies and build
WORKDIR /app/dashboard
RUN echo "📦 Installing Node.js dependencies..." && \
    npm ci && \
    echo "✅ Dependencies installed" && \
    echo "📋 Verifying tailwindcss..." && \
    npm list tailwindcss && \
    echo "🔨 Building Next.js application..." && \
    npm run build && \
    echo "✅ Build completed successfully"

# Copy Python requirements
WORKDIR /app
COPY backend/requirements.txt backend/
COPY blockchain/requirements.txt blockchain/

# Install Python dependencies
RUN echo "🐍 Installing Python dependencies..." && \
    pip3 install --no-cache-dir -r backend/requirements.txt && \
    pip3 install --no-cache-dir -r blockchain/requirements.txt && \
    echo "✅ Python dependencies installed"

# Copy rest of the application
COPY backend/ backend/
COPY blockchain/ blockchain/
COPY start.sh .

# Make start script executable
RUN chmod +x start.sh

# Expose ports
EXPOSE 3000 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start all services
CMD ["bash", "./start.sh"]
