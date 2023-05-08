#!/bin/bash

BASE_PATH="/home/ubuntu/"
SYSTEM_PATH="system/"
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
TEMP_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp/"
BACKUP_SERVER="$1"
MYSQL_DATABASE="$2"
MYSQL_USER="$3"
MYSQL_PASSWORD="$4"
MYSQL_FILE="${TEMP_DIRECTORY}mysql_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").sql"
WORDPRESS_DIRECTORY_TAR_FILE="${TEMP_DIRECTORY}wordpress_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
NGINX_DIRECTORY_TAR_FILE="${TEMP_DIRECTORY}nginx_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
WORDPRESS_DIRECTORY="/var/www/html/wordpress"
NGINX_DIRECTORY="/etc/nginx"
ENVIRONMENT_SHELL="/bin/bash"
SFTP_LINE="/usr/bin/sftp"

# Calculate the length of the LOG_ENTRY_DATE_TIME text
LOG_ENTRY_DATE_TIME="$(date +"%Y-%m-%d %H:%M:%S")"
entry_length=${#LOG_ENTRY_DATE_TIME}

# Calculate the number of spaces needed to center the text
spaces=$(( (line_length - entry_length) / 2 ))

printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " START OF LOG ENTRY " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " $LOG_ENTRY_DATE_TIME " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"


mkdir -p $BASE_PATH$SYSTEM_PATH

mkdir -p $TEMP_DIRECTORY

if [ "$#" -ne 4 ]; then
    echo "Usage: sudo bash setup-part-3.sh <BACKUP_SERVER> <MYSQL_DATABASE> <MYSQL_USER> <MYSQL_PASSWORD>"
    exit 1
fi


# Check if the database exists
DB_EXISTS=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES LIKE '$MYSQL_DATABASE';" | grep "$MYSQL_DATABASE")

if [ -z "$DB_EXISTS" ]; then
    echo "🚫 The database does not exist. Please go to http://$(curl ifconfig.me) to finish the WordPress installation." >> "$LOG_FILE"
    exit 1
else
    # mysqldump --no-tablespaces $MYSQL_DATABASE > $MYSQL_FILE
    mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$MYSQL_FILE"

    echo -e "📤 Uploading MySQL backup...\nput $MYSQL_FILE\nexit" >> "$LOG_FILE" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER

    tar -czf "$WORDPRESS_DIRECTORY_TAR_FILE" "$WORDPRESS_DIRECTORY" >> "$LOG_FILE"

    echo -e "📤 Uploading WordPress backup...\nput $WORDPRESS_DIRECTORY_TAR_FILE\nexit" >> "$LOG_FILE" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER

    tar -czf "$NGINX_DIRECTORY_TAR_FILE" "$NGINX_DIRECTORY" >> "$LOG_FILE"

    echo -e "📤 Uploading Nginx backup...\nput $NGINX_DIRECTORY_TAR_FILE\nexit" >> "$LOG_FILE" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER

    OUTPUT=$(mysql -u$MYSQL_USER -e "use $MYSQL_DATABASE;
    SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');")


    # Extract the home and siteurl values from the query output
    HOME_URL=$(echo "$OUTPUT" | grep "home" | awk '{print $2}')
    SITE_URL=$(echo "$OUTPUT" | grep "siteurl" | awk '{print $2}')
    CURRENT_URL="http://$(curl ifconfig.me)"

    if [ "$HOME_URL" != "$CURRENT_URL" ] && [ "$SITE_URL" != "$CURRENT_URL" ]; then
        # Update the home and siteurl values in the wp_options table using the 'mysql' command-line client
        mysql -u$MYSQL_USER -e "use $MYSQL_DATABASE;
        UPDATE wp_options SET option_value = '$CURRENT_URL' WHERE option_name = 'siteurl';
        UPDATE wp_options SET option_value = '$CURRENT_URL' WHERE option_name = 'home';"

        echo "🔄 Updated home and siteurl values in the database." >> "$LOG_FILE"

    else

        echo "ℹ️ Current homeurl is: $HOME_URL" >> "$LOG_FILE"
        echo "ℹ️ Current siteurl is: $SITE_URL" >> "$LOG_FILE"

    fi

    # Set up the cron job to run the backup script every minute
    CRON_JOB=" * * * * * $ENVIRONMENT_SHELL ${BASE_PATH}${SYSTEM_PATH}backup.sh $BACKUP_SERVER $MYSQL_DATABASE $MYSQL_USER '$MYSQL_PASSWORD' >> $LOG_FILE 2>&1"

    # Backup the current 'ubuntu' user's crontab
    sudo crontab -u ubuntu -l > /tmp/current_crontab

    # Check if the cron job already exists
    if ! grep -qF "$CRON_JOB" /tmp/current_crontab; then
        # Add the new cron job to the temporary crontab file
        echo "$CRON_JOB" >> /tmp/current_crontab

        # Install the modified crontab for the 'ubuntu' user
        sudo crontab -u ubuntu /tmp/current_crontab

        echo "⏲️ Cron job set up to run the backup script every minute." >> "$LOG_FILE"
    else
        echo "ℹ️ The cron job already exists." >> "$LOG_FILE"
    fi

    # Clean up the temporary file
    rm /tmp/current_crontab

    rm -r $TEMP_DIRECTORY

    echo "✅ Backup process completed successfully!" >> "$LOG_FILE"
fi

printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " END OF LOG ENTRY " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " $LOG_ENTRY_DATE_TIME " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
