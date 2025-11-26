# 📌 Despliegue de CMS en Arquitectura de 3 Capas  
### Cluster WordPress con Balanceador Apache + NFS + MariaDB (Vagrant / Bash)

## 📝 Descripción  
Este proyecto despliega una arquitectura distribuida de **WordPress** compuesta por:

✔ **Balanceador Apache** con `mod_proxy_balancer` + SSL autofirmado  
✔ **Dos nodos web** con Apache + PHP  
✔ **Almacenamiento compartido (wp-content) vía NFS**  
✔ **Base de datos central con MariaDB**  
✔ **Todo automatizado con scripts Bash (opcionalmente con Vagrant)**  

> Ideal para prácticas de Sistemas, Redes, Virtualización y DevOps.

---

## 🏗️ Arquitectura (3 capas)


---

## 📂 Archivos incluidos

| Archivo | Función |
|--------|---------|
| `balanceador.sh` | Instala Apache como balanceador con SSL. |
| `web.sh` | Instala Apache+PHP, descarga WordPress y monta NFS. |
| `db_nfs.sh` | Configura servidor NFS + base de datos MariaDB. |
| `Vagrantfile` (opcional) | Permite desplegar todo con `vagrant up`. |

---

## 📌 Script: Balanceador Apache (`balanceador.sh`)

```bash
#!/bin/bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y apache2 openssl

sudo a2enmod ssl proxy proxy_balancer proxy_http lbmethod_byrequests headers

sudo mkdir -p /etc/apache2/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/balancer.key \
  -out /etc/apache2/ssl/balancer.crt \
  -subj "/CN=balanceador.local"

cat <<EOF | sudo tee /etc/apache2/sites-available/balancer.conf
<VirtualHost *:443>
   ServerName balanceador.local
   SSLEngine on
   SSLCertificateFile /etc/apache2/ssl/balancer.crt
   SSLCertificateKeyFile /etc/apache2/ssl/balancer.key

   <Proxy "balancer://wpcluster">
      BalancerMember http://192.168.10.20
      BalancerMember http://192.168.10.21
   </Proxy>

   ProxyPass / balancer://wpcluster/
   ProxyPassReverse / balancer://wpcluster/

   Header add X-Student "Mario"
</VirtualHost>
EOF

sudo a2dissite 000-default.conf
sudo a2ensite balancer.conf
sudo systemctl restart apache2

#!/bin/bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y apache2 php php-mysql php-gd php-xml php-mbstring nfs-common wget tar

sudo mkdir -p /var/www/html
echo "192.168.10.40:/srv/wp-shared /var/www/html/wp-content nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a

wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzf /tmp/latest.tar.gz -C /tmp
sudo cp -r /tmp/wordpress/* /var/www/html/

sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart apache2

#!/bin/bash
set -euo pipefail

# NFS
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server

sudo mkdir -p /srv/wp-shared
sudo chown -R 33:33 /srv/wp-shared
sudo chmod -R 755 /srv/wp-shared

echo "/srv/wp-shared 192.168.10.0/24(rw,sync,no_subtree_check,all_squash,anonuid=33,anongid=33)" | sudo tee /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# MariaDB
sudo apt-get install -y mariadb-server
sudo systemctl enable mariadb --now

sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('abcd') WHERE User='root';" || true
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" || true
sudo mysql -e "DROP DATABASE IF EXISTS test;" || true
sudo mysql -e "FLUSH PRIVILEGES;"

mysql -uroot -p"abcd" -e "CREATE DATABASE IF NOT EXISTS mario CHARACTER SET utf8mb4;"
mysql -uroot -p"abcd" -e "CREATE USER IF NOT EXISTS 'mario'@'192.168.10.%' IDENTIFIED BY 'abcd';"
mysql -uroot -p"abcd" -e "GRANT ALL PRIVILEGES ON mario.* TO 'mario'@'192.168.10.%'; FLUSH PRIVILEGES;"
