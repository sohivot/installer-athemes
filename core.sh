#!/bin/bash
# =======================================================
# MODUL CORE: INSTALLATION & UPDATES
# =======================================================
OPTION=$1
CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CC="\e[36m"; R="\e[0m"
PANEL_DIR="/var/www/pterodactyl"
ATHEMES_DIR="/var/www/athemes"
DB_FILE="$ATHEMES_DIR/db.txt"

# OS Detection Engine
. /etc/os-release
OS_NAME=$ID
if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
  PKG_MGR="apt"; WEB_USER="www-data"; NGINX_CONF="/etc/nginx/sites-available"
else
  PKG_MGR="yum"; WEB_USER="nginx"; NGINX_CONF="/etc/nginx/conf.d"
fi

setup_swap() {
  if [ "$(free -m | awk '/^Swap:/ {print $2}')" -lt 2000 ] && [ ! -f /swapfile ]; then
    echo -e "${CY}[*] Kapasitas RAM terbatas. Menambahkan Virtual RAM (Swap) 2GB...${R}"
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile
  fi
}

if [ "$OPTION" == "1" ]; then
  echo -e "\n${CY}[*] Memulai proses instalasi pada OS ${OS_NAME^^}...${R}"
  mkdir -p "$PANEL_DIR"
  
  echo -e "${CY}[*] Menginstal perangkat lunak yang dibutuhkan...${R}"
  if [ "$PKG_MGR" == "apt" ]; then
    apt-get update -y && apt-get install -y git curl unzip mariadb-server nginx php-common php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-fpm
  else
    yum update -y && yum install -y epel-release git curl unzip mariadb-server nginx php php-cli php-gd php-mysqlnd php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-fpm
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  fi

  setup_swap
  echo -e "${CY}[*] Menyiapkan NodeJS & Yarn untuk kompilasi tema...${R}"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && $PKG_MGR install -y nodejs
  npm install -g yarn

  echo -e "${CY}[*] Mengunduh aset tema aThemes dari repositori...${R}"
  git clone https://github.com/AlnoXD404/athemes.git /tmp/athemes_tmp
  rsync -av --exclude='.git' /tmp/athemes_tmp/ "$PANEL_DIR/"
  
  cd "$PANEL_DIR"
  echo -e "${CY}[*] Memproses dan mengkompilasi aset UI (Ini mungkin memakan waktu beberapa menit)...${R}"
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  
  echo -e "${CG}[✓] Instalasi aThemes berhasil diselesaikan!${R}"

elif [ "$OPTION" == "3" ]; then
  echo -e "${CY}[*] Memulai proses pembaruan dan perbaikan antarmuka...${R}"
  cd "$PANEL_DIR" && setup_swap
  echo -e "${CY}[*] Sedang membangun ulang aset (Rebuild UI)...${R}"
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  echo -e "${CG}[✓] Antarmuka panel berhasil diperbarui dan disegarkan.${R}"
fi
