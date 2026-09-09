#!/bin/bash
# =======================================================
# MODUL CORE: INSTALLATION & UPDATES (FULL VERSION V3.1)
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

load_credentials() {
  if [ -f "$DB_FILE" ]; then
    source "$DB_FILE"
  else
    echo -e "${CR}[-] File db.txt tidak ditemukan! Harap jalankan instalasi Full (Opsi 1).${R}"
    exit 1
  fi
}

setup_swap() {
  if [ "$(free -m | awk '/^Swap:/ {print $2}')" -lt 2000 ] && [ ! -f /swapfile ]; then
    echo -e "${CY}[*] Menambahkan Virtual RAM (Swap) 2GB...${R}"
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile
  fi
}

install_nodejs() {
  if ! command -v node > /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    $PKG_MGR install -y nodejs
  fi
  if ! command -v yarn > /dev/null; then
    npm install -g yarn
  fi
}

process_addon() {
  local INPUT=$1
  if [ -z "$INPUT" ]; then return; fi
  echo -e "\n${CC}[*] Memproses Addon Kustom...${R}"
  rm -rf /tmp/exeren_addon && mkdir -p /tmp/exeren_addon
  if [[ "$INPUT" == http* ]]; then
    curl -L -o /tmp/addon.zip "$INPUT"
    unzip -o /tmp/addon.zip -d /tmp/exeren_addon > /dev/null
    rm -f /tmp/addon.zip
  elif [ -f "$INPUT" ]; then
    unzip -o "$INPUT" -d /tmp/exeren_addon > /dev/null
  else
    return
  fi
  cp -r /tmp/exeren_addon/* "$PANEL_DIR/" 2>/dev/null || true
  if [ -f "/tmp/exeren_addon/install.sh" ]; then
    chmod +x /tmp/exeren_addon/install.sh
    cd /tmp/exeren_addon && bash install.sh
  fi
  rm -rf /tmp/exeren_addon
  echo -e "${CG}[✓] Addon Berhasil Disatukan!${R}"
}

# ==========================================
# EKSEKUSI BERDASARKAN PILIHAN MENU
# ==========================================

if [ "$OPTION" == "1" ]; then
  mkdir -p "$ATHEMES_DIR"
  if [ -f "$DB_FILE" ]; then
    echo -e "${CG}[✓] Menggunakan kredensial dari $DB_FILE${R}"
    source "$DB_FILE"
  else
    echo -e "${CY}[*] SETUP PERTAMA - Kredensial akan disimpan di db.txt${R}"
    read -p "    URL Panel (cth: http://127.0.0.1): " PANEL_URL
    read -p "    Nama Database [panel]: " DB_NAME; DB_NAME=${DB_NAME:-panel}
    read -p "    Database Username [pterodactyl]: " DB_USER; DB_USER=${DB_USER:-pterodactyl}
    read -s -p "    Database Password: " DB_PASS; echo ""
    read -p "    Email Admin: " ADMIN_EMAIL
    read -p "    Username Admin: " ADMIN_USER
    read -p "    Nama Depan Admin: " ADMIN_FIRST
    read -p "    Nama Belakang Admin: " ADMIN_LAST
    read -s -p "    Password Admin: " ADMIN_PASS; echo ""
    
    cat << EOF > "$DB_FILE"
PANEL_URL="$PANEL_URL"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
ADMIN_EMAIL="$ADMIN_EMAIL"
ADMIN_USER="$ADMIN_USER"
ADMIN_FIRST="$ADMIN_FIRST"
ADMIN_LAST="$ADMIN_LAST"
ADMIN_PASS="$ADMIN_PASS"
EOF
  fi

  echo -e "\n${CY}[*] Memulai proses instalasi pada OS ${OS_NAME^^}...${R}"
  
  if [ "$PKG_MGR" == "apt" ]; then
    apt-get update -y && apt-get install -y git rsync tar curl unzip mariadb-server nginx php-common php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-fpm certbot python3-certbot-nginx
  else
    yum update -y && yum install -y epel-release git rsync tar curl unzip mariadb-server nginx php php-cli php-gd php-mysqlnd php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-fpm certbot python3-certbot-nginx
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  fi

  setup_swap
  install_nodejs

  echo -e "${CY}[*] Menyiapkan MariaDB...${R}"
  systemctl start mariadb || systemctl start mysql
  systemctl enable mariadb || systemctl enable mysql
  mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
  mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
  mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "FLUSH PRIVILEGES;"

  # ====================================================
  # BAGIAN YANG DIPERBAIKI: INSTALL CORE PTERODACTYL DULU
  # ====================================================
  echo -e "${CY}[*] Mengunduh File Inti Pterodactyl Panel...${R}"
  mkdir -p "$PANEL_DIR"
  curl -Lo /tmp/panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  tar -xzvf /tmp/panel.tar.gz -C "$PANEL_DIR"
  rm -f /tmp/panel.tar.gz
  
  echo -e "${CY}[*] Menimpa dengan tema aThemes dari GitHub...${R}"
  git clone https://github.com/AlnoXD404/athemes.git /tmp/athemes_tmp
  rsync -av --exclude='.git' /tmp/athemes_tmp/ "$PANEL_DIR/"
  rm -rf /tmp/athemes_tmp
  
  cd "$PANEL_DIR"
  chmod -R 755 storage/* bootstrap/cache/ 2>/dev/null || true
  chown -R $WEB_USER:$WEB_USER storage bootstrap/cache

  [ ! -f ".env" ] && ([ -f ".env.example" ] && cp .env.example .env || touch .env)
  sed -i "s|APP_URL=.*|APP_URL=$PANEL_URL|" .env
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

  echo -e "${CY}[*] Instalasi Composer (Backend)...${R}"
  composer install --no-dev --optimize-autoloader --no-interaction
  php artisan key:generate --force
  
  read -p "URL / Path Addon (Tekan Enter jika tidak ada): " ADDON_URL
  [ -n "$ADDON_URL" ] && process_addon "$ADDON_URL"

  echo -e "${CY}[*] Memproses dan mengkompilasi aset UI (Yarn Build)...${R}"
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  
  echo -e "\n${CY}[*] Mengonfigurasi Nginx Server Block...${R}"
  DOMAIN_ONLY=$(echo "$PANEL_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
  
  if [ "$PKG_MGR" == "apt" ]; then
    PHP_SOCKET=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n 1)
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
  else
    PHP_SOCKET="/run/php-fpm/www.sock"
  fi

  cat << EOF > $NGINX_CONF/pterodactyl.conf
server {
    listen 80;
    server_name $DOMAIN_ONLY;
    root /var/www/pterodactyl/public;
    index index.php index.html index.htm;
    access_log /var/log/nginx/pterodactyl.access.log;
    error_log /var/log/nginx/pterodactyl.error.log error;
    client_max_body_size 100m;
    client_body_buffer_size 100m;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_hide_header X-Powered-By;
    }
    location ~ /\.ht { deny all; }
}
EOF

  if [ "$PKG_MGR" == "apt" ]; then
    ln -sf $NGINX_CONF/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  fi
  
  if [ "$PKG_MGR" == "yum" ]; then systemctl enable php-fpm && systemctl start php-fpm; fi
  systemctl enable nginx && systemctl restart nginx
  
  php artisan migrate --force
  php artisan p:user:make --email="$ADMIN_EMAIL" --username="$ADMIN_USER" --name-first="$ADMIN_FIRST" --name-last="$ADMIN_LAST" --password="$ADMIN_PASS" --admin=1 --no-interaction || true
  php artisan optimize:clear
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  
  echo -e "\n${CY}[*] Mengonfigurasi SSL Certbot...${R}"
  if [[ ! "$DOMAIN_ONLY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    certbot --nginx -d "$DOMAIN_ONLY" --non-interactive --agree-tos -m "$ADMIN_EMAIL" --redirect || true
  fi
  
  echo -e "${CG}[✓] Instalasi Full aThemes berhasil diselesaikan!${R}"

# ... [Opsi 2, 3, 4, 5, 6 tetap sama] ...
elif [ "$OPTION" == "2" ]; then
  load_credentials
  mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\`; GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"
  cd "$PANEL_DIR" && php artisan migrate:fresh --force
  echo -e "${CG}[✓] Database berhasil direset!${R}"
elif [ "$OPTION" == "3" ]; then
  cd "$PANEL_DIR" && setup_swap && install_nodejs
  git clone https://github.com/AlnoXD404/athemes.git /tmp/athemes_tmp
  rsync -av --exclude='.git' /tmp/athemes_tmp/ "$PANEL_DIR/"
  rm -rf /tmp/athemes_tmp
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  php artisan view:clear && php artisan optimize:clear
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  echo -e "${CG}[✓] UI Berhasil di-rebuild.${R}"
elif [ "$OPTION" == "4" ]; then
  systemctl stop wings || true
  curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod +x /usr/local/bin/wings
  systemctl start wings
  echo -e "${CG}[✓] Wings diperbarui!${R}"
elif [ "$OPTION" == "5" ]; then
  rm -f "$DB_FILE"
  echo -e "${CG}[✓] File db.txt berhasil dihapus.${R}"
elif [ "$OPTION" == "6" ]; then
  read -p "URL / Path Addon (.zip): " ADDON_URL
  if [ -n "$ADDON_URL" ]; then
    process_addon "$ADDON_URL"
    cd "$PANEL_DIR" && setup_swap && install_nodejs
    yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
    php artisan optimize:clear
    chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
    echo -e "${CG}[✓] Addon Dipasang!${R}"
  fi
fi
