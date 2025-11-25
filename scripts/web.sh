#!/bin/bash
set -euo pipefail

# Actualizar repositorios e instalar paquetes necesarios
sudo apt-get update -y
sudo apt-get install -y apache2 php php-mysql php-cli php-fpm nfs-common curl rsync

# Habilitar módulos correctos
sudo a2enmod rewrite headers proxy_fcgi setenvif
sudo a2enconf php8.2-fpm

# Montaje NFS para compartir wp-content y recursos
sudo mkdir -p /var/www/html/wp-content
echo "192.168.10.30:/srv/wp-shared /var/www/html/wp-content nfs rw,sync,hard,intr,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Descargar WordPress
cd /tmp
curl -sSL https://wordpress.org/latest.tar.gz -o wordpress.tar.gz
tar xzf wordpress.tar.gz

# Copiar WordPress excepto wp-content (ya montado desde NFS)
sudo rsync -a --exclude=wp-content wordpress/ /var/www/html/
sudo sed -i "s/Welcome/WordPress de MARIO/g" /var/www/html/wp-admin/about.php || true

# Permisos
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Configurar vhost
cat <<EOF | sudo tee /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerName wordpress.local
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    Header always set X-Student "Mario"
    ErrorLog \${APACHE_LOG_DIR}/wp_error.log
    CustomLog \${APACHE_LOG_DIR}/wp_access.log combined
</VirtualHost>
EOF

sudo a2dissite 000-default.conf || true
sudo a2ensite wordpress.conf
sudo systemctl enable apache2
sudo systemctl restart apache2