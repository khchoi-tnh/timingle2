# ============================================
# timingle Backend Dockerfile
# Multi-stage build for optimized production image
# ============================================

# Stage 1: Build
FROM golang:1.22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build API and Worker binaries
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo 'dev')" \
    -o /bin/api ./cmd/api

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo 'dev')" \
    -o /bin/worker ./cmd/worker

# Stage 2: Production - API
FROM alpine:3.19 AS api

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1000 timingle && \
    adduser -u 1000 -G timingle -s /bin/sh -D timingle

# Copy binary and migrations
COPY --from=builder /bin/api /usr/local/bin/api
COPY --from=builder /app/migrations /app/migrations

# Set timezone
ENV TZ=UTC

# Switch to non-root user
USER timingle

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the API
ENTRYPOINT ["/usr/local/bin/api"]

# Stage 3: Production - Worker
FROM alpine:3.19 AS worker

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1000 timingle && \
    adduser -u 1000 -G timingle -s /bin/sh -D timingle

# Copy binary
COPY --from=builder /bin/worker /usr/local/bin/worker

# Set timezone
ENV TZ=UTC

# Switch to non-root user
USER timingle

# Run the worker
ENTRYPOINT ["/usr/local/bin/worker"]
