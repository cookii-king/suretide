#!/bin/bash

BASE_PATH="/home/ubuntu/"
SYSTEM_PATH="system/"
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
TEMPORARY_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp/"

function valid_ip() {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}

BACKUP_SERVER=""
if [ ! -z "$1" ]; then
  input="$1"
  input="${input#*@}"
  input="${input#https://}"
  input="${input#http://}"
  
  if valid_ip "$input" || host "$input" > /dev/null 2>&1; then
    BACKUP_SERVER="$1"
  else
    echo "Error: Invalid IP address or hostname."
    exit 1
  fi
fi

LOG_ENTRY_DATE_TIME="$(date +"%Y-%m-%d %H:%M:%S")"
echo "LOG ENTRY: $LOG_ENTRY_DATE_TIME" >> ${LOG_FILE}

if [ -e "$BACKUP_KEY" ]; then
  file_permissions=$(stat -c "%a" "$BACKUP_KEY")
  if [ "$file_permissions" != "400" ] && [ "$file_permissions" != "600" ]; then
    chmod 400 "$BACKUP_KEY"
    echo "File permissions for backup.pem have been changed to 400." >> "${LOG_FILE}"
  fi
else
  echo "backup.pem file not found." >> "${LOG_FILE}"
fi

sudo systemctl stop rsync >> "${LOG_FILE}"
sudo systemctl start rsync >> "${LOG_FILE}"
sudo systemctl restart rsync >> "${LOG_FILE}"

MYSQL_DATABASE="suretidewordpress"
MYSQL_USER="suretidewordpressuser"
MYSQL_PASSWORD="@Rp!!T431"

if [ ! -z "$2" ]; then
  sed -i "s|MYSQL_DATABASE=\"suretidewordpress\"|MYSQL_DATABASE=\"$2\"|" setup-part-3.sh
fi

if [ ! -z "$3" ]; then
  sed -i "s|MYSQL_USER=\"suretidewordpressuser\"|MYSQL_USER=\"$3\"|" setup-part-3.sh
fi

if [ ! -z "$4" ]; then
  sed -i "s|MYSQL_PASSWORD=\"@Rp!!T431\"|MYSQL_PASSWORD=\"$4\"|" setup-part-3.sh
fi

# Create the MySQL dump file path
MYSQL_FILE="${TEMPORARY_DIRECTORY}database_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").sql"
echo "${MYSQL_FILE}"
echo -e "put $MYSQL_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER

# #----------------------------------------------------------------------------------------------------
# # ----------------------     Save Latest WordPress Tar File and Transfer     ---------------------- #
# #----------------------------------------------------------------------------------------------------

# # Set the WordPress directory
# WORDPRESS_DIRECTORY="/var/www/html/wordpress"

# # Check if a command line argument is provided for the WordPress directory
# if [ ! -z "$5" ]; then
#   sed -i "s|WORDPRESS_DIRECTORY=\"/var/www/html/wordpress\"|WORDPRESS_DIRECTORY=\"$5\"|" setup-part-3.sh
# fi

# # Create the WordPress tar file path
# WORDPRESS_DIRECTORY_TAR_FILE="$TEMPORARY_DIRECTORY/wordpress_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"

# echo "🚦 🏁 Performing backup on $WORDPRESS_DIRECTORY directory... 🏁 🚦" >> ${BASE_PATH}${$LOG_FILE}
# echo "Creating tar archive..." >> ${BASE_PATH}${$LOG_FILE}
# echo "Saved tar file to $WORDPRESS_DIRECTORY_TAR_FILE." >> ${BASE_PATH}${$LOG_FILE}
# tar -czf "$WORDPRESS_DIRECTORY_TAR_FILE" "$WORDPRESS_DIRECTORY"

# echo "Using SFTP to transfer the file from this local server at http://$(curl ifconfig.me) to your remote server at http://$BACKUP_SERVER." >> ${BASE_PATH}${$LOG_FILE}
# echo -e "put $WORDPRESS_DIRECTORY_TAR_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${BASE_PATH}${$LOG_FILE}

