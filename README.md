# -Despliegue-de-CMS-en-arquitectura-en-3-capas
# Proyecto: Cluster WordPress con Balanceador Apache (Vagrant / Bash)

**Descripción**  
Este repositorio contiene scripts y recursos para desplegar un clúster simple de WordPress con un balanceador de carga Apache y servidores web que comparten `wp-content` vía NFS. Está pensado para entornos de laboratorio (Vagrant / máquinas Ubuntu/Debian) y uso didáctico. Los scripts automatizan la instalación y configuración básica: Apache, PHP, NFS, y un balanceador con SSL auto-firmado.

---

## Arquitectura (resumen)
             +------------------+
             |  balanceador     |  (Apache + mod_proxy_balancer)
             |  192.168.10.10 ? |
             +--------+---------+
                      |
     -----------------+-----------------
     |                                 |



> Nota: Las IP mostradas (192.168.10.20 / .21 / .30) aparecen en los scripts; adáptalas a tu red/Vagrantfile si es necesario.

---

## Archivos principales
- `balanceador.sh` — Script para instalar y configurar Apache como balanceador (mod_proxy, mod_proxy_balancer), crear certificado SSL auto-firmado y habilitar el VirtualHost con `balancer://wpcluster`. Contiene header personalizado `X-Student "Mario"`.
- `web.sh` — Script para instalar Apache + PHP, montar NFS con `wp-content`, descargar WordPress y preparar el vhost `wordpress.local`. Ajusta `fstab` para montar `192.168.10.30:/srv/wp-shared`.
- `Vagrantfile` — (Incluido en el repo) Recomendado para levantar las máquinas de laboratorio. Ejecutar `vagrant up` desde la raíz para provisión (ver Vagrantfile para detalles).

---

## Requisitos
- Host con VirtualBox + Vagrant (si usas Vagrant). Alternativa: máquinas Ubuntu/Debian.
- Conexión de red entre las VMs (host-only o red privada).
- Acceso `sudo` en las máquinas objetivo.
- (Opcional) Ajusta `/etc/hosts` en tu equipo para mapear `wordpress.local` y `balanceador.local` a las IPs de las VMs si quieres probar en un navegador.

---

## Instrucciones rápidas (ejemplo con Vagrant)
1. Clona este repositorio:
   ```bash


# Proyecto: Cluster WordPress con Balanceador y Servidores Web + NFS + MariaDB

**Descripción**  
Este repositorio contiene scripts y recursos para desplegar un clúster de WordPress con:

- Balanceador Apache con `mod_proxy_balancer` + SSL autofirmado.
- 2 nodos web independientes con Apache + PHP.
- Carpeta `wp-content` compartida vía NFS.
- Base de datos MariaDB gestionada desde una VM central.
- Configuración automática vía scripts Bash.

Ideal para entornos educativos con **Vagrant**, **VirtualBox** o cualquier entorno Linux Debian/Ubuntu.

---

## 🏗️ Arquitectura


---

## 📂 Archivos principales en este repo

| Archivo | Descripción |
|---------|-------------|
| `balanceador.sh` | Instala Apache balanceador + certificado SSL. |
| `web.sh` | Configura Apache+PHP, descarga WordPress, monta NFS. |
| `db_nfs.sh` | (Nuevo) Configura MariaDB + carpeta NFS compartida. |
| `Vagrantfile` | Estructura de máquinas Vagrant (opcional). |

---

## 🗄️ Script: NFS + MariaDB (db_nfs.sh)

> **Este script debe ejecutar en la máquina 192.168.10.40**

```bash
#!/bin/bash
set -euo pipefail

# ----------------------------------------
# Instalar NFS server
# ----------------------------------------
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

# ----------------------------------------
# Instalar MariaDB
# ----------------------------------------
sudo apt-get update -y
sudo apt-get install -y mariadb-server

sudo systemctl enable mariadb
sudo systemctl start mariadb

# Endurecer mínimo (sin interacción)
sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('abcd') WHERE User='root';" || true
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" || true
sudo mysql -e "DROP DATABASE IF EXISTS test;" || true
sudo mysql -e "FLUSH PRIVILEGES;" || true

# Crear BD y usuario para WordPress
mysql -uroot -p"abcd" -e "CREATE DATABASE IF NOT EXISTS mario CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p"abcd" -e "CREATE USER IF NOT EXISTS 'mario'@'192.168.10.%' IDENTIFIED BY 'abcd';"
mysql -uroot -p"abcd" -e "GRANT ALL PRIVILEGES ON mario.* TO 'mario'@'192.168.10.%'; FLUSH PRIVILEGES;"

# Info final para wp-config.php
cat <<EOF
===================== DATOS PARA WORDPRESS =====================

DB_NAME: mario
DB_USER: mario
DB_PASSWORD: abcd
DB_HOST: 192.168.10.40

=================================================================
EOF


   git clone <tu-repo-url>.git
   cd <tu-repo>
