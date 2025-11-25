#!/bin/bash
set -euo pipefail


sudo apt-get update -y
sudo apt-get install -y mariadb-server

sudo systemctl enable mariadb
sudo systemctl start mariadb

# Endurecer minimamente (sin interaccion)
sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('abcd') WHERE User='root';" || true
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" || true
sudo mysql -e "DROP DATABASE IF EXISTS test;" || true
sudo mysql -e "FLUSH PRIVILEGES;" || true

# Crear BD y usuario wp
mysql -uroot -p"abcd" -e "CREATE DATABASE IF NOT EXISTS mario CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p"abcd" -e "CREATE USER IF NOT EXISTS mario'@'192.168.10.%' IDENTIFIED BY 'abcd';"
mysql -uroot -p"abcd" -e "GRANT ALL PRIVILEGES ON mario.* TO 'mario'@'192.168.10.%'; FLUSH PRIVILEGES;"


# Sugerencia para wp-config.php 
cat <<EOF
Para completar WordPress en Web1/Web2:
DB_NAME: mario
DB_USER: mario
DB_PASSWORD: abcd
DB_HOST: 192.168.10.40
EOF