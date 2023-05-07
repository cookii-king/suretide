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

# # Set the backup key file path
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

printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}backupscript.log; echo -n " START OF LOG ENTRY " >> ${BASE_PATH}backupscript.log; printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}backupscript.log; echo >> ${BASE_PATH}backupscript.log
printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}backupscript.log; echo -n " $LOG_ENTRY_DATE_TIME " >> ${BASE_PATH}backupscript.log; printf '%*.s' $spaces '' | tr ' ' '-' >> ${BASE_PATH}backupscript.log; echo >> ${BASE_PATH}backupscript.log

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
