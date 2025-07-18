FROM elixir:1.17-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm \
    curl \
    postgresql-client

# Create app directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Set build env
ENV MIX_ENV=prod

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy application code
COPY . .

# Build assets if they exist
RUN if [ -d "assets" ]; then \
        cd assets && npm install && cd .. && \
        mix assets.deploy; \
    fi

# Compile application
RUN mix compile

# Create release
RUN mix release

# Start a new stage for runtime
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs \
    curl \
    bash

# Create non-root user
RUN addgroup -g 1000 crod && \
    adduser -D -u 1000 -G crod crod

# Copy release from builder
COPY --from=builder --chown=crod:crod /app/_build/prod/rel/crod /app

# Set runtime environment
ENV HOME=/app
WORKDIR /app
USER crod

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Start the application
CMD ["/app/bin/crod", "start"]
