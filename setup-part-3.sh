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
