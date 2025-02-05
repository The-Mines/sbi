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

# Get backup time from environment variable or use default
BACKUP_TIME = os.getenv('BACKUP_TIME', '01:00')

def check_medusa_config():
    """Verify medusa configuration exists"""
    if not os.path.exists('/etc/medusa/medusa.ini'):
        logger.error("Medusa configuration file not found at /etc/medusa/medusa.ini")
        return False
    return True

def validate_time_format(time_str):
    """Validate time string format (HH:MM)"""
    try:
        datetime.strptime(time_str, '%H:%M')
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

        # Use subprocess instead of os.system for better control and security
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

def main():
    logger.info("Starting backup scheduler")

    # Validate backup time format
    if not validate_time_format(BACKUP_TIME):
        logger.error(f"Invalid BACKUP_TIME format: {BACKUP_TIME}. Using default: 01:00")
        backup_time = "01:00"
    else:
        backup_time = BACKUP_TIME

    # Schedule backup at specified time every day
    schedule.every().day.at(backup_time).do(run_medusa_backup)
    logger.info(f"Scheduled daily backup for {backup_time}")

    # Run first backup immediately
    logger.info("Running initial backup")
    run_medusa_backup()

    # Keep script running
    while True:
        try:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
        except KeyboardInterrupt:
            logger.info("Backup scheduler stopped by user")
            break
        except Exception as e:
            logger.error(f"Error in scheduler loop: {str(e)}")
            time.sleep(60)  # Wait a minute before retrying

if __name__ == "__main__":
    main()
