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

# Backup configuration from environment variables
BACKUP_MODE = os.getenv('BACKUP_MODE', 'interval')  # Changed default to 'interval'
BACKUP_TIMES = os.getenv('BACKUP_TIMES', '00:00,12:00')  # Default times if using daily mode
BACKUP_INTERVAL_HOURS = int(os.getenv('BACKUP_INTERVAL_HOURS', '12'))  # Changed default to 12 hours

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

        result = subprocess.run(
            ['medusa', 'backup', f'--backup-name={backup_name}'],
            capture_output=True,
            text=True,
            check=True
        )

        logger.info(f"Backup completed successfully: {backup_name}")
        logger.debug(result.stdout)
        return True

    except subprocess.CalledProcessError as e:
        logger.error(f"Backup failed: {e}")
        logger.error(f"Error output: {e.stderr}")
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
        if BACKUP_INTERVAL_HOURS < 1:
            logger.error("Invalid interval hours. Using default: 12")
            BACKUP_INTERVAL_HOURS = 12
        schedule_interval_backups()

    elif BACKUP_MODE == 'daily':
        if not validate_time_format(BACKUP_TIMES):
            logger.error(f"Invalid backup times format: {BACKUP_TIMES}. Using default: 00:00,12:00")
            backup_times = ["00:00", "12:00"]
        else:
            backup_times = BACKUP_TIMES.split(',')
        schedule_daily_backups(backup_times)

    else:
        logger.error(f"Invalid backup mode: {BACKUP_MODE}. Using interval mode.")
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
