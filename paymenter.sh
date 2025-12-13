#!/bin/bash

# ==========================================
# PAYMENTER INSTALLATION SCRIPT
# Ubuntu 24.04 | Auto-Install with Warnings
# ==========================================

# Color codes for warnings
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# WARNING SECTION
# ==========================================
clear
echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                   ⚠️  PERINGATAN PENTING ⚠️               ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${RED}${BOLD}PERHATIAN:${NC}"
echo -e "${YELLOW}1. Script ini hanya untuk Ubuntu 24.04${NC}"
echo -e "${YELLOW}2. Pastikan Anda memiliki akses root/sudo${NC}"
echo -e "${YELLOW}3. Pastikan domain sudah mengarah ke IP server ini${NC}"
echo -e "${YELLOW}4. Backup data penting sebelum melanjutkan${NC}"
echo -e "${YELLOW}5. Proses ini akan menginstal banyak paket sistem${NC}"
echo ""
echo -e "${BLUE}Dependencies yang akan diinstal:${NC}"
echo "- Nginx, MariaDB, PHP 8.3"
echo "- Redis, Git, Curl, Unzip"
echo "- PHP extensions (mysql, gd, mbstring, bcmath, xml, fpm, curl, zip, intl, redis)"
echo ""

read -p "Apakah Anda ingin melihat informasi server terlebih dahulu? (y/n): " show_info
if [[ $show_info == "y" || $show_info == "Y" ]]; then
    # ==========================================
    # SERVER INFO SECTION
    # ==========================================
    echo ""
    echo -e "${GREEN}${BOLD}📊 INFORMASI SERVER:${NC}"
    echo "════════════════════════════════════"
    
    # OS Info
    echo -e "${BLUE}📦 Sistem Operasi:${NC}"
    lsb_release -a 2>/dev/null | grep "Description" || cat /etc/os-release | grep PRETTY_NAME
    
    # CPU Info
    echo -e "${BLUE}🖥️  CPU:${NC}"
    lscpu | grep "Model name" | head -1
    
    # Memory Info
    echo -e "${BLUE}💾 RAM:${NC}"
    free -h | awk 'NR==2{printf "Total: %s | Used: %s | Free: %s\n", $2, $3, $4}'
    
    # Disk Info
    echo -e "${BLUE}💿 DISK:${NC}"
    df -h / | awk 'NR==2{printf "Total: %s | Used: %s | Free: %s | Use: %s\n", $2, $3, $4, $5}'
    
    # IP Address
    echo -e "${BLUE}🌐 IP Address:${NC}"
    ip a | grep inet | grep -v "127.0.0.1" | grep -v "::1" | head -2
    
    echo "════════════════════════════════════"
    echo ""
fi

# ==========================================
# CONFIRMATION
# ==========================================
echo -e "${RED}${BOLD}⚠️  WARNING:${NC} Script akan melakukan perubahan sistem!"
echo -e "${YELLOW}Pastikan Anda sudah membackup data penting!${NC}"
echo ""
read -p "Apakah Anda ingin melanjutkan instalasi Paymenter? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 1
fi

# ==========================================
# DOMAIN INPUT
# ==========================================
echo ""
echo -e "${GREEN}${BOLD}🌐 KONFIGURASI DOMAIN${NC}"
echo "════════════════════════════════════"
echo -e "${YELLOW}Pastikan domain sudah mengarah ke IP server ini:${NC}"
ip a | grep inet | grep -v "127.0.0.1" | grep -v "::1" | awk '{print $2}' | cut -d/ -f1 | head -1
echo ""

