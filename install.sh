#!/bin/bash

# ===============================
#   🚀 Ubuntu Setup Assistant 🚀
# ===============================
clear

# Fungsi untuk tampilan seperti Winfetch
function show_info() {
    echo -e "\e[1;36m"
echo " /$$$$$$$            /$$                    "
echo "| $$__  $$          | $$                    "
echo "| $$  \ $$ /$$   /$$| $$ /$$$$$$$$ /$$   /$$"
echo "| $$$$$$$/| $$  | $$| $$|____ /$$/|  $$ /$$/"
echo "| $$__  $$| $$  | $$| $$   /$$$$/  \  $$$$/ "
echo "| $$  \ $$| $$  | $$| $$  /$$__/    >$$  $$ "
echo "| $$  | $$|  $$$$$$/| $$ /$$$$$$$$ /$$/\  $$"
echo "|__/  |__/ \______/ |__/|________/|__/  \__/"
echo -e "\e[0m"
    echo -e "🖥️  Hostname   : \e[1;33m$(hostname)\e[0m"
    echo -e "📦 Distro     : \e[1;33m$(lsb_release -ds)\e[0m"
    echo -e "🧠 Kernel     : \e[1;33m$(uname -r)\e[0m"
    echo -e "🧮 Arch       : \e[1;33m$(dpkg --print-architecture)\e[0m"
    echo -e "📡 IP Address : \e[1;33m$(hostname -I | awk '{print $1}')\e[0m"
    echo ""
}

# Fungsi untuk install Docker
function install_docker() {
    echo -e "\n\e[1;34m[🔧] Mengupdate sistem dan mengatur repository Docker...\e[0m"
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    echo -e "\n\e[1;34m[📦] Menginstall Docker...\e[0m"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "\n\e[1;32m✅ Docker berhasil diinstal!\e[0m"
    docker --version
}

# Fungsi untuk install Immich
function install_immich() {
    echo -e "\n\e[1;34m📥 Membuat direktori ./immich-app...\e[0m"
    mkdir -p immich-app
    cd immich-app || exit

    echo -e "\n\e[1;34m⬇️  Mengunduh docker-compose.yml dan .env...\e[0m"
    wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
    wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env

    echo -e "\n\e[1;34m⚙️ Mengatur konfigurasi default .env...\e[0m"
    sed -i 's|^UPLOAD_LOCATION=.*|UPLOAD_LOCATION=./library|' .env
    sed -i 's|^DB_DATA_LOCATION=.*|DB_DATA_LOCATION=./postgres|' .env
    sed -i 's|^IMMICH_VERSION=.*|IMMICH_VERSION=release|' .env
    sed -i 's|^DB_PASSWORD=.*|DB_PASSWORD=postgres|' .env

    echo -e "\n\e[1;34m🚀 Menjalankan container Immich...\e[0m"
    docker compose up -d

    echo -e "\n\e[1;32m✅ Immich berhasil dijalankan di background!\e[0m"
    echo -e "📂 Direktori: $(pwd)"
    echo -e "📝 File: docker-compose.yml & .env"
}

# Fungsi untuk install PHP 8.4 + Composer + Laravel
function install_laravel() {
    echo -e "\n\e[1;34m[🐘] Menginstall PHP 8.4, Composer, dan Laravel...\e[0m"
    /bin/bash -c "$(curl -fsSL https://php.new/install/linux/8.4)"

    echo -e "\n\e[1;32m✅ PHP & Composer berhasil diinstal!\e[0m"
    php -v
    composer -V

    echo -e "\n\e[1;34m⬇️  Menginstal Laravel installer...\e[0m"
    composer global require laravel/installer

    echo -e "\n\e[1;32m✅ Laravel installer berhasil diinstal!\e[0m"
    echo -e "Gunakan perintah berikut untuk membuat project Laravel baru:"
    echo -e "  \e[1;33mlaravel new example-app\e[0m"
    echo -e "  \e[1;33mcd example-app\e[0m"
    echo -e "  \e[1;33mnpm install && npm run build\e[0m"
    echo -e "  \e[1;33mcomposer run dev\e[0m"
}

# Fungsi untuk setup RDP CLI-only + XFCE GUI
function setup_rdp() {
    echo -e "\n\e[1;34m[🖥️] Mengatur Ubuntu agar boot ke CLI dan GUI hanya muncul di RDP...\e[0m"

    # Update sistem
    sudo apt update && sudo apt upgrade -y

    # Install XFCE + XRDP
    echo -e "\n\e[1;34m📦 Menginstal XFCE dan XRDP...\e[0m"
    sudo apt install -y xfce4 xfce4-goodies xrdp

    # Set XFCE sebagai default session
    echo xfce4-session > ~/.xsession

    # Modifikasi startwm.sh
    sudo sed -i '/^test -x/ i\unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nstartxfce4' /etc/xrdp/startwm.sh

    # Enable dan start xrdp
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp

    # Izinkan port 3389
    sudo ufw allow 3389/tcp

    # Set agar boot ke CLI
    sudo systemctl set-default multi-user.target

    echo -e "\n\e[1;32m✅ Setup selesai!\e[0m"
    echo -e "💡 Sistem akan boot ke CLI (tanpa GUI)"
    echo -e "💻 Akses GUI via RDP dari Windows:"
    echo -e "  IP: \e[1;33m$(hostname -I | awk '{print $1}')\e[0m Port: \e[1;33m3389\e[0m"
    echo -e "🪟 Gunakan Remote Desktop (mstsc.exe) untuk login XFCE GUI!"
}

# Show info
show_info

# Menu
echo -e "\n\e[1;35mSilakan pilih opsi:\e[0m"
echo -e "1) Install Docker"
echo -e "2) Install Immich"
echo -e "3) Install PHP 8.4 + Composer + Laravel"
echo -e "4) Setup Ubuntu sebagai RDP Server (CLI only + XFCE via RDP)"
read -p $'\nPilih opsi (1/2/3/4): ' opt

case $opt in
  1)
    install_docker
    ;;
  2)
    install_immich
    ;;
  3)
    install_laravel
    ;;
  4)
    setup_rdp
    ;;
  *)
    echo -e "\n\e[1;31mOpsi tidak valid!\e[0m"
    ;;
esac
