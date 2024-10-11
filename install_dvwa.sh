#!/bin/bash

# Install DVWA di Ubuntu Server

# 1. Update Sistem
echo "Updating system..."
sudo apt update
sudo apt upgrade -y

# 2. Instal Apache dan MySQL
echo "Installing Apache and MySQL..."
sudo apt install apache2 mysql-server -y

# 3. Instal PHP dan Ekstensi yang Diperlukan
echo "Installing PHP and required extensions..."
sudo apt install php libapache2-mod-php php-mysql php-gd php-mbstring php-xml php-curl -y

# 4. Download DVWA
echo "Downloading DVWA..."
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git

# 5. Konfigurasi File DVWA
echo "Configuring DVWA..."
cd DVWA/config
sudo cp config.inc.php.dist config.inc.php

# Edit config.inc.php (sesuaikan detail MySQL Anda di sini)
sudo sed -i "s/'db_user'     = 'root'/'db_user'     = 'dvwa'/g" config.inc.php
sudo sed -i "s/'db_password' = 'p@ssw0rd'/'db_password' = 'p@ssw0rd'/g" config.inc.php

# 6. Konfigurasi Database
echo "Configuring MySQL database..."
sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE dvwa;
CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

# 7. Ubah Izin Direktori
echo "Setting permissions for DVWA directory..."
sudo chown -R www-data:www-data /var/www/html/DVWA/
sudo chmod -R 755 /var/www/html/DVWA/

# 8. Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

# 9. Konfigurasi Apache
echo "Configuring Apache for DVWA..."
sudo bash -c 'cat > /etc/apache2/sites-available/dvwa.conf <<EOF
<VirtualHost *:8082>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/DVWA
    ServerName dvwa.local
    <Directory /var/www/html/DVWA/>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/dvwa_error.log
    CustomLog \${APACHE_LOG_DIR}/dvwa_access.log combined
</VirtualHost>
EOF'

# 10. Konfigurasi Port Apache
echo "Configuring Apache ports..."
sudo bash -c 'echo "Listen 8082" >> /etc/apache2/ports.conf'

# 11. Aktifkan Virtual Host dan Modul Rewrite
echo "Enabling DVWA site and mod_rewrite..."
sudo a2ensite dvwa.conf
sudo a2enmod rewrite

# 12. Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

# 13. Konfigurasi PHP
echo "Configuring PHP settings..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
sudo sed -i "s/allow_url_include = Off/allow_url_include = On/g" /etc/php/$PHP_VERSION/apache2/php.ini
sudo sed -i "s/display_errors = On/display_errors = Off/g" /etc/php/$PHP_VERSION/apache2/php.ini

# Restart Apache lagi
echo "Restarting Apache again..."
sudo systemctl restart apache2

echo "DVWA installation completed. Access it at http://your_server_ip:8082"
