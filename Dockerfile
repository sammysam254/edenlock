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

# Copy dashboard files (node_modules and .next excluded by .dockerignore)
COPY dashboard/ dashboard/

# Install dependencies from scratch
WORKDIR /app/dashboard
RUN echo "📦 Installing dependencies from package-lock.json..." && \
    npm ci --no-optional && \
    echo "✅ npm ci completed" && \
    echo "📋 Listing installed packages..." && \
    ls -la node_modules/ | head -20 && \
    echo "🔍 Checking for tailwindcss..." && \
    ls -la node_modules/tailwindcss/ && \
    echo "✅ Tailwindcss found" && \
    echo "🔨 Building Next.js..." && \
    npm run build && \
    echo "✅ Build successful"

# Copy Python requirements
WORKDIR /app
COPY backend/requirements.txt backend/
COPY blockchain/requirements.txt blockchain/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r backend/requirements.txt && \
    pip3 install --no-cache-dir -r blockchain/requirements.txt

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
