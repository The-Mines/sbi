#!/bin/sh
set -e

# Initialize database if data directory is empty
if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
  echo "Initializing PostgreSQL database in $PGDATA..."

  # Initialize the database
  initdb --username="$POSTGRES_USER" -D "$PGDATA"

  # Configure authentication based on environment
  if [ "$POSTGRES_HOST_AUTH_METHOD" = "trust" ]; then
    echo "Setting authentication method to trust..."
    cat > "$PGDATA/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               trust
EOF
  fi

  # Run initialization scripts if they exist
  if [ -d /docker-entrypoint-initdb.d ] && [ "$(ls -A /docker-entrypoint-initdb.d 2>/dev/null)" ]; then
    echo "Running initialization scripts..."
    pg_ctl -D "$PGDATA" -o "-c listen_addresses=localhost" -w start

    # Execute all SQL and shell scripts in initialization directory
    for f in /docker-entrypoint-initdb.d/*; do
      case "$f" in
        *.sql)
          echo "Running SQL script: $f"
          psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
          ;;
        *.sh)
          echo "Running shell script: $f"
          . "$f"
          ;;
        *)
          echo "Ignoring $f"
          ;;
      esac
    done

    pg_ctl -D "$PGDATA" -m fast -w stop
  fi
fi

# Start PostgreSQL if the first argument is 'postgres'
if [ "$1" = "postgres" ]; then
  echo "Starting PostgreSQL server..."
  exec postgres -D "$PGDATA"
else
  # Otherwise execute the given command
  exec "$@"
fi
