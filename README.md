# Suretide Setup Part 1

This script, `setup-part-1.sh`, is designed to help you easily upload a file to a remote server using either a `.pem` or `.ppk` keypair. The script will automatically set the destination path to `/home/username/` on the remote server.

## Prerequisites

- A remote server with SSH access
- A `.pem` or `.ppk` keypair for the remote server
- A file you want to upload to the remote server
- A macOS or Linux system to run the script

## Usage

1. Download the script from the GitHub repository and save it as `setup-part-1.sh`:

```bash
curl -sSL https://raw.githubusercontent.com/cookii-king/suretide/main/setup-part-1.sh -o setup-part-1.sh
```

2. Make the script executable:

```bash
chmod +x setup-part-1.sh
```

3. Run the script:

```bash
./setup-part-1.sh
```

4. Follow the prompts to enter the remote server's `username@ip`, the path to your keypair, the path of the file you want to upload, and the destination path on the remote server.

5. The script will test the connection to the remote server and upload the file to the specified destination path.

6. If the file upload is successful, the script will establish an SSH connection to the remote server.

You can run this one line:

```bash
curl -sSL https://raw.githubusercontent.com/cookii-king/suretide/main/setup-part-1.sh -o setup-part-1.sh && chmod +x setup-part-1.sh && bash setup-part-1.sh
```

## Troubleshooting

- Ensure you have the correct keypair file and its path.
- Verify that the remote server's IP address and username are correct.
- Make sure your local system has `rsync`, `ssh`, and `curl` installed. On macOS, you can install these tools using [Homebrew](https://brew.sh/). On Linux, use your package manager (e.g., `apt`, `yum`, or `pacman`).

## Additional Notes

- This script assumes that the remote server's SSH service is running on the default port (22). If the remote server uses a different port, you will need to modify the script to include the `-p` flag followed by the port number in the `ssh` and `rsync` commands.
- If you are using a `.ppk` keypair, the script assumes that you have `ssh-pageant` installed and configured on your system.
