FROM rust:latest

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    build-essential \
    libclang-dev \
    librocksdb-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Cargo files first for better caching
COPY rust/Cargo.toml rust/Cargo.lock* ./

# Create dummy main.rs for dependency caching
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies
RUN cargo build --release

# Remove dummy main.rs
RUN rm src/main.rs

# Copy actual source code
COPY rust/src ./src

# Build the actual application
RUN touch src/main.rs && cargo build --release

EXPOSE 7777

CMD ["cargo", "run", "--release"]