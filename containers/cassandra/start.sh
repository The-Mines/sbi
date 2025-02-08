#!/bin/bash

# Function to start backup script with retry
start_backup_script() {
    while true; do
        echo "Starting backup script..."
        python3 /etc/medusa/backup.py || echo "Backup script exited with error, restarting in 60 seconds..."
        sleep 60
    done
}

# Start backup script only if ENABLE_BACKUPS is true
if [ "${ENABLE_BACKUPS,,}" = "true" ]; then
    echo "Backups enabled, starting backup script..."
    start_backup_script &
    BACKUP_PID=$!
else
    echo "Backups disabled, skipping backup script"
fi

# Start Cassandra in the foreground
exec cassandra -f