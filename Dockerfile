# Multi-stage Dockerfile for Eden Platform
# Runs Dashboard (Node.js) + Blockchain (Python) + Listener (Python)

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

# Set working directory
WORKDIR /app

# Copy entire project
COPY . .

# Install Node.js dependencies
WORKDIR /app/dashboard
RUN npm ci

# Build Next.js app
RUN npm run build

# Remove dev dependencies after build
RUN npm prune --production

# Install Python dependencies
WORKDIR /app
RUN pip3 install --no-cache-dir -r backend/requirements.txt
RUN pip3 install --no-cache-dir -r blockchain/requirements.txt

# Make start script executable
RUN chmod +x start.sh

# Expose ports
EXPOSE 3000 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start all services
CMD ["bash", "./start.sh"]
