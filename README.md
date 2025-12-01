# 🚀 Despliegue Completo CMS en AWS — Arquitectura 3 Capas  
🔥 *Balanceador + Web1/Web2 + Base de Datos + NFS* 🔥  

Este proyecto despliega un CMS (WordPress) en AWS utilizando una infraestructura profesional de **3 capas**, con servidores conectados por NFS, una base de datos MariaDB privada y un balanceador Apache2 con SSL.

Incluye los scripts completos de despliegue:

- `balanceador.sh`
- `db.sh` (MariaDB)
- `nfs.sh` (Servidor NFS)
- `web.sh` (Servidores Web conectados a NFS)

---

# 📑 Índice

1. [🧱 Arquitectura General](#🧱-arquitectura-general)
2. [📦 Componentes del Proyecto](#📦-componentes-del-proyecto)
3. [🛡️ Security Groups AWS](#🛡️-security-groups-aws)
4. [🌀 Scripts de Configuración](#🌀-scripts-de-configuración)
   - [Balanceador](#balanceador)
   - [Base de Datos (MariaDB)](#base-de-datos-mariadb)
   - [Servidor NFS](#servidor-nfs)
   - [Servidores Web](#servidores-web)
5. [🧪 Pruebas Finales](#🧪-pruebas-finales)
6. [📎 Mejoras Futuras](#📎-mejoras-futuras)

---



---

# 📦 Componentes del Proyecto

| Componente | Función |
|-----------|---------|
| **Balanceador** | SSL + Proxy + Load Balancing |
| **NFS Server** | Directorio compartido para WordPress |
| **Web1 / Web2** | Apache + PHP conectados al NFS |
| **MariaDB** | Base de datos del CMS |

---

# 🛡️ Security Groups AWS

| SG | Permite | Desde |
|----|---------|--------|
| **SG-BAL** | 80/443 | Internet |
| **SG-WEB** | 80 | BAL |
| **SG-NFS** | 2049 | WEB1/WEB2 |
| **SG-DB** | 3306 | WEB1/WEB2 |
| **SG-SSH** | 22 | Tu IP |

---

# 🌀 Scripts de Configuración

---

# 🔥 **Balanceador**
Archivo: `balanceador.sh`

```bash
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
    Redirect permanent / https://marioaws.onthewifi.com/
</VirtualHost>
EOF

sudo tee /etc/apache2/sites-available/load-balancer-ssl.conf > /dev/null <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName marioaws.onthewifi.com

    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/marioaws.onthewifi.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/marioaws.onthewifi.com/privkey.pem

    <Proxy "balancer://mycluster">
        ProxySet stickysession=JSESSIONID|ROUTEID
        BalancerMember http://10.0.2.45:80
        BalancerMember http://10.0.2.184:80
    </Proxy>

    ProxyPass "/" "balancer://mycluster/"
    ProxyPassReverse "/" "balancer://mycluster/"
</VirtualHost>
</IfModule>
EOF

sudo a2dissite 000-default.conf
sudo a2ensite load-balancer.conf
sudo a2ensite load-balancer-ssl.conf
sudo systemctl reload apache2

```

# 🔥 **NFS**
Archivo: `nfs.sh`

```bash

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

sudo sed -i 's/^bind-address.*/bind-address = 10.0.3.111/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

```

# 🔥 **db**
Archivo: `db.sh`
```bash

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

sudo sed -i 's/^bind-address.*/bind-address = 10.0.3.111/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

```

# 🔥 **web**
Archivo: `web.sh`

```bash

#!/bin/bash
set -e
sudo hostnamectl set-hostname WEBmariodasilva

sudo apt update
sudo apt install nfs-common apache2 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl -y

sudo mkdir -p /nfs/general

sudo mount 10.0.2.232:/var/nfs/general /nfs/general
echo "10.0.2.232:/var/nfs/general  /nfs/general  nfs _netdev,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab

sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf

sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName https://marioaws.onthewifi.com
    DocumentRoot /nfs/general/wordpress/

    <Directory /nfs/general/wordpress>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo systemctl reload apache2

`🧱 Arquitectura General
