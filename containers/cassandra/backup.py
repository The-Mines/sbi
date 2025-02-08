import os
import time
import schedule
import logging
from datetime import datetime
import subprocess

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Default backup settings
DEFAULT_INTERVAL_HOURS = 12
DEFAULT_BACKUP_TIMES = '00:00,12:00'

# Backup configuration from environment variables
BACKUP_MODE = os.getenv('BACKUP_MODE', 'interval')  # Default to interval mode
BACKUP_TIMES = os.getenv('BACKUP_TIMES', DEFAULT_BACKUP_TIMES)  # Default times if using daily mode
try:
    BACKUP_INTERVAL_HOURS = int(os.getenv('BACKUP_INTERVAL_HOURS', str(DEFAULT_INTERVAL_HOURS)))
except ValueError:
    logger.error(f"Invalid BACKUP_INTERVAL_HOURS value. Using default: {DEFAULT_INTERVAL_HOURS}")
    BACKUP_INTERVAL_HOURS = DEFAULT_INTERVAL_HOURS

# Ensure interval is never less than 1 hour
if BACKUP_INTERVAL_HOURS < 1:
    logger.error(f"Invalid interval hours. Using default: {DEFAULT_INTERVAL_HOURS}")
    BACKUP_INTERVAL_HOURS = DEFAULT_INTERVAL_HOURS

def check_medusa_config():
    """Verify medusa configuration exists"""
    if not os.path.exists('/etc/medusa/medusa.ini'):
        logger.error("Medusa configuration file not found at /etc/medusa/medusa.ini")
        return False
    return True

def validate_time_format(time_str):
    """Validate time string format (HH:MM)"""
    try:
        for time_value in time_str.split(','):
            datetime.strptime(time_value.strip(), '%H:%M')
        return True
    except ValueError:
        return False

def run_medusa_backup():
    """Execute medusa backup with error handling"""
    try:
        if not check_medusa_config():
            return False

        timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M")
        backup_name = f"backup_{timestamp}"

        logger.info(f"Starting backup: {backup_name}")

        # Run medusa backup command
        result = subprocess.run(
            ['medusa', 'backup', f'--backup-name={backup_name}'],
            capture_output=True,
            text=True,
            check=True
        )

        # Log the output from medusa
        if result.stdout:
            logger.info("Medusa Output:")
            for line in result.stdout.splitlines():
                logger.info(f"Medusa: {line}")

        if result.stderr:
            logger.warning("Medusa Warnings/Errors:")
            for line in result.stderr.splitlines():
                logger.warning(f"Medusa: {line}")

        logger.info(f"Backup completed successfully: {backup_name}")
        return True

    except subprocess.CalledProcessError as e:
        logger.error(f"Backup failed: {e}")
        if e.stdout:
            logger.info("Medusa Output:")
            for line in e.stdout.splitlines():
                logger.info(f"Medusa: {line}")
        if e.stderr:
            logger.error("Medusa Error Output:")
            for line in e.stderr.splitlines():
                logger.error(f"Medusa: {line}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error during backup: {str(e)}")
        return False

def schedule_interval_backups():
    """Schedule backups at regular intervals"""
    schedule.every(BACKUP_INTERVAL_HOURS).hours.do(run_medusa_backup)
    logger.info(f"Scheduled backups every {BACKUP_INTERVAL_HOURS} hours")

def schedule_daily_backups(backup_times):
    """Schedule multiple daily backups at specific times"""
    for backup_time in backup_times:
        schedule.every().day.at(backup_time.strip()).do(run_medusa_backup)
        logger.info(f"Scheduled daily backup for {backup_time.strip()}")

def main():
    logger.info("Starting backup scheduler")
    logger.info(f"Backup mode: {BACKUP_MODE}")

    if BACKUP_MODE == 'interval':
        schedule_interval_backups()
    elif BACKUP_MODE == 'daily':
        if not validate_time_format(BACKUP_TIMES):
            logger.error(f"Invalid backup times format: {BACKUP_TIMES}. Using default: {DEFAULT_BACKUP_TIMES}")
            backup_times = DEFAULT_BACKUP_TIMES.split(',')
        else:
            backup_times = BACKUP_TIMES.split(',')
        schedule_daily_backups(backup_times)
    else:
        logger.error(f"Invalid backup mode: {BACKUP_MODE}. Using interval mode with {DEFAULT_INTERVAL_HOURS} hour interval.")
        schedule_interval_backups()

    # Run first backup immediately
    logger.info("Running initial backup")
    run_medusa_backup()

    # Keep script running
    while True:
        try:
            schedule.run_pending()
            time.sleep(60)
        except KeyboardInterrupt:
            logger.info("Backup scheduler stopped by user")
            break
        except Exception as e:
            logger.error(f"Error in scheduler loop: {str(e)}")
            time.sleep(60)

if __name__ == "__main__":
    main()
