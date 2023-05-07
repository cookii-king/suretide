#!/bin/bash


bs_username="$1"
db_name="$2"
db_user="$3"
db_password="$4"

#-----------------------------------------------------------------------------------------
# ----------------------     Initialization and Configuration     ---------------------- #
#-----------------------------------------------------------------------------------------

# Set terminal type to xterm
export TERM=xterm
SFTP_LINE="/usr/bin/sftp"
ENVIRONMENT_SHELL="/bin/bash"

# Determine the line length of the terminal
LINE_LENGTH=$(/usr/bin/tput cols)
CURRENT_USER="$(whoami)"
# Set the base path for the script
BASE_PATH="/home/ubuntu/"
# Set the system folder path
SYSTEM_PATH="system/"

# Set the log file path and create a new entry with delimiter lines
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
printf '%.0s*' $(seq 1 $LINE_LENGTH) >> $LOG_FILE; echo >> $LOG_FILE
printf '%.0s*' $(seq 1 $LINE_LENGTH) >> $LOG_FILE; echo >> $LOG_FILE

# Set the backup key file path
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
# Set the temporary directory path
TEMPORARY_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp"

# Create the temporary directory if it does not exist
mkdir -p "$TEMPORARY_DIRECTORY"

# Check if the temporary directory exists
if [ -d "$TEMPORARY_DIRECTORY" ]; then
    echo "$TEMPORARY_DIRECTORY"
else
    echo "Failed to create temporary directory."
fi

# Set the backup server
BACKUP_SERVER=""

# Function to validate an IP address
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

if [ ! -z "$1" ]; then
  input="$1"
  # Remove username if present
  if [[ $input == *"@"* ]]; then
    input="${input#*@}"
  fi

  # Remove https:// if present
  if [[ $input == "https://"* ]]; then
    input="${input#https://}"
  fi

    # Remove http:// if present
  if [[ $input == "http://"* ]]; then
    input="${input#http://}"
  fi

  if valid_ip "$input" || host "$input" > /dev/null 2>&1; then
    # Update the BACKUP_SERVER variable in the current script
    sed -i "s|BACKUP_SERVER=\"\"|BACKUP_SERVER=\"$1\"|" $0
    BACKUP_SERVER="$1"
  else
    echo "Error: Invalid IP address or hostname."
    exit 1
  fi
fi

# Calculate the length of the LOG_ENTRY_DATE_TIME text
LOG_ENTRY_DATE_TIME="$(date +"%Y-%m-%d %H:%M:%S")"
entry_length=${#LOG_ENTRY_DATE_TIME}

# Calculate the number of spaces needed to center the text
spaces=$(( (line_length - entry_length) / 2 ))

printf '%*.s' $spaces '' | tr ' ' '-' >> $LOG_FILE; echo -n " START OF LOG ENTRY " >> $LOG_FILE; printf '%*.s' $spaces '' | tr ' ' '-' >> $LOG_FILE; echo >> $LOG_FILE
printf '%*.s' $spaces '' | tr ' ' '-' >> $LOG_FILE; echo -n " $LOG_ENTRY_DATE_TIME " >> $LOG_FILE; printf '%*.s' $spaces '' | tr ' ' '-' >> $LOG_FILE; echo >> $LOG_FILE

# Check if the backup.pem file exists
if [ -e "$BACKUP_KEY" ]; then
  # Get the file permissions
  file_permissions=$(stat -c "%a" "$BACKUP_KEY")

  # Check if the permissions are not 400 or 600
  if [ "$file_permissions" != "400" ] && [ "$file_permissions" != "600" ]; then
    chmod 400 "$BACKUP_KEY"
    echo "File permissions for backup.pem have been changed to 400." >> "${LOG_FILE}"
  fi
else
  echo "backup.pem file not found." >> "${LOG_FILE}"
fi


# Stops specific services, where necessary
echo "stopping rsync..." >> "${LOG_FILE}"
sudo systemctl stop rsync >> "${LOG_FILE}"

echo "starting rsync..." >> "${LOG_FILE}"
sudo systemctl start rsync >> "${LOG_FILE}"

echo "restarting rsync..." >> "${LOG_FILE}"
sudo systemctl restart rsync >> "${LOG_FILE}"

# #----------------------------------------------------------------------------------------
# # ----------------------     Perform MySQL Dump and Transfer     ---------------------- #
# #----------------------------------------------------------------------------------------

# # Set MySQL variables
# MYSQL_DATABASE="suretidewordpress"
# MYSQL_USER="suretidewordpressuser"
# MYSQL_PASSWORD="@Rp!!T431"

# ## Check if command line arguments are provided for MySQL variables
# if [ ! -z "$2" ]; then
#   sed -i "s|MYSQL_DATABASE=\"suretidewordpress\"|MYSQL_DATABASE=\"$2\"|" backupscript.sh
# fi

# if [ ! -z "$3" ]; then
#   sed -i "s|MYSQL_USER=\"suretidewordpressuser\"|MYSQL_USER=\"$3\"|" backupscript.sh
# fi

# if [ ! -z "$4" ]; then
#   sed -i "s|MYSQL_PASSWORD=\"@Rp!!T431\"|MYSQL_PASSWORD=\"$4\"|" backupscript.sh
# fi

# # Create the MySQL dump file path
# MYSQL_FILE="$TEMPORARY_DIRECTORY/database_backup_on_$(date +"%d_%m_%Y_at_%H_%M_%S").sql"

# echo "🚦 🏁 Performing backup on $MYSQL_DATABASE database... 🏁 🚦" >> ${BASE_PATH}${$LOG_FILE}
# echo " ⚠️  Please ensure to update the IP address or domain URL of $MYSQL_DATABASE!! Or this script will not backup to your remote server. ⚠️" >> ${BASE_PATH}${$LOG_FILE}

# echo "Dumping MySQL database..." >> ${BASE_PATH}${$LOG_FILE}
# echo "Saved SQL file to $MYSQL_FILE." >> ${BASE_PATH}${$LOG_FILE}
# mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$MYSQL_FILE"

# echo "Using SFTP to transfer the file from this local server at http://$(curl ifconfig.me) to your remote server at http://$BACKUP_SERVER." >> ${BASE_PATH}${$LOG_FILE}
# echo -e "put $MYSQL_FILE\nexit" | $SFTP_LINE -o StrictHostKeyChecking=no -i $BACKUP_KEY $BACKUP_SERVER >> ${BASE_PATH}${$LOG_FILE}

# #----------------------------------------------------------------------------------------------------
# # ----------------------     Save Latest WordPress Tar File and Transfer     ---------------------- #
# #----------------------------------------------------------------------------------------------------

# # Set the WordPress directory
# WORDPRESS_DIRECTORY="/var/www/html/wordpress"

# # Check if a command line argument is provided for the WordPress directory
# if [ ! -z "$5" ]; then
#   sed -i "s|WORDPRESS_DIRECTORY=\"/var/www/html/wordpress\"|WORDPRESS_DIRECTORY=\"$5\"|" backupscript.sh
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
#   sed -i "s|NGINX_DIRECTORY=\"/etc/nginx\"|NGINX_DIRECTORY=\"$6\"|" backupscript.sh
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
# CRON_JOB_LINE=" * * * * * $ENVIRONMENT_SHELL ${BASE_PATH}backupscript.sh >> ${BASE_PATH}${$LOG_FILE} 2>&1"

# # Remove existing similar cron jobs
# grep -v "${BASE_PATH}backupscript.sh" /tmp/c1 > /tmp/c2
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
