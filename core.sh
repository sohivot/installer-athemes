#!/bin/bash
# =======================================================
# MODUL CORE: INSTALLATION ONLY
# By: Exeren
# =======================================================
OPTION=$1
CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CC="\e[36m"; R="\e[0m"

PANEL_DIR="/var/www/pterodactyl"
DB_DIR="$HOME/.athemes_installer"
DB_FILE="$DB_DIR/db.txt"

. /etc/os-release
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  PKG_MGR="apt"; WEB_USER="www-data"; NGINX_CONF="/etc/nginx/sites-available"
else
  PKG_MGR="yum"; WEB_USER="nginx"; NGINX_CONF="/etc/nginx/conf.d"
fi

ask_credentials() {
  if [ -f "$DB_FILE" ]; then
    echo -e "${CG}[✓] Menggunakan data dari $DB_FILE${R}"
    source "$DB_FILE"
  else
    mkdir -p "$DB_DIR"
    echo -e "\n${CY}[*] SETUP KREDENSIAL AWAL:${R}"
    read -p "    URL Panel (cth: http://127.0.0.1): " PANEL_URL
    read -p "    Nama Database [panel]: " DB_NAME; DB_NAME=${DB_NAME:-panel}
    read -p "    Database Username [pterodactyl]: " DB_USER; DB_USER=${DB_USER:-pterodactyl}
    read -s -p "    Database Password: " DB_PASS; echo ""
    read -p "    Email Admin: " ADMIN_EMAIL
    read -p "    Username Admin: " ADMIN_USER
    read -s -p "    Password Admin: " ADMIN_PASS; echo ""
    
    cat << EOF > "$DB_FILE"
PANEL_URL="$PANEL_URL"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
ADMIN_EMAIL="$ADMIN_EMAIL"
ADMIN_USER="$ADMIN_USER"
ADMIN_PASS="$ADMIN_PASS"
EOF
  fi
  DOMAIN_ONLY=$(echo "$PANEL_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
}

setup_db_mysql() {
  systemctl start mariadb || systemctl start mysql
  systemctl enable mariadb || systemctl enable mysql
  if mysql -e "SHOW DATABASES;" | grep -q "^${DB_NAME}$"; then
    echo -e "\n${CY}[!] Database '${DB_NAME}' sudah ada!${R}"
    read -p "Hapus & Reset database lama? (y/n): " RESET_DB
    if [[ "$RESET_DB" == "y" || "$RESET_DB" == "Y" ]]; then
      mysql -e "DROP DATABASE \`${DB_NAME}\`;"
    fi
  fi
  mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
  mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
  mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "FLUSH PRIVILEGES;"
}

fix_permissions_and_cache() {
  cd "$PANEL_DIR"
  php artisan view:clear >/dev/null 2>&1
  php artisan config:clear >/dev/null 2>&1
  php artisan cache:clear >/dev/null 2>&1
  php artisan optimize:clear >/dev/null 2>&1
  rm -rf storage/framework/sessions/* 2>/dev/null || true
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  chmod -R 775 storage bootstrap/cache
}

if [[ "$OPTION" == "1" || "$OPTION" == "2" ]]; then
  ask_credentials
  echo -e "\n${CY}[*] Menginstal Dependensi Sistem...${R}"
  $PKG_MGR update -y -q
  $PKG_MGR install -y -q curl tar unzip git rsync mariadb-server nginx php-common php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip php-intl php-fpm nodejs npm
  npm install -g yarn >/dev/null 2>&1
  setup_db_mysql
  
  echo -e "${CY}[*] Mengunduh File Inti Pterodactyl...${R}"
  mkdir -p "$PANEL_DIR"
  curl -sLo /tmp/panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  tar -xzf /tmp/panel.tar.gz -C "$PANEL_DIR"
  rm -f /tmp/panel.tar.gz

  if [[ "$OPTION" == "2" ]]; then
    echo -e "${CY}[*] Menyuntikkan aThemes Custom UI...${R}"
    cd /tmp && git clone -q https://github.com/AlnoXD404/athemes.git athemes_tmp
    rsync -a --exclude='.git' athemes_tmp/ "$PANEL_DIR/"
    rm -rf athemes_tmp
    sed -i 's|</head>|<style>input, input:focus { color: #1f2937 !important; }</style></head>|g' "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
  fi

  echo -e "${CY}[*] Mengonfigurasi Environment & Composer...${R}"
  cd "$PANEL_DIR"
  cp .env.example .env
  echo "APP_KEY=base64:WnBqa1R6Y0N1R2R1a0hOa1R6Y0N1R2R1a0hOa1R6YWM=" >> .env 
  sed -i "s|APP_URL=.*|APP_URL=$PANEL_URL|" .env
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
  sed -i "s|APP_ENVIRONMENT_ONLY=true|APP_ENVIRONMENT_ONLY=false|g" .env

  curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
  php composer.phar install --no-dev --optimize-autoloader --no-interaction >/dev/null 2>&1
  php artisan key:generate --force >/dev/null 2>&1
  php artisan migrate --force >/dev/null 2>&1
  php artisan db:seed --force >/dev/null 2>&1
  php artisan p:user:make --email="$ADMIN_EMAIL" --username="$ADMIN_USER" --name-first="Admin" --name-last="User" --password="$ADMIN_PASS" --admin=1 --no-interaction >/dev/null 2>&1 || true

  if [[ "$OPTION" == "2" ]]; then
    echo -e "${CY}[*] Membangun Aset aThemes (Yarn Build)...${R}"
    yarn install >/dev/null 2>&1 && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production >/dev/null 2>&1
  fi

  echo -e "${CY}[*] Mengonfigurasi Nginx...${R}"
  PHP_V=$(php -v | head -n 1 | awk '{print $2}' | cut -d. -f1,2)
  PHP_SOCKET="/run/php/php${PHP_V}-fpm.sock"
  rm -f /etc/nginx/sites-enabled/default
  cat << EOF > $NGINX_CONF/pterodactyl.conf
server {
    listen 80; server_name $DOMAIN_ONLY; root /var/www/pterodactyl/public; index index.php;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_pass unix:$PHP_SOCKET; fastcgi_index index.php; include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
  ln -sf $NGINX_CONF/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  
  fix_permissions_and_cache
  systemctl restart nginx
  echo -e "\n${CG}[✓] Instalasi Selesai! Buka: $PANEL_URL${R}"

elif [[ "$OPTION" == "3" ]]; then
  echo -e "\n${CY}[*] Menginstal Wings...${R}"
  mkdir -p /etc/pterodactyl
  curl -sL -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod +x /usr/local/bin/wings
  systemctl daemon-reload
  echo -e "${CG}[✓] Wings terinstal! Letakkan config.yml lalu jalankan: systemctl start wings${R}"
fi