while true; do
    read -p "Masukkan domain Anda (contoh: payment.domain.com): " domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Domain tidak boleh kosong!${NC}"
    elif [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Format domain tidak valid!${NC}"
    else
        read -p "Domain yang dimasukkan: ${domain} - Benar? (y/n): " verify
        if [[ $verify == "y" || $verify == "Y" ]]; then
            break
        fi
    fi
done

# ==========================================
# DATABASE PASSWORD
# ==========================================
echo ""
echo -e "${GREEN}${BOLD}🔐 KONFIGURASI DATABASE${NC}"
echo "════════════════════════════════════"

while true; do
    read -sp "Masukkan password untuk database user 'paymenter': " db_password
    echo ""
    
    if [[ -z "$db_password" ]]; then
        echo -e "${RED}Password tidak boleh kosong!${NC}"
        continue
    fi
    
    read -sp "Konfirmasi password: " db_password_confirm
    echo ""
    
    if [[ "$db_password" != "$db_password_confirm" ]]; then
        echo -e "${RED}Password tidak cocok!${NC}"
    else
        echo -e "${GREEN}✓ Password database disimpan${NC}"
        break
    fi
done

# ==========================================
# START INSTALLATION
# ==========================================
echo ""
echo -e "${GREEN}${BOLD}🚀 MULAI INSTALASI PAYMENTER${NC}"
echo "════════════════════════════════════"
echo -e "${YELLOW}Proses mungkin memakan waktu 5-10 menit...${NC}"
echo ""

# Update system
echo -e "${BLUE}[1/15] Mengupdate sistem...${NC}"
apt update && apt upgrade -y

# Install dependencies
echo -e "${BLUE}[2/15] Menginstal dependencies umum...${NC}"
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

# Add PHP repository
echo -e "${BLUE}[3/15] Menambahkan repository PHP 8.3...${NC}"
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

# Add MariaDB repository
echo -e "${BLUE}[4/15] Menambahkan repository MariaDB 10.11...${NC}"
curl -sSL https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-10.11"

# Update package list
echo -e "${BLUE}[5/15] Mengupdate daftar paket...${NC}"
apt update

# Install main packages
echo -e "${BLUE}[6/15] Menginstal paket utama (PHP, MariaDB, Nginx)...${NC}"
apt -y install php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} \
    mariadb-server nginx tar unzip git redis-server

# Create Paymenter directory
echo -e "${BLUE}[7/15] Membuat direktori Paymenter...${NC}"
mkdir -p /var/www/paymenter
cd /var/www/paymenter

# Download Paymenter
echo -e "${BLUE}[8/15] Mengunduh Paymenter terbaru...${NC}"
curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz

# Extract Paymenter
echo -e "${BLUE}[9/15] Mengekstrak Paymenter...${NC}"
tar -xzvf paymenter.tar.gz

# Set permissions
echo -e "${BLUE}[10/15] Mengatur permissions...${NC}"
chmod -R 755 storage/* bootstrap/cache/

# ==========================================
# DATABASE SETUP
# ==========================================
echo -e "${BLUE}[11/15] Mengatur database...${NC}"

# Start MariaDB if not running
systemctl start mariadb
systemctl enable mariadb

# Secure MariaDB installation (non-interactive)
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${db_password}';"
mysql -u root -p${db_password} -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p${db_password} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -p${db_password} -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p${db_password} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -p${db_password} -e "FLUSH PRIVILEGES;"

# Create Paymenter database and user
mysql -u root -p${db_password} <<EOF
CREATE USER IF NOT EXISTS 'paymenter'@'127.0.0.1' IDENTIFIED BY '${db_password}';
CREATE DATABASE IF NOT EXISTS paymenter;
GRANT ALL PRIVILEGES ON paymenter.* TO 'paymenter'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# ==========================================
# PAYMENTER CONFIGURATION
# ==========================================
echo -e "${BLUE}[12/15] Mengkonfigurasi Paymenter...${NC}"

# Create .env file
cp .env.example .env

# Generate encryption key
php artisan key:generate --force
php artisan storage:link

# Update .env with database credentials
sed -i "s/DB_DATABASE=.*/DB_DATABASE=paymenter/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=paymenter/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/" .env
sed -i "s/APP_URL=.*/APP_URL=https:\/\/${domain}/" .env

# Setup database
echo -e "${YELLOW}⚠️  Migrasi database mungkin memakan waktu beberapa menit...${NC}"
php artisan migrate --force --seed
php artisan db:seed --class=CustomPropertySeeder

