#!/bin/bash

# ===============================
#   🚀 Ubuntu Setup Assistant 🚀
# ===============================
clear

# Fungsi untuk tampilan seperti Winfetch
function show_info() {
    echo -e "\e[1;36m"
    echo "       ___       __         __         "
    echo "  ____/ (_)___  / /_  ___  / /__  _____ "
    echo " / __  / / __ \/ __ \/ _ \/ / _ \/ ___/ "
    echo "/ /_/ / / /_/ / / / /  __/ /  __(__  )  "
    echo "\__,_/_/ .___/_/ /_/\___/_/\___/____/   "
    echo "       /_/                              "
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

# Show info
show_info

# Menu
echo -e "\n\e[1;35mSilakan pilih opsi:\e[0m"
echo -e "1) Install Docker"
echo -e "2) Install Immich"
read -p $'\nPilih opsi (1/2): ' opt

case $opt in
  1)
    install_docker
    ;;
  2)
    install_immich
    ;;
  *)
    echo -e "\n\e[1;31mOpsi tidak valid!\e[0m"
    ;;
esac
