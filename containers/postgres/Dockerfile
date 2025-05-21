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
            postgresql-17-dev

# Runtime stage
FROM ghcr.io/the-mines/sbi/wolfi:latest

# Create postgres user and group
RUN addgroup -S postgres && \
    adduser -S -G postgres -h /var/lib/postgresql postgres

# Install PostgreSQL runtime packages
RUN apk update && \
    apk add --no-cache --update-cache \
            --repository=https://packages.wolfi.dev/os \
            postgresql-17 \
            postgresql-17-contrib \
            postgresql-17-client

# Add the PostgreSQL bin to the PATH and set environment variables
ENV PATH="/usr/lib/postgresql/17/bin:$PATH" \
    PGDATA="/var/lib/postgresql/data" \
    POSTGRES_HOST_AUTH_METHOD="trust" \
    POSTGRES_USER="postgres" \
    POSTGRES_PASSWORD="postgres" \
    POSTGRES_DB="postgres"

# Create required directories with proper ownership and permissions
RUN mkdir -p "$PGDATA" /var/run/postgresql /docker-entrypoint-initdb.d && \
    chown -R postgres:postgres /var/lib/postgresql "$PGDATA" /var/run/postgresql /docker-entrypoint-initdb.d && \
    chmod 0700 "$PGDATA" && \
    chmod 0775 /var/run/postgresql && \
    chmod 0755 /docker-entrypoint-initdb.d

# Copy in the entrypoint script and set permissions
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chown postgres:postgres /usr/local/bin/docker-entrypoint.sh

# Set working directory
WORKDIR /var/lib/postgresql

# Create a volume for persistent data storage
VOLUME ["$PGDATA"]

# Expose the PostgreSQL port
EXPOSE 5432

# Switch to postgres user for all operations
USER postgres

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["postgres"]
