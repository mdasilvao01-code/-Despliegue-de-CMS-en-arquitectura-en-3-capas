#!/bin/bash
set -e
sudo hostnamectl set-hostname NFSmariodasilva

#Instalamos el servidor NFS
sudo apt update
sudo apt install nfs-kernel-server -y

#Creamos la carpeta a compartir 
sudo mkdir -p /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general

#Añadimos a los servidores web 
echo "/var/nfs/general 10.0.2.45(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/nfs/general 10.0.2.184(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

#Descargamos el wordpress
sudo apt install unzip -y
sudo wget -O /var/nfs/general/latest.zip https://wordpress.org/latest.zip
sudo unzip /var/nfs/general/latest.zip -d /var/nfs/general/

#Asignamos los correspondientes permisos y reiniciamos el servicio 
sudo chown -R www-data:www-data /var/nfs/general/wordpress
sudo find /var/nfs/general/wordpress/ -type d -exec chmod 755 {} \;
sudo find /var/nfs/general/wordpress/ -type f -exec chmod 644 {} \;
sudo systemctl restart nfs-kernel-server
sudo exportfs -a