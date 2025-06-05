# Build stage
FROM ghcr.io/the-mines/sbi/wolfi:latest AS builder

# Install PostgreSQL 17 and development tools
RUN apk update && \
    apk add --no-cache --virtual .pg-build-deps build-base && \
    apk add --no-cache --update-cache \
            --repository=https://packages.wolfi.dev/os \
            postgresql-17 \
            postgresql-17-contrib \
            postgresql-17-client \
            postgresql-17-dev \
            busybox

# Runtime stage
FROM ghcr.io/the-mines/sbi/wolfi:latest

# Create postgres user and group
RUN addgroup -S postgres && \
    adduser -S -G postgres -h /var/lib/postgresql postgres

# Install PostgreSQL runtime packages and required extras to mirror Chainguard config
RUN apk update && \
    apk add --no-cache --update-cache \
            --repository=https://packages.wolfi.dev/os \
            postgresql-17 \
            postgresql-17-contrib \
            postgresql-17-client \
            gosu \
            postgresql-oci-entrypoint \
            libpq \
            pgaudit \
            busybox \
            glibc-locale-en
            posix-libc-utils


# Add the PostgreSQL bin to the PATH and set environment variables
ENV PATH="/usr/lib/postgresql/17/bin:$PATH" \
    PGDATA="/var/lib/postgresql/data" \
    LANG="en_US.UTF-8"
    #POSTGRES_HOST_AUTH_METHOD="trust" \
    #POSTGRES_USER="postgres" \
    #POSTGRES_PASSWORD="postgres" \
    #POSTGRES_DB="postgres"

# Create required directories with proper ownership and permissions
RUN mkdir -p "$PGDATA" /var/run/postgresql /docker-entrypoint-initdb.d && \
    chown -R root:root /var/lib/postgresql "$PGDATA" /var/run/postgresql /docker-entrypoint-initdb.d && \
    chmod 0700 "$PGDATA" && \
    chmod 0775 /var/run/postgresql && \
    chmod 0755 /docker-entrypoint-initdb.d

# Set working directory
WORKDIR /var/lib/postgresql

# Create a volume for persistent data storage
VOLUME ["$PGDATA"]

# Expose the PostgreSQL port
EXPOSE 5432

# Run as root (UID 0) to mirror Chainguard config

# Use the official postgresql-oci-entrypoint as entrypoint
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh postgres"]

# Default command
#CMD ["postgres"]

