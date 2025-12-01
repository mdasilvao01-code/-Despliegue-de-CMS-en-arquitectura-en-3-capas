#!/bin/bash
set -e
sudo hostnamectl set-hostname WEBmariodasilva

#Instalamos en nfs
sudo apt update
sudo apt install nfs-common apache2 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl -y

#Creamos la carpeta de montaje
sudo mkdir -p /nfs/general

#Montamos la carpeta 
sudo mount 10.0.2.232:/var/nfs/general /nfs/general
echo "10.0.2.232:/var/nfs/general  /nfs/general  nfs _netdev,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf

# Configuracion para servir el contenido desde NFS
sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName https://marioaws.onthewifi.com
    ServerAdmin webmaster@localhost
    DocumentRoot /nfs/general/wordpress/
    
    <Directory /nfs/general/wordpress>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

#Deshabilitamos el que esta por defecto y reiniciamos el apache
sudo a2dissite 000-default.conf
sudo /usr/sbin/a2ensite wordpress.conf
sudo systemctl reload apache2