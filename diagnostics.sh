#!/bin/bash

# Function to center text
center_text() {
    text="$1"
    line_length=$(/usr/bin/tput cols)
    text_length=${#text}
    padding=$(( (line_length - text_length) / 2 ))
    printf "%${padding}s" ''
    echo "$text"
}

# Welcome message
clear
center_text "Welcome to the Real-time System Information Monitor"
sleep 2

while true
do
    # Get terminal dimensions
    export TERM=xterm
    line_length=$(/usr/bin/tput cols)

    # System information
    current_host=$(hostname)
    current_kernel_version=$(uname -r)
    cpu_usage=$(top -b -n1 | grep Cpu | awk '{print $2}')
    ps_table=$(ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu)
    system_uptime=$(uptime -p | sed 's/^up //')

    diagnostics="
$(printf '%.0s=' $(seq 1 $line_length))
$(center_text 'System Information')
Hostname: $current_host
Current kernel version: $current_kernel_version
System up-time: $system_uptime

$(printf '%.0s=' $(seq 1 $line_length))
$(center_text 'Resource Usage')
Number of tasks running: $(ps | wc -l)
Total and available RAM: $(free -h | awk '/^Mem:/{print $2 " / " $7}')
Total CPU usage: $cpu_usage%

$(printf '%.0s=' $(seq 1 $line_length))
$(center_text 'Disk Usage')
Total and available disk size: $(df -h --total | awk 'END {print $2 " / " $4}')

$(printf '%.0s=' $(seq 1 $line_length))
$(center_text 'Process Details')
$ps_table

$(printf '%.0s=' $(seq 1 $line_length))
Press CTRL+C to exit.
"

    clear
    echo -e "$diagnostics"
    sleep 1
done
