#!/bin/bash

# Initialization and Configuration
BASE_PATH="/home/ubuntu/"
LOG_FILE="${BASE_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}backup.pem"
TEMPORARY_DIRECTORY="${BASE_PATH}temp"
SFTP_LINE="/usr/bin/sftp"
BACKUP_SERVER=""

if [ ! -z "$1" ]; then
  sed -i "s|BACKUP_SERVER=\"\"|BACKUP_SERVER=\"$1\"|" $0
  BACKUP_SERVER="$1"
fi

# Create Temporary Directory
if [ ! -d "$TEMPORARY_DIRECTORY" ]; then
  mkdir -p "$TEMPORARY_DIRECTORY"
  echo "Created temporary directory: $TEMPORARY_DIRECTORY" >> ${LOG_FILE}
else
  echo "Temporary directory already exists: $TEMPORARY_DIRECTORY" >> ${LOG_FILE}
fi

# Set Backup Key Permissions
if [ -e "$BACKUP_KEY" ]; then
  file_permissions=$(stat -c "%a" "$BACKUP_KEY")
  if [ "$file_permissions" != "400" ] && [ "$file_permissions" != "600" ]; then
    chmod 400 "$BACKUP_KEY"
    echo "File permissions for backup.pem have been changed to 400." >> ${LOG_FILE}
  fi
else
  echo "backup.pem file not found." >> ${LOG_FILE}
fi

# Stop, Start, and Restart Rsync Service
sudo systemctl stop rsync >> ${LOG_FILE}
sudo systemctl start rsync >> ${LOG_FILE}
sudo systemctl restart rsync >> ${LOG_FILE}

# Perform MySQL Dump and Transfer
MYSQL_DATABASE="suretidewordpress"
MYSQL_USER="suretidewordpressuser"
MYSQL_PASSWORD="@Rp!!T431"

if [ ! -z "$2" ]; then
  sed -i "s|MYSQL_DATABASE=\"suretidewordpress\"|MYSQL_DATABASE=\"$2\"|" $0
fi

if [ ! -z "$3" ]; then
  sed -i "s|MYSQL_USER=\"suretidewordpressuser\"|MYSQL_USER=\"$3\"|" $0
fi

if [ ! -z "$4" ]; then
  sed -i "s|MYSQL_PASSWORD=\"@Rp!!T431\"|MYSQL_PASSWORD=\"$4\"|" $0
fi

MYSQL_FILE="$TEMPORARY_DIRECTORY/database_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").sql"
mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$MYSQL_FILE"
echo -e "put $MYSQL_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${LOG_FILE}

# Save Latest WordPress Tar File and Transfer
WORDPRESS_DIRECTORY="/var/www/html/wordpress"

if [ ! -z "$5" ]; then
  sed -i "s|WORDPRESS_DIRECTORY=\"/var/www/html/wordpress\"|WORDPRESS_DIRECTORY=\"$5\"|" $0
fi

WORDPRESS_DIRECTORY_TAR_FILE="$TEMPORARY_DIRECTORY/wordpress_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
tar -czf "$WORDPRESS_DIRECTORY_TAR_FILE" "$WORDPRESS_DIRECTORY"
echo -e "put $WORDPRESS_DIRECTORY_TAR_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${LOG_FILE}

# Save Latest Nginx Config Tar File and Transfer
NGINX_DIRECTORY="/etc/nginx"

if [ ! -z "$6" ]; then
  sed -i "s|NGINX_DIRECTORY=\"/etc/nginx\"|NGINX_DIRECTORY=\"$6\"|" $0
fi

NGINX_DIRECTORY_TAR_FILE="$TEMPORARY_DIRECTORY/nginx_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
tar -czf "$NGINX_DIRECTORY_TAR_FILE" "$NGINX_DIRECTORY"
echo -e "put $NGINX_DIRECTORY_TAR_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${LOG_FILE}

# Add Cron Job for Automation
sudo crontab -u ubuntu -l > /tmp/c1
CRON_JOB_LINE=" * * * * * /bin/bash ${BASE_PATH}backup.sh >> ${BASE_PATH}suretide.log 2>&1"
grep -v "${BASE_PATH}backup.sh" /tmp/c1 > /tmp/c2
mv /tmp/c2 /tmp/c1

if ! grep -qF "$CRON_JOB_LINE" /tmp/c1; then
  echo "$CRON_JOB_LINE" >> /tmp/c1
  sudo crontab -u ubuntu /tmp/c1
fi

rm /tmp/c1

# Remove Temporary Directory
sudo rm -r $TEMPORARY_DIRECTORY >> ${LOG_FILE}
