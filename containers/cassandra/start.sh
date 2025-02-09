#!/bin/bash
set -e

#
# 1. Start backup script in the background (only if enabled).
#
if [ "${ENABLE_BACKUPS,,}" = "true" ]; then
    echo "Backups enabled; launching backup.py in background..."
    python3 /etc/medusa/backup.py &
fi

#
# 2. Chain to the real Cassandra entrypoint script.
#    The official Cassandra image’s /docker-entrypoint.sh sets up the environment correctly
#    before calling `exec` on Cassandra. So we just pass in whatever arguments we got.
#
exec /docker-entrypoint.sh "$@"