# Initialize app
php artisan app:init

# Create admin user
echo ""
echo -e "${GREEN}${BOLD}👤 BUAT ADMIN USER${NC}"
echo "════════════════════════════════════"
php artisan app:user:create

# ==========================================
# CRONJOB & SERVICE SETUP
# ==========================================
echo -e "${BLUE}[13/15] Mengatur cronjob dan service...${NC}"

# Setup cronjob
(crontab -u www-data -l 2>/dev/null || true; echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -

# Create queue worker service
cat > /etc/systemd/system/paymenter.service <<EOF
[Unit]
Description=Paymenter Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable --now paymenter.service
systemctl enable --now redis-server

# ==========================================
# NGINX CONFIGURATION
# ==========================================
echo -e "${BLUE}[14/15] Mengkonfigurasi Nginx...${NC}"

# Create Nginx config
cat > /etc/nginx/sites-available/paymenter.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    root /var/www/paymenter/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ ^/index\.php(/|\$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
nginx -t

# Set permissions
chown -R www-data:www-data /var/www/paymenter/*

# Restart services
systemctl restart nginx
systemctl restart php8.3-fpm

# ==========================================
# SSL SETUP (OPTIONAL)
# ==========================================
echo ""
read -p "Apakah Anda ingin menginstal SSL certificate dengan Certbot? (y/n): " install_ssl

if [[ $install_ssl == "y" || $install_ssl == "Y" ]]; then
    echo -e "${BLUE}[15/15] Menginstal SSL certificate...${NC}"
    
    # Install Certbot
    apt install -y python3-certbot-nginx
    
    # Stop Nginx temporarily for Certbot
    systemctl stop nginx
    
    # Obtain SSL certificate
    if certbot certonly --nginx -d ${domain} --non-interactive --agree-tos --email admin@${domain}; then
        # Update Nginx config with SSL
        cat > /etc/nginx/sites-available/paymenter.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain};
    root /var/www/paymenter/public;

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ ^/index\.php(/|\$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }
}
EOF
        
        # Setup auto-renewal cronjob
        (crontab -l 2>/dev/null || true; echo "0 23 * * * certbot renew --quiet --deploy-hook 'systemctl restart nginx'") | crontab -
        
        echo -e "${GREEN}✓ SSL certificate berhasil diinstal${NC}"
    else
        echo -e "${YELLOW}⚠️  Gagal menginstal SSL certificate, melanjutkan tanpa SSL${NC}"
    fi
    
    # Start Nginx
    systemctl start nginx
else
    echo -e "${BLUE}[15/15] Melewati instalasi SSL...${NC}"
fi

# ==========================================
# FINALIZATION
# ==========================================
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}🎉 INSTALASI PAYMENTER SELESAI!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 INFORMASI INSTALASI:${NC}"
echo -e "  • Domain: ${GREEN}https://${domain}${NC}"
echo -e "  • Login URL: ${GREEN}https://${domain}/login${NC}"
echo -e "  • Database: ${GREEN}paymenter${NC}"
echo -e "  • Database User: ${GREEN}paymenter${NC}"
echo -e "  • Install Directory: ${GREEN}/var/www/paymenter${NC}"
echo ""
echo -e "${YELLOW}⚠️  CATATAN PENTING:${NC}"
echo -e "  1. Simpan password database Anda: ${RED}${db_password}${NC}"
echo -e "  2. Backup APP_KEY dari file: ${GREEN}/var/www/paymenter/.env${NC}"
echo -e "  3. Untuk update, jalankan: ${GREEN}cd /var/www/paymenter && php artisan app:upgrade${NC}"
echo ""
echo -e "${BLUE}🚀 Layanan yang berjalan:${NC}"
systemctl status nginx --no-pager
echo ""
systemctl status mariadb --no-pager
echo ""
systemctl status paymenter.service --no-pager
echo ""
echo -e "${GREEN}✅ Paymenter siap digunakan!${NC}"
