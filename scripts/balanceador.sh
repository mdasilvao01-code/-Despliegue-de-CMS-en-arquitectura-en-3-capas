#!/bin/bash
set -euo pipefail

# Actualización e instalación Apache y módulos
sudo apt-get update -y
sudo apt-get install -y apache2 openssl

# Habilitar módulos necesarios
sudo a2enmod proxy proxy_http proxy_balancer headers ssl

# Crear sitio de balanceo con SSL
sudo mkdir -p /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 \
  -subj "/CN=balanceador.local" \
  -newkey rsa:2048 -keyout /etc/apache2/ssl/balancer.key \
  -out /etc/apache2/ssl/balancer.crt

cat <<EOF | sudo tee /etc/apache2/sites-available/balancer.conf
<VirtualHost *:80>
    ServerName balanceador.local
    Header always set X-Student "Mario"
    ProxyPreserveHost On

    <Proxy "balancer://wpcluster">
        BalancerMember http://192.168.10.20
        BalancerMember http://192.168.10.21
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass "/" "balancer://wpcluster/"
    ProxyPassReverse "/" "balancer://wpcluster/"
</VirtualHost>

<VirtualHost *:443>
    ServerName balanceador.local
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/balancer.crt
    SSLCertificateKeyFile /etc/apache2/ssl/balancer.key

    Header always set X-Student "Mario"
    ProxyPreserveHost On

    <Proxy "balancer://wpcluster">
        BalancerMember http://192.168.10.20
        BalancerMember http://192.168.10.21
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass "/" "balancer://wpcluster/"
    ProxyPassReverse "/" "balancer://wpcluster/"
</VirtualHost>
EOF

sudo a2dissite 000-default.conf || true
sudo a2ensite balancer.conf
sudo systemctl enable apache2
sudo systemctl restart apache2