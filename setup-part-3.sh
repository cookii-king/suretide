#!/bin/bash

BASE_PATH="/home/ubuntu/"
SYSTEM_PATH="system/"
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
TEMP_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp/"
BACKUP_SERVER="backup server"
MYSQL_DATABASE="database name"
MYSQL_USER="database user"
MYSQL_PASSWORD="database password"
MYSQL_FILE="${TEMP_DIRECTORY}mysql_file.sql"
WORDPRESS_DIRECTORY="/var/www/html/wordpress"
NGINX_DIRECTORY="/etc/nginx"
ENVIRONMENT_SHELL="/bin/bash"

# Check if the script is called with the necessary arguments
if [ "$#" -eq 5 ]; then
    # Update variables
    user="$1"
    server_address="$2"
    database="$3"
    mysql_user="$4"
    mysql_password="$5"

    # Get the line numbers of the BACKUP_SERVER, MYSQL_DATABASE, MYSQL_USER, and MYSQL_PASSWORD variables
    backup_server_line_number=$(grep -n "BACKUP_SERVER=" "$0" | cut -d : -f 1)
    mysql_database_line_number=$(grep -n "MYSQL_DATABASE=" "$0" | cut -d : -f 1)
    mysql_user_line_number=$(grep -n "MYSQL_USER=" "$0" | cut -d : -f 1)
    mysql_password_line_number=$(grep -n "MYSQL_PASSWORD=" "$0" | cut -d : -f 1)

    # Update the BACKUP_SERVER, MYSQL_DATABASE, MYSQL_USER, and MYSQL_PASSWORD variables in the script
    sed -i "${backup_server_line_number}s|BACKUP_SERVER=\"backup server\"|BACKUP_SERVER=\"${user}@${server_address}\"|" "$0"
    sed -i "${mysql_database_line_number}s|MYSQL_DATABASE=\"database name\"|MYSQL_DATABASE=\"${database}\"|" "$0"
    sed -i "${mysql_user_line_number}s|MYSQL_USER=\"database user\"|MYSQL_USER=\"${mysql_user}\"|" "$0"
    sed -i "${mysql_password_line_number}s|MYSQL_PASSWORD=\"database password\"|MYSQL_PASSWORD=\"${mysql_password}\"|" "$0"

    echo "you entered $user"
    echo "you entered $server_address"
    echo "you entered $database"
    echo "you entered $mysql_user"
    echo "you entered $mysql_password"

fi

# Set up the cron job to run the Hello World script every minute
CRON_JOB=" * * * * * $ENVIRONMENT_SHELL "${BASE_PATH}${SYSTEM_PATH}test.sh" >> $LOG_FILE 2>&1"

# Backup the current 'ubuntu' user's crontab
sudo crontab -u ubuntu -l > /tmp/current_crontab

# Check if the cron job already exists
if ! grep -qF "$CRON_JOB" /tmp/current_crontab; then
    # Add the new cron job to the temporary crontab file
    echo "$CRON_JOB" >> /tmp/current_crontab

    # Install the modified crontab for the 'ubuntu' user
    sudo crontab -u ubuntu /tmp/current_crontab

    echo "Cron job set up to run the Hello World script every minute."
else
    echo "The cron job already exists."
fi

# Clean up the temporary file
rm /tmp/current_crontab