# #-------------------------------------------------------------------------------------------------------
# # ----------------------     Save Latest Nginx Config Tar File and Transfer     ---------------------- #
# #-------------------------------------------------------------------------------------------------------

# # Set the Nginx directory
# NGINX_DIRECTORY="/etc/nginx"

# # Check if a command line argument is provided for the Nginx directory
# if [ ! -z "$6" ]; then
#   sed -i "s|NGINX_DIRECTORY=\"/etc/nginx\"|NGINX_DIRECTORY=\"$6\"|" setup-part-3.sh
# fi

# # Create the Nginx tar file path
# NGINX_DIRECTORY_TAR_FILE="$TEMPORARY_DIRECTORY/nginx_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").tar.gz"

# echo "🚦 🏁 Performing backup on $NGINX_DIRECTORY directory... 🏁 🚦" >> ${BASE_PATH}${$LOG_FILE}
# echo "Creating tar archive..." >> ${BASE_PATH}${$LOG_FILE}
# echo "Saved tar file to $NGINX_DIRECTORY_TAR_FILE." >> ${BASE_PATH}${$LOG_FILE}
# tar -czf "$NGINX_DIRECTORY_TAR_FILE" "$NGINX_DIRECTORY"

# echo "Using SFTP to transfer the file from this local server at http://$(curl ifconfig.me) to your remote server at http://$BACKUP_SERVER." >> ${BASE_PATH}${$LOG_FILE}
# echo -e "put $NGINX_DIRECTORY_TAR_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${BASE_PATH}${$LOG_FILE}

# #------------------------------------------------------------------------------------
# # ----------------------     Add Cron Job for Automation     ---------------------- #
# #------------------------------------------------------------------------------------

# # Save the current crontab for the 'ubuntu' user to a temporary file
# sudo crontab -u ubuntu -l > /tmp/c1

# # Define the cron job line you want to add
# CRON_JOB_LINE=" * * * * * $ENVIRONMENT_SHELL ${BASE_PATH}setup-part-3.sh >> ${BASE_PATH}${$LOG_FILE} 2>&1"

# # Remove existing similar cron jobs
# grep -v "${BASE_PATH}setup-part-3.sh" /tmp/c1 > /tmp/c2
# mv /tmp/c2 /tmp/c1

# echo "Checking if crontab has automation for this script..." >> ${BASE_PATH}${$LOG_FILE}
# # Check if the cron job line is already in the crontab
# if ! grep -qF "$CRON_JOB_LINE" /tmp/c1; then
#   # If it's not in the crontab, append it to the temporary file
#   echo "Adding crontab automation to this script..." >> ${BASE_PATH}${$LOG_FILE}
#   echo "$CRON_JOB_LINE" >> /tmp/c1

#   # Install the modified crontab from the temporary file for the 'ubuntu' user
#   sudo crontab -u ubuntu /tmp/c1
# else
#   echo "The cron job is already in the crontab." >> ${BASE_PATH}${$LOG_FILE}
# fi

# # Clean up the temporary files
# rm /tmp/c1

# #--------------------------------------------------------------------------------------------------------
# # ----------------------     Remove Temporary Directory and End of Log Entry     ---------------------- #
# #--------------------------------------------------------------------------------------------------------

# echo "removing temp directory..." >> ${BASE_PATH}${$LOG_FILE}
# sudo rm -r $TEMPORARY_DIRECTORY >> ${BASE_PATH}${$LOG_FILE}

# printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}${$LOG_FILE}; echo -n " END OF LOG ENTRY " >> ${BASE_PATH}${$LOG_FILE}; printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}${$LOG_FILE}; echo >> ${BASE_PATH}${$LOG_FILE}
# printf '%.0s*' $(seq 1 $line_length) >> ${BASE_PATH}${$LOG_FILE}; echo >> ${BASE_PATH}${$LOG_FILE}
# printf '%.0s*' $(seq 1 $line_length) >> ${BASE_PATH}${$LOG_FILE}; echo >> ${BASE_PATH}backup
