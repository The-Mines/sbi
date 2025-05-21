# PostgreSQL Container

This container provides PostgreSQL 17 based on the Wolfi Linux distribution. It's designed with security in mind, running as a non-root user and following best practices for containerized PostgreSQL.

## Basic Usage

```bash
# Run PostgreSQL with default settings
docker run -d --name postgres -p 5432:5432 ghcr.io/the-mines/sbi/postgres:latest

# Connect to the server
psql -h localhost -U postgres
```

## Environment Variables

The container supports these configuration options:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | Default username |
| `POSTGRES_PASSWORD` | `postgres` | Default password |
| `POSTGRES_DB` | `postgres` | Default database name |
| `POSTGRES_HOST_AUTH_METHOD` | `trust` | Authentication method |
| `PGDATA` | `/var/lib/postgresql/data` | Data directory location |

## Data Persistence

To persist your PostgreSQL data across container restarts, mount a volume to the `PGDATA` path:

```bash
# Using a named volume
docker run -d --name postgres \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest

# Using a host directory
docker run -d --name postgres \
  -v /path/on/host:/var/lib/postgresql/data \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

In Kubernetes, use a PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  # ...
  template:
    # ...
    spec:
      containers:
      - name: postgres
        image: ghcr.io/the-mines/sbi/postgres:latest
        volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: postgres-data
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-data-pvc
```

## PostgreSQL Data Directory Structure

When using persistent volumes, it's important to understand PostgreSQL's data directory structure:

### Data Directory Layout

The PostgreSQL data directory (`PGDATA`) contains:

```
/var/lib/postgresql/data/
├── base/              # Database files
├── global/            # Global tables
├── pg_commit_ts/      # Commit timestamp info
├── pg_dynshmem/       # Dynamic shared memory
├── pg_logical/        # Logical replication
├── pg_multixact/      # Multitransaction status
├── pg_notify/         # LISTEN/NOTIFY status
├── pg_replslot/       # Replication slot data
├── pg_serial/         # Serializable transaction data
├── pg_snapshots/      # Exported snapshots
├── pg_stat/           # Statistics subsystem
├── pg_stat_tmp/       # Temporary statistics
├── pg_subtrans/       # Subtransaction info
├── pg_tblspc/         # Tablespace symlinks
├── pg_twophase/       # Prepared transactions
├── pg_wal/            # Write ahead log (WAL)
├── pg_xact/           # Transaction commit status
├── postgresql.auto.conf # Auto-updated configuration
├── postgresql.conf    # Configuration file
├── pg_hba.conf        # Client authentication config
└── pg_ident.conf      # User name mapping
```

### Persistence Strategies

#### Strategy 1: Mount the Entire Data Directory (Recommended)

This is the simplest approach, mounting a volume to the entire `/var/lib/postgresql/data` directory:

```bash
docker run -d --name postgres \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

**Pros:**
- Simple configuration
- Everything is persisted
- No need to create subdirectories

**Cons:**
- Cannot separate WAL from data for performance tuning
- May not be optimal for some advanced configurations

#### Strategy 2: Separate Data and WAL Volumes (Advanced)

For high-performance setups, you might want to place WAL files on separate storage:

```bash
# Create directories with proper permissions
mkdir -p /postgres/data /postgres/wal
chown -R 999:999 /postgres  # 999 is typically the postgres UID/GID

# Run with separate volumes
docker run -d --name postgres \
  -v /postgres/data:/var/lib/postgresql/data \
  -v /postgres/wal:/var/lib/postgresql/data/pg_wal \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

**Important:** When using this approach, you must:
1. Create the initial directories before starting PostgreSQL
2. Set proper ownership (postgres user)
3. Start PostgreSQL with empty directories for first initialization

In Kubernetes, this would look like:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  # ...
  template:
    # ...
    spec:
      initContainers:
      - name: setup-directories
        image: busybox
        command: ['sh', '-c', 'mkdir -p /bitnami/postgresql/data /bitnami/postgresql/wal && chmod 700 /bitnami/postgresql/data /bitnami/postgresql/wal']
        volumeMounts:
        - name: data
          mountPath: /bitnami/postgresql/data
        - name: wal
          mountPath: /bitnami/postgresql/wal
      containers:
      - name: postgres
        image: ghcr.io/the-mines/sbi/postgres:latest
        env:
        - name: PGDATA
          value: /var/lib/postgresql/data
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: wal
          mountPath: /var/lib/postgresql/data/pg_wal
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-data
      - name: wal
        persistentVolumeClaim:
          claimName: postgres-wal
```

#### Strategy 3: Using a PGDATA Subdirectory for Docker Mounts

If you're encountering permission issues with Docker volumes on some hosts, you can create a subdirectory inside the data volume:

```bash
docker run -d --name postgres \
  -v postgres_data:/var/lib/postgresql \
  -e PGDATA=/var/lib/postgresql/pgdata \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

