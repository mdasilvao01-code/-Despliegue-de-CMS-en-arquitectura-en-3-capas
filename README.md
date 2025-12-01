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

# 🧱 Arquitectura General — Despliegue CMS en AWS (3 Capas)

La infraestructura está diseñada siguiendo un modelo profesional de **3 capas**, asegurando separación de servicios, mayor seguridad, escalabilidad y alta disponibilidad. La comunicación se realiza mediante subredes privadas y públicas dentro de una VPC en AWS.

---

## 🌍 Vista General de la Arquitectura

┌───────────────────────────┐
│ Internet 🌍 │
└──────────────┬────────────┘
│
┌───────▼────────┐
│ BALANCEADOR │
│ Apache2 + SSL │
│ Proxy + LB │
└───────┬────────┘
┌───────────┴───────────────┐
│ │
┌──▼──┐ ┌────▼───┐
│ WEB1│ │ WEB2 │
│ Apache + PHP │ Apache + PHP
│ WordPress desde NFS │ WordPress desde NFS
└──┬──┘ └───┬────┘
│ │
└──────────────┬─────────────┘
│
┌───────▼────────┐
│ NFS SERVER │
│ WordPress │
│ Compartido │
└───────┬────────┘
│
┌───────▼────────┐
│ MariaDB │
│ Base de datos │
└─────────────────
---

## 🧩 Componentes Principales

### 🔥 1. **Balanceador de Carga (EC2)**
- Apache2 con módulos: `proxy`, `proxy_http`, `proxy_balancer`, `ssl`
- Certificado SSL Let’s Encrypt
- Redirección HTTP → HTTPS  
- Distribución del tráfico a WEB1 y WEB2

---

### 🌐 2. **Servidores Web (WEB1 y WEB2)**
- Apache2 + PHP  
- Montan el WordPress desde el servidor NFS  
- Conexión directa a la base de datos MariaDB  
- Funcionan detrás del balanceador

---

### 📁 3. **Servidor NFS**
- Almacena los archivos de WordPress  
- Carpeta compartida con Web1/Web2  
- Permisos configurados para Apache y NFS

---

### 🗄️ 4. **Base de Datos (MariaDB)**
- Contiene la base de datos del CMS  
- Acceso limitado a Web1/Web2 mediante IP privada  
- Configurada dentro de subred privada

---

## 🛡️ Seguridad de la Arquitectura

| Capa | Seguridad | Descripción |
|------|-----------|-------------|
| **Balanceador** | SG público (80/443) | Único punto expuesto a Internet |
| **Web** | SG interno | Solo acepta tráfico del balanceador |
| **NFS** | SG privado | Solo permite acceso desde Web1/Web2 |
| **MariaDB** | SG privado | Solo accesible desde Web1/Web2 |
| **SSH** | Acceso restringido | Solo desde la IP del administrador |

---

## 🛰️ Comunicación entre Componentes

- Balanceador ↔ Web: tráfico HTTP/HTTPS interno  
- Web ↔ NFS: tráfico NFS (2049)  
- Web ↔ MariaDB: puerto 3306  
- No hay acceso directo desde Internet a Web, NFS o BD  

---

## 🏗️ Resumen de Beneficios

- ✔ Alta disponibilidad  
- ✔ Escalabilidad horizontal (más web servers si se necesita)  
- ✔ Seguridad por aislamiento de capas  
- ✔ Centralización del WordPress mediante NFS  
- ✔ Tráfico cifrado con SSL  

---

## 📌 Conclusión

Esta arquitectura aprovecha lo mejor de AWS para construir un entorno profesional y modular, ideal para aplicaciones CMS como WordPress, con separación de responsabilidades y un flujo seguro entre capas.



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

