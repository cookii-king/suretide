#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <remote_server> <keypair_path> <file_path>"
    exit 1
fi

# Extract the input from command line arguments
remote_server="$1"
keypair_path="$2"
file_path="$3"

# Extract the username from the remote server's input
username=$(echo "$remote_server" | cut -d '@' -f 1)

# Set the destination path to the default /home/username/system/
remote_destination="/home/${username}/system/"

# Check if the keypair is .pem or .ppk
key_ext="${keypair_path##*.}"

# Test the connection
if [ "$key_ext" == "pem" ]; then
    ssh -i "${keypair_path}" "${remote_server}" exit
    status=$?
elif [ "$key_ext" == "ppk" ]; then
    eval $(ssh-pageant -k "${keypair_path}")
    ssh "${remote_server}" exit
    status=$?
else
    echo "Invalid keypair extension. Please provide a .pem or .ppk keypair."
    exit 1
fi

if [ $status -ne 0 ]; then
    echo "Connection failed. Please check your input and try again."
    exit 1
fi

# Upload the file
if [ "$key_ext" == "pem" ]; then
    # Use rsync with .pem keypair
    rsync -avz -e "ssh -i \"${keypair_path}\"" "${file_path}" "${remote_server}:${remote_destination}"
elif [ "$key_ext" == "ppk" ]; then
    # Use rsync with .ppk keypair (assuming ssh-pageant is installed and configured)
    eval $(ssh-pageant -k "${keypair_path}")
    rsync -avz -e "ssh" "${file_path}" "${remote_server}:${remote_destination}"
fi

echo "File uploaded successfully."

ssh -i "${keypair_path}" "${remote_server}"
