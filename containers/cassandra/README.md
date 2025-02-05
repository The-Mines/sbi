# Cassandra with Medusa Backup Container

This container extends the official Cassandra image with Medusa backup capabilities for performing backups to cloud storage.

## Usage

### Basic Run

### Required Environment Variables for AWS
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: Your AWS region (default: us-east-1)

### Medusa Configuration

Create a `medusa.ini` file with your backup configuration:

### Performing Backups

To perform a backup:

### Listing Backups

To list available backups:

## Volumes

The container uses two main volumes:
- `/etc/medusa`: For Medusa configuration
- `/var/lib/cassandra/backups`: For local backup staging

## Health Check

The container includes a health check that verifies Cassandra's status using `nodetool status`. The health check runs every 30 seconds.

## Security Notes

- Never commit AWS credentials to version control
- Consider using IAM roles when running in AWS
- Ensure proper file permissions on mounted configuration files

## Automated Backups

The container includes an automated backup system that:
- Runs a backup daily at the time specified by `BACKUP_TIME` (default: 01:00)
- Creates backups with timestamps in the format: `backup_YYYY-MM-DD-HH-MM`
- Logs all backup operations for monitoring
- Runs an initial backup when the container starts