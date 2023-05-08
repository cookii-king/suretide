#!/bin/bash

BASE_PATH="/home/ubuntu/"
SYSTEM_PATH="system/"
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
TEMP_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp/"
BACKUP_SERVER=""
MYSQL_DATABASE=""
MYSQL_USER=""
MYSQL_PASSWORD=""
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
    sed -i "${backup_server_line_number}s|BACKUP_SERVER=\"\"|BACKUP_SERVER=\"${user}@${server_address}\"|" "$0"
    sed -i "${mysql_database_line_number}s|MYSQL_DATABASE=\"\"|MYSQL_DATABASE=\"${database}\"|" "$0"
    sed -i "${mysql_user_line_number}s|MYSQL_USER=\"\"|MYSQL_USER=\"${mysql_user}\"|" "$0"
    sed -i "${mysql_password_line_number}s|MYSQL_PASSWORD=\"\"|MYSQL_PASSWORD=\"${mysql_password}\"|" "$0"

    # Create crontab
    sudo crontab -u ubuntu -l > /tmp/c1

    CRON_JOB_LINE=" * * * * * $ENVIRONMENT_SHELL ${BASE_PATH}${SYSTEM_PATH}setup-part-3.sh ${BACKUP_SERVER} ${MYSQL_DATABASE} ${MYSQL_USER} ${MYSQL_PASSWORD} >> ${LOG_FILE} 2>&1"

    # Remove existing similar cron jobs
    grep -v "${BASE_PATH}${SYSTEM_PATH}setup-part-3.sh" /tmp/c1 > /tmp/c2
    mv /tmp/c2 /tmp/c1

    echo "Checking if crontab has automation for this script..." >> ${LOG_FILE}
    # Check if the cron job line is already in the crontab
    if ! grep -qF "$CRON_JOB_LINE" /tmp/c1; then
        # If it's not in the crontab, append it to the temporary file
        echo "Adding crontab automation to this script..." >> ${LOG_FILE}
        echo "$CRON_JOB_LINE" >> /tmp/c1

        # Install the modified crontab from the temporary file for the 'ubuntu' user
        sudo crontab -u ubuntu /tmp/c1
    else
        echo "The cron job is already in the crontab." >> ${LOG_FILE}
    fi

    # Clean up the temporary files
    rm /tmp/c1
fi
