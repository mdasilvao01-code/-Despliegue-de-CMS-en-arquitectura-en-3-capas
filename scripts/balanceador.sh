#!/bin/bash
# Hostname
sudo hostnamectl set-hostname BalanceadorMarioDaSilva

#Instalamos Apache 
sudo apt update
sudo apt install apache2 -y
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests proxy_connect ssl headers

#Reiniciamos Apache para cargar modulos
sudo systemctl restart apache2

#Copiamos el archivo de config base
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/load-balancer.conf

sudo tee /etc/apache2/sites-available/load-balancer.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName marioaws.onthewifi.com
    ServerAdmin webmaster@localhost

    # Redireccion permanente HTTP → HTTPS
    Redirect permanent / https://marioaws.onthewifi.com/

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# --- CONFIGURACIÓN SSL + BALANCEO ---
sudo tee /etc/apache2/sites-available/load-balancer-ssl.conf > /dev/null <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName marioaws.onthewifi.com

    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/marioaws.onthewifi.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/marioaws.onthewifi.com/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf

    <Proxy "balancer://mycluster">
        ProxySet stickysession=JSESSIONID|ROUTEID

        # Servidor Web 1
        BalancerMember http://10.0.2.45:80

        # Servidor Web 2
        BalancerMember http://10.0.2.184:80
    </Proxy>

    # Reenvio de trafico al balanceador
    ProxyPass "/" "balancer://mycluster/"
    ProxyPassReverse "/" "balancer://mycluster/"

    ErrorLog \${APACHE_LOG_DIR}/ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
</IfModule>
EOF

#Deshabilitamos el sitio por defecto
sudo a2dissite 000-default.conf

#Activamos y reiniciamos apache2
sudo a2ensite load-balancer.conf
sudo a2ensite load-balancer-ssl.conf
sudo systemctl reload apache2