This ensures that Docker doesn't mount a volume directly to the PostgreSQL data directory, avoiding permission issues on some systems.

### Performance Considerations

1. **WAL Files**: For high-write applications, place WAL files (`pg_wal`) on fast storage (SSD/NVMe)
2. **Tables**: Large tables in the `base` directory are good candidates for separate volumes
3. **Tablespaces**: For large databases, use PostgreSQL tablespaces to place tables on different storage

### Backup Considerations

When using persistent volumes, consider these backup options:

1. **Volume Snapshots**: Take snapshots of the persistent volumes
2. **pg_basebackup**: Use PostgreSQL's built-in backup tool
3. **WAL Archiving**: Set up continuous WAL archiving for point-in-time recovery

Example configuration to enable WAL archiving:

```bash
docker run -d --name postgres \
  -v postgres_data:/var/lib/postgresql/data \
  -v postgres_archive:/var/lib/postgresql/archive \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest

# Then connect and configure:
docker exec -it postgres psql -U postgres -c "ALTER SYSTEM SET archive_mode = on;"
docker exec -it postgres psql -U postgres -c "ALTER SYSTEM SET archive_command = 'cp %p /var/lib/postgresql/archive/%f';"
docker exec -it postgres psql -U postgres -c "SELECT pg_reload_conf();"
```

## Adding Initialization Scripts

The container automatically runs scripts found in `/docker-entrypoint-initdb.d/` when the database is first initialized. Both SQL (`.sql`) and shell scripts (`.sh`) are supported.

```bash
# Mount a directory with init scripts
docker run -d --name postgres \
  -v ./init-scripts:/docker-entrypoint-initdb.d \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

Example initialization scripts:

**1. create-schema.sql**
```sql
CREATE SCHEMA app;
CREATE TABLE app.users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

**2. seed-data.sql**
```sql
INSERT INTO app.users (username, email) VALUES
  ('admin', 'admin@example.com'),
  ('user1', 'user1@example.com'),
  ('user2', 'user2@example.com');
```

**3. setup-permissions.sh**
```bash
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE app_readonly WITH LOGIN PASSWORD 'readonly';
  GRANT USAGE ON SCHEMA app TO app_readonly;
  GRANT SELECT ON ALL TABLES IN SCHEMA app TO app_readonly;
EOSQL
```

## Common PostgreSQL Workflows

### Backup and Restore

**Backup:**
```bash
# Backup a database to a file
docker exec postgres pg_dump -U postgres mydatabase > backup.sql

# Backup with compression
docker exec postgres pg_dump -U postgres mydatabase | gzip > backup.sql.gz
```

**Restore:**
```bash
# Restore from a file
cat backup.sql | docker exec -i postgres psql -U postgres -d mydatabase

# Restore from compressed backup
gunzip -c backup.sql.gz | docker exec -i postgres psql -U postgres -d mydatabase
```

### Creating Additional Users and Databases

```bash
# Create a new database
docker exec -it postgres psql -U postgres -c "CREATE DATABASE appdb;"

# Create a new user with password
docker exec -it postgres psql -U postgres -c "CREATE USER appuser WITH ENCRYPTED PASSWORD 'secure_password';"

# Grant privileges
docker exec -it postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;"
```

### Upgrading PostgreSQL

When upgrading to a new version, you need to use `pg_upgrade` or perform a dump/restore:

```bash
# Dump from old version
docker exec old_postgres pg_dumpall -U postgres > full_backup.sql

# Restore to new version
cat full_backup.sql | docker exec -i new_postgres psql -U postgres
```

### Optimizing Performance

You can adjust PostgreSQL configuration by mounting a custom `postgresql.conf` file:

```bash
docker run -d --name postgres \
  -v ./custom-config/postgresql.conf:/var/lib/postgresql/data/postgresql.conf \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  ghcr.io/the-mines/sbi/postgres:latest
```

Common performance settings:
```
# Memory settings
shared_buffers = 1GB            # 25% of available RAM
effective_cache_size = 3GB      # 75% of available RAM
work_mem = 32MB                 # For complex sorts/joins
maintenance_work_mem = 256MB    # For maintenance operations

# Query planner
random_page_cost = 1.1          # For SSD storage
effective_io_concurrency = 200  # For SSD storage

# Write-ahead log
wal_buffers = 16MB              # Reasonable value for most workloads
```

## Security Considerations

- The container runs as the `postgres` user, not as root
- Set a strong password for the `postgres` user in production
- Consider using more restrictive `pg_hba.conf` settings in production
- Use network isolation in Kubernetes deployments
- Set resource limits to prevent denial-of-service conditions

## Troubleshooting

### Check PostgreSQL Logs
```bash
docker logs postgres
```

### Connect to Running Container
```bash
docker exec -it postgres bash
```

### Check PostgreSQL Status
```bash
docker exec postgres pg_isready
```

### Inspect Database
```bash
docker exec -it postgres psql -U postgres
```
