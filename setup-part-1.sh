#!/bin/bash

# Prompt the user for input
echo "Enter the remote server's username@ip (e.g. user@example.com):"
read remote_server

echo "Enter the path to the server's .pem or .ppk keypair:"
read keypair_path

echo "Enter the path of the file you want to upload:"
read file_path

# echo "Enter the destination path on the remote server (e.g. /home/user/destination) or leave it empty for default (/home/username/):"
# read remote_destination

remote_destination=""

# If the destination path is empty, use /home/username/
# if [ -z "$remote_destination" ]; then
#     username=$(echo "$remote_server" | cut -d '@' -f 1)
#     remote_destination="/home/${username}/"
# fi

username=$(echo "$remote_server" | cut -d '@' -f 1)
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

sudo rm -r setup-part-1.sh
