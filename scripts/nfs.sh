#!/bin/bash
set -euo pipefail

# Instalar NFS server
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server

# Crear carpeta compartida
sudo mkdir -p /srv/wp-shared

# Asignar propietario www-data (UID/GID 33)
sudo chown -R 33:33 /srv/wp-shared
sudo chmod -R 755 /srv/wp-shared

# Exportar carpeta para la red privada
echo "/srv/wp-shared 192.168.10.0/24(rw,sync,no_subtree_check,all_squash,anonuid=33,anongid=33)" | sudo tee /etc/exports

# Aplicar exportación y reiniciar servicio
sudo exportfs -ra
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server