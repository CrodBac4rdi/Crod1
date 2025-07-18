# Build stage
FROM elixir:1.18 AS build

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set build environment
ENV MIX_ENV=prod

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files and install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# Copy config files
COPY config config/

# Compile dependencies
RUN mix deps.compile

# Copy application source
COPY lib lib/
COPY priv priv/
COPY assets assets/

# Compile application
RUN mix compile

# Build assets
RUN mix assets.deploy

# Build release
RUN mix release

# Runtime stage
FROM elixir:1.18-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    openssl \
    libssl3 \
    libncurses6 \
    postgresql-client \
    git \
    curl \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

# Install hex and rebar for runtime
RUN mix local.hex --force && \
    mix local.rebar --force

# Set runtime environment
ENV MIX_ENV=prod
ENV PHX_SERVER=true
ENV SHELL=/bin/bash
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ELIXIR_ERL_OPTIONS="+fnu"

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/crod ./

# Copy patterns data
COPY --from=build /app/priv/patterns ./priv/patterns/
COPY --from=build /app/priv/static ./priv/static/

# Copy entrypoint script from elixir directory
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create auth directory
RUN mkdir -p /root/.crod

# Expose ports
EXPOSE 4000 8888

# Use entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]