```


# 🏗️ Despliegue de Infraestructura AWS — Paso a Paso con Capturas

Este documento presenta **todas las fases de construcción de la infraestructura en AWS**, acompañadas de **capturas reales** de cada paso:

- Creación de VPC  
- Subredes  
- Internet Gateway  
- NAT Gateway  
- Tablas de rutas  
- Security Groups  
- Instancias EC2  
- Comprobaciones finales  

---

# 📦 1. Crear la VPC

## 1.1 Acceder al servicio VPC
📌 Navega en AWS → *VPC* → *Your VPCs* → **Create VPC**

![Descripción de la imagen](/imagen.png)

---

## 1.2 Configurar la nueva VPC
- Nombre: `VPC-WordPress`
- IPv4 CIDR: `10.0.0.0/16`
- Tenancy: Default

👉 *Inserta aquí la captura de la configuración final antes de crearla*

---

# 🌐 2. Crear Subredes

## 2.1 Subred Pública 1 (Zona A)
- Nombre: `Public-Subnet-A`
- CIDR: `10.0.1.0/24`
- AZ: `eu-west-1a`

👉 *Inserta aquí la captura de la creación de la subred pública*

---

## 2.2 Subred Pública 2 (Zona B)
- Nombre: `Public-Subnet-B`
- CIDR: `10.0.2.0/24`
- AZ: `eu-west-1b`

👉 *Inserta aquí la captura*

---

## 2.3 Subred Privada (Base de datos)
- Nombre: `Private-DB-Subnet`
- CIDR: `10.0.3.0/24`
- AZ: `eu-west-1a`

👉 *Inserta aquí la captura*

---

# 🌍 3. Crear Internet Gateway

## 3.1 Crear el IGW
VPC → *Internet Gateways* → **Create Internet Gateway**

👉 *Inserta aquí la captura de la creación*

---

## 3.2 Asociarlo a la VPC
- Seleccionar IGW → *Actions* → Attach to VPC

👉 *Inserta aquí la captura de la asociación*

---

# 🔄 4. Crear NAT Gateway (opcional para BD privada)

## 4.1 Crear Elastic IP
EC2 → Network & Security → **Elastic IPs**

👉 *Inserta captura del Elastic IP creado*

---

## 4.2 Crear NAT Gateway
VPC → *NAT Gateways* → **Create NAT Gateway**

- Subred: `Public-Subnet-A`
- Elastic IP: creado antes

👉 *Inserta captura del NAT Gateway*

---

# 🚦 5. Tablas de Rutas

## 5.1 Tabla de rutas pública
- Ruta: `0.0.0.0/0` → IGW

👉 *Inserta captura de la tabla pública*

---

## 5.2 Tabla de rutas privada (para BD)
- Ruta: `0.0.0.0/0` → NAT Gateway

👉 *Inserta captura de la tabla privada*

---

# 🔐 6. Crear Security Groups

## 6.1 SG-BAL (Balanceador)
Reglas de entrada:
- 80 (HTTP) → 0.0.0.0/0
- 443 (HTTPS) → 0.0.0.0/0
- 22 (SSH) → Tu IP

👉 *Inserta captura del SG*

---

## 6.2 SG-WEB (Web1 y Web2)
Reglas:
- HTTP 80 → SG-BAL  
- NFS 2049 → SG-NFS  
- MySQL 3306 → SG-DB  

👉 *Inserta captura del SG-WEB*

---

## 6.3 SG-DB (MariaDB)
Reglas:
- 3306 → SG-WEB  

👉 *Inserta captura*

---

## 6.4 SG-NFS
Reglas:
- 2049 → SG-WEB  

👉 *Inserta captura*

---

# 🖥️ 7. Crear las instancias EC2

## 7.1 Instancia del Balanceador
- AMI: Ubuntu 22.04  
- Tipo: t2.micro  
- Subred: Pública  
- SG: **SG-BAL**  
- Script: `balanceador.sh`  

👉 *Inserta captura del lanzamiento*

---

## 7.2 Instancias Web (WEB1 / WEB2)
- AMI: Ubuntu  
- Tipo: t2.micro  
- Subred: Pública  
- SG: **SG-WEB**  
- Script: `web.sh`  

👉 *Inserta captura de Web1*  
👉 *Inserta captura de Web2*

---

## 7.3 Instancia de la Base de Datos
- AMI: Ubuntu  
- Subred: **Privada**  
- SG: SG-DB  
- Script: `db.sh`

👉 *Inserta captura*

---

## 7.4 Instancia del Servidor NFS
- AMI: Ubuntu  
- Subred: Pública  
- SG: SG-NFS  
- Script: `nfs.sh`

👉 *Inserta captura*

---

# 🧪 8. Pruebas Finales

## 8.1 Comprobar el balanceo
Acceder varias veces al dominio:
