#!/bin/bash

# Get the current user
current_user="$(whoami)"

# Check if the current user is already an admin
if groups "$current_user" | grep -q "\bsudo\b"; then
    echo "$current_user is already an admin."
else
    echo "$current_user is not an admin. Granting admin privileges..."
    if [ "$current_user" != "root" ]; then
        # Add the current user to the sudo group
        sudo usermod -aG sudo "$current_user"
        echo "$current_user has been granted admin privileges."
    else
        echo "You are logged in as root. No need to grant admin privileges."
    fi
fi


# Set default values
db_name=""
db_user=""
db_password=""
bs_username=""

# Check if command line arguments are provided
if [ ! -z "$1" ]; then
  db_name="$1"
else
  read -p "Enter database name: " db_name
fi

if [ ! -z "$2" ]; then
  db_user="$2"
else
  read -p "Enter database user: " db_user
fi

if [ ! -z "$3" ]; then
  db_password="$3"
else
  read -sp "Enter database password: " db_password
  echo ""
fi

if [ ! -z "$4" ]; then
  bs_username="$4"
else
  read -p "Enter backup server username: " bs_username
fi

sudo apt update -y
sudo apt install tree -y
sudo apt install nginx -y
sudo apt install software-properties-common -y
sudo apt install mysql-server -y
sudo apt install mysql-client -y
sudo apt install vsftpd -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt install php8.1 -y
sudo apt install php8.1-fpm -y
sudo apt install php8.1-mysql -y
sudo systemctl status nginx
sudo wget -O /var/www/html/latest.tar.gz https://wordpress.org/latest.tar.gz
sudo tar -xzf /var/www/html/latest.tar.gz -C /var/www/html/
sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
ls /var/www/html/wordpress

sudo sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$db_name' );/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$db_user' );/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$db_password' );/g" /var/www/html/wordpress/wp-config.php

config_file="/var/www/html/wordpress/wp-config.php"

# Download the salts and store them in a variable
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Define the search string
STRING='put your unique phrase here'

# Replace the placeholders in the wp-config.php file
sed -i "/$STRING/ { N; d }" $config_file
printf '%s\n' "/**#@-/i" "$SALT" "." "w" | ed -s $config_file

# Replace the document root in the Nginx configuration file
sudo sed -i "s#root /var/www/html;#root /var/www/html/wordpress;#g" /etc/nginx/sites-available/default
sudo sed -i "s#index index.html index.htm index.nginx-debian.html;#index index.php index.html index.htm index.nginx-debian.html;#g" /etc/nginx/sites-available/default
sudo sed -i "s/server_name _;/server_name localhost;/g" /etc/nginx/sites-available/default
sudo sed -i 's#try_files $uri $uri/ =404;#try_files $uri $uri/ /index.php?$args;#g' /etc/nginx/sites-available/default

sudo sed -i '60s/php7.4-fpm.sock/php8.1-fpm.sock/' /etc/nginx/sites-available/default

sudo sed -i -e '56, 61 s/#//' -e '63 s/#//' /etc/nginx/sites-available/default

# Create the database, user, and grant privileges
sudo mysql <<EOF
CREATE DATABASE $db_name DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF

sudo systemctl restart nginx

sudo chown -R www-data:www-data /var/www

curl -sSL https://raw.githubusercontent.com/cookii-king/suretide/main/setup-part-3.sh -o setup-part-3.sh && sudo chmod +x setup-part-3.sh && sudo bash setup-part-3.sh $bs_username $db_name $db_user $db_password

sudo rm -r setup-part-3.sh
echo "done ✅ ∙ to get rid of error just setup your wordpres and update the backup script to your liking..."
echo "go to http://$(curl ifconfig.me) to see finish setting up your wordpress website. 😁"
