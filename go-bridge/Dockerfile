FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY main.go go.mod* go.sum* ./
RUN go mod init claude-crod-bridge || true
RUN go build -o bridge main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/bridge .

EXPOSE 9090
CMD ["./bridge"]