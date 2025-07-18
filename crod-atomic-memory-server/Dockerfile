# CROD Layered Atomic Memory Server
FROM node:20-alpine

# Install build dependencies for better-sqlite3
RUN apk add --no-cache python3 make g++ sqlite

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy built files
COPY dist/ ./dist/

# Create data directory with proper permissions
RUN mkdir -p /data && \
    chmod 755 /data

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD sqlite3 /data/layered-atomic.db "SELECT COUNT(*) FROM base_atoms" || exit 1

# Environment variables
ENV CROD_LAYERED_DB_PATH=/data/layered-atomic.db
ENV NODE_ENV=production

# MCP server listens on stdio, not a network port
# But we'll expose a port for future HTTP health endpoint
EXPOSE 3000

# Volume for persistent data
VOLUME ["/data"]

# Run as non-root user
RUN addgroup -g 1001 -S crod && \
    adduser -S crod -u 1001 -G crod
USER crod

# Start the MCP server
CMD ["node", "dist/index-layered.js"]