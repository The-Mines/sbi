FROM cassandra:5.0.1

# Switch to root if you need to install packages
USER root

# Install Python and dependencies
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv 
    # removing cleanup
    # && \
    # apt-get clean && \
    # rm -rf /var/lib/apt/lists/*

# Create Python symlinks and install Medusa
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    pip3 install --no-cache-dir cassandra-medusa schedule

# Make medusa directory & copy in backup script
RUN mkdir -p /etc/medusa
COPY backup.py /etc/medusa/backup.py

# Copy in your custom start script
COPY start.sh /usr/local/bin/start.sh

# Ensure both scripts are executable
RUN chmod +x /etc/medusa/backup.py && \
    chmod +x /usr/local/bin/start.sh

# (Optionally) declare volumes
VOLUME ["/etc/medusa", "/var/lib/cassandra/backups"]

# Switch back to Cassandra user if desired
USER cassandra

# Here we override the entrypoint so that we can run our wrapper script
ENTRYPOINT ["/usr/local/bin/start.sh"]

# The official Cassandra image sets CMD to ["cassandra", "-f"] by default.
# We'll preserve that, but it now goes through our script -> official entrypoint -> cassandra
CMD ["cassandra", "-f"]
