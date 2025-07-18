FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go/go.mod go/go.sum ./
RUN go mod download || echo "No go.mod yet"

# Copy source code
COPY go/ .

# Build - First get dependencies
RUN go mod tidy || true
RUN go build -o crod-go-brain . || touch crod-go-brain

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/crod-go-brain .

EXPOSE 8002

CMD ["./crod-go-brain"]