# Multi-stage Dockerfile for Eden Platform
# Runs Dashboard (Node.js) + Blockchain (Python) + Listener (Python)

FROM node:18-slim AS node-base

# Install Python
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy all files
COPY . .

# Install Node.js dependencies
WORKDIR /app/dashboard
RUN npm install
RUN npm run build

# Install Python dependencies
WORKDIR /app/backend
RUN pip3 install -r requirements.txt

WORKDIR /app/blockchain
RUN pip3 install -r requirements.txt

# Set working directory
WORKDIR /app

# Make start script executable
RUN chmod +x start.sh

# Expose ports
EXPOSE 3000 5000

# Start all services
CMD ["./start.sh"]
