FROM cassandra:5.0.1

# Install Python and create symlinks first
RUN apt-get update && \
    apt-get install -y python3 python3-distutils && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy backup script first
COPY backup.py /tmp/backup.py
COPY start.sh /start.sh

# Install dependencies and clean up in a single layer
RUN apt-get update && \
    apt-get install -y \
    python3-pip \
    python3-setuptools \
    python3-wheel && \
    pip install --no-cache-dir cassandra-medusa schedule && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/medusa && \
    mv /tmp/backup.py /etc/medusa/backup.py && \
    chmod +x /etc/medusa/backup.py && \
    chmod +x /start.sh

# Create directory for backups
VOLUME ["/etc/medusa", "/var/lib/cassandra/backups"]

# # Add a healthcheck
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#     CMD nodetool status || exit 1

# Set the startup script as the entrypoint
CMD ["/start.sh"]





