#!/bin/bash
BACKUP_SERVER=""
MYSQL_DATABASE=""
MYSQL_USER=""
MYSQL_PASSWORD=""
MYSQL_FILE="/home/ubuntu/system/backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").sql"
LOG_FILE="/home/ubuntu/system/suretide.log"

# Check if command line arguments are provided
if [ ! -z "$1" ]; then
  MYSQL_DATABASE="$1"
else
  read -p "Enter database name: " MYSQL_DATABASE
fi

if [ ! -z "$2" ]; then
  MYSQL_USER="$2"
else
  read -p "Enter database user: " MYSQL_USER
fi

if [ ! -z "$3" ]; then
  MYSQL_PASSWORD="$3"
else
  read -sp "Enter database password: " MYSQL_PASSWORD
  echo ""
fi

if [ ! -z "$4" ]; then
  BACKUP_SERVER="$4"
else
  read -p "Enter backup server username: " BACKUP_SERVER
fi

# Calculate the length of the LOG_ENTRY_DATE_TIME text
LOG_ENTRY_DATE_TIME="$(date +"%Y-%m-%d %H:%M:%S")"
entry_length=${#LOG_ENTRY_DATE_TIME}
# Calculate the number of spaces needed to center the text
spaces=$(( (line_length - entry_length) / 2 ))

printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " 🚀 START OF LOG ENTRY " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " 🕒 $LOG_ENTRY_DATE_TIME " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"

# /usr/bin/mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORDd $MYSQL_DATABASE > "$MYSQL_FILE"
/usr/bin/mysqldump -u$MYSQL_USER $MYSQL_DATABASE > "$MYSQL_FILE"
echo -e "put $MYSQL_FILE\nexit" | /usr/bin/sftp -o StrictHostKeyChecking=no -i "/home/ubuntu/system/backup.pem" "ubuntu@34.227.112.90" >> "$LOG_FILE"

WORDPRESS_DIRECTORY_TAR_FILE="/home/ubuntu/system/wordpress_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
WORDPRESS_DIRECTORY="/var/www/html/wordpress"
tar -czf "$WORDPRESS_DIRECTORY_TAR_FILE" "$WORDPRESS_DIRECTORY" >> "$LOG_FILE"
echo -e "put $WORDPRESS_DIRECTORY_TAR_FILE\nexit" | /usr/bin/sftp -o StrictHostKeyChecking=no -i "/home/ubuntu/system/backup.pem" "ubuntu@34.227.112.90" >> "$LOG_FILE"

NGINX_DIRECTORY_TAR_FILE="/home/ubuntu/system/nginx_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"
NGINX_DIRECTORY="/etc/nginx"
tar -czf "$NGINX_DIRECTORY_TAR_FILE" "$NGINX_DIRECTORY" >> "$LOG_FILE"
echo -e "put $NGINX_DIRECTORY_TAR_FILE\nexit" | /usr/bin/sftp -o StrictHostKeyChecking=no -i "/home/ubuntu/system/backup.pem" "ubuntu@34.227.112.90" >> "$LOG_FILE"

echo "$MYSQL_FILE"
cat "$LOG_FILE"

rm $MYSQL_FILE
rm $WORDPRESS_DIRECTORY_TAR_FILE
rm $NGINX_DIRECTORY_TAR_FILE

OUTPUT=$(mysql -u$MYSQL_USER -e "use $MYSQL_DATABASE;
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');")
HOME_URL=$(echo "$OUTPUT" | grep "home" | awk '{print $2}')
SITE_URL=$(echo "$OUTPUT" | grep "siteurl" | awk '{print $2}')
CURRENT_URL="http://$(curl ifconfig.me)"

if [ "$HOME_URL" != "$CURRENT_URL" ] && [ "$SITE_URL" != "$CURRENT_URL" ]; then
    mysql -u$MYSQL_USER -e "use $MYSQL_DATABASE;
    UPDATE wp_options SET option_value = '$CURRENT_URL' WHERE option_name = 'siteurl';
    UPDATE wp_options SET option_value = '$CURRENT_URL' WHERE option_name = 'home';"
    echo "🔄 Updated home and siteurl values in the database." >> "$LOG_FILE"
else
    echo "ℹ️ Current homeurl is: $HOME_URL" >> "$LOG_FILE"
    echo "ℹ️ Current siteurl is: $SITE_URL" >> "$LOG_FILE"
fi

(crontab -l | grep -v "/home/ubuntu/system/backup.sh"; echo " * * * * * /usr/bin/bash /home/ubuntu/system/backup.sh") | sort -u | crontab -

printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " 🏁 END OF LOG ENTRY " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo -n " 🕒 $LOG_ENTRY_DATE_TIME " >> "$LOG_FILE"; printf '%*.s' $spaces '' | tr ' ' '-' >> "$LOG_FILE"; echo >> "$LOG_FILE"
