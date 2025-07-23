# Git-init compatibility image for legacy Tekton git-clone tasks
# This bridges the gap between old Tekton tasks expecting /ko-app/git-init
# and modern git distributions

FROM golang:1.21-alpine AS builder

# Install git and dependencies
RUN apk add --no-cache git

# Copy the go source file
WORKDIR /build
COPY git-init.go .

# Build the git-init binary
RUN go build -o git-init git-init.go

# Final image based on Alpine (minimal)
FROM alpine:3.18

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates openssh-client

# Copy the git-init binary to the expected location
COPY --from=builder /build/git-init /ko-app/git-init
RUN chmod +x /ko-app/git-init

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy git safe directory fix
COPY git-safe-directory-fix.sh /usr/local/bin/git-safe-directory-fix.sh
RUN chmod +x /usr/local/bin/git-safe-directory-fix.sh

# Create a git wrapper that automatically applies the safe directory fix
RUN cp /usr/bin/git /usr/bin/git.real && \
    echo '#!/bin/sh' > /usr/bin/git && \
    echo '/usr/bin/git.real config --global --add safe.directory "*" 2>/dev/null || true' >> /usr/bin/git && \
    echo 'exec /usr/bin/git.real "$@"' >> /usr/bin/git && \
    chmod +x /usr/bin/git

# Create the tekton home directory
RUN mkdir -p /tekton/home && chmod 777 /tekton/home

# Install su-exec for better signal handling (if needed for chown)
RUN apk add --no-cache su-exec

# Set up non-root user (matching Tekton's expectations)
USER 65532:65532

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]