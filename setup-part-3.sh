#!/bin/bash

BASE_PATH="/home/ubuntu/"
SYSTEM_PATH="system/"
LOG_FILE="${BASE_PATH}${SYSTEM_PATH}suretide.log"
BACKUP_KEY="${BASE_PATH}${SYSTEM_PATH}backup.pem"
TEMPORARY_DIRECTORY="${BASE_PATH}${SYSTEM_PATH}temp"

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
