#!/bin/bash
set -e

# Cambiar hostname
sudo hostnamectl set-hostname DBmariodasilva

# Instalar MariaDB
sudo apt update
sudo apt install mariadb-server -y

sudo mysql <<EOF
CREATE DATABASE mariowordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

CREATE USER 'mario'@'10.0.2.45' IDENTIFIED BY 'abcd';
GRANT ALL PRIVILEGES ON wordpress.* TO 'mario'@'10.0.2.45';

CREATE USER 'mario'@'10.0.2.184' IDENTIFIED BY 'abcd';
GRANT ALL PRIVILEGES ON wordpress.* TO 'mario'@'10.0.2.184';

FLUSH PRIVILEGES;
EOF

#Configurar bind-address en MariaDB
sudo sed -i 's/^bind-address.*/bind-address = 10.0.3.111/' /etc/mysql/mariadb.conf.d/50-server.cnf

#Reiniciar MariaDB
sudo systemctl restart mariadb


