FROM node:20-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache \
    curl \
    python3 \
    make \
    g++ \
    bash

# Copy package files (adjusted for new context)
COPY package*.json ./

# Install dependencies
RUN npm ci || npm install

# Copy application code
COPY . .

# Create data directory
RUN mkdir -p /app/data

# Create health check endpoint
RUN echo '{"status":"healthy"}' > /app/health.json

EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8888/health || exit 1

CMD ["node", "core/crod-brain.js"]