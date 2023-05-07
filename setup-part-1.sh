#!/bin/bash

# Check if arguments are provided
if [ $# -eq 0 ]; then
    # Ask for user input
    read -p "Enter user@example.com or user@ip: " remote_server
    read -p "Enter the key pair path to your server: " keypair_path
    read -p "Enter the key pair path to your backup server: " backup_keypair_path
    read -p "Enter the file path to transfer: " file_path
    read -p "Enter the remote destination: " remote_destination
else
    # Use provided arguments
    remote_server=$1
    keypair_path=$2
    backup_keypair_path=$3
    file_path=$4
    remote_destination=$5
fi

# Check if keypair files exist
if [ ! -f "$keypair_path" ] || [ ! -f "$backup_keypair_path" ]; then
    echo "Error: Key pair files not found."
    exit 1
fi

# Get keypair file extensions
key_ext=$(echo "${keypair_path##*.}")
backup_key_ext=$(echo "${backup_keypair_path##*.}")

# Transfer files using rsync
if [ "$key_ext" == "pem" ]; then
    # Use rsync with .pem keypair
    rsync -avz -e "ssh -i \"${keypair_path}\"" "${file_path}" "${remote_server}:${remote_destination}"
elif [ "$key_ext" == "ppk" ]; then
    # Use rsync with .ppk keypair (assuming ssh-pageant is installed and configured)
    eval $(ssh-pageant -k "${keypair_path}")
    rsync -avz -e "ssh" "${file_path}" "${remote_server}:${remote_destination}"
else
    echo "Error: Unsupported keypair file extension."
    exit 1
fi

# Transfer files to backup server
if [ "$backup_key_ext" == "pem" ]; then
    # Use rsync with .pem keypair
    rsync -avz -e "ssh -i \"${backup_keypair_path}\"" "${file_path}" "${remote_server}:${remote_destination}"
elif [ "$backup_key_ext" == "ppk" ]; then
    # Use rsync with .ppk keypair (assuming ssh-pageant is installed and configured)
    eval $(ssh-pageant -k "${backup_keypair_path}")
    rsync -avz -e "ssh" "${file_path}" "${remote_server}:${remote_destination}"
else
    echo "Error: Unsupported backup keypair file extension."
    exit 1
fi

echo "File transfer completed."
