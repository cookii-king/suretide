#!/bin/bash

function update_variables() {
    local user="$1"
    local server_address="$2"
    local database="$3"
    local mysql_user="$4"
    local mysql_password="$5"

    # Get the line numbers of the BACKUP_SERVER, MYSQL_DATABASE, MYSQL_USER, and MYSQL_PASSWORD variables
    local backup_server_line_number=$(grep -n "BACKUP_SERVER=" "$0" | cut -d : -f 1)
    local mysql_database_line_number=$(grep -n "MYSQL_DATABASE=" "$0" | cut -d : -f 1)
    local mysql_user_line_number=$(grep -n "MYSQL_USER=" "$0" | cut -d : -f 1)
    local mysql_password_line_number=$(grep -n "MYSQL_PASSWORD=" "$0" | cut -d : -f 1)

    # Update the BACKUP_SERVER, MYSQL_DATABASE, MYSQL_USER, and MYSQL_PASSWORD variables in the script
    sed -i "${backup_server_line_number}s|BACKUP_SERVER=\"\"|BACKUP_SERVER=\"${user}@${server_address}\"|" "$0"
    sed -i "${mysql_database_line_number}s|MYSQL_DATABASE=\"\"|MYSQL_DATABASE=\"${database}\"|" "$0"
    sed -i "${mysql_user_line_number}s|MYSQL_USER=\"\"|MYSQL_USER=\"${mysql_user}\"|" "$0"
    sed -i "${mysql_password_line_number}s|MYSQL_PASSWORD=\"\"|MYSQL_PASSWORD=\"${mysql_password}\"|" "$0"
}

function create_crontab() {
    local script_path="$(realpath "$0")"
    (crontab -l 2>/dev/null; echo "* * * * * /usr/bin/env bash -u ubuntu ${script_path} ${BACKUP_SERVER} ${MYSQL_DATABASE} ${MYSQL_USER} ${MYSQL_PASSWORD}") | crontab -
}

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

# Check if the script is called with the necessary arguments
if [ "$#" -eq 5 ]; then
    update_variables "$1" "$2" "$3" "$4" "$5"
    create_crontab
fi

