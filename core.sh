#!/bin/bash
# =======================================================
# MODUL CORE: INSTALLATION & UPDATES (STABLE V4.8)
# FITUR: Auto-Setup Node, Safe DB, Fix Perm, Auto-Detect DB
# =======================================================
OPTION=$1
CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CC="\e[36m"; R="\e[0m"

PANEL_DIR="/var/www/pterodactyl"
# Lokasi aman di folder home user agar tidak terhapus saat Uninstall
DB_DIR="$HOME/.athemes_installer"
DB_FILE="$DB_DIR/db.txt"

# OS Detection Engine
. /etc/os-release
OS_NAME=$ID
if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
  PKG_MGR="apt"; WEB_USER="www-data"; NGINX_CONF="/etc/nginx/sites-available"
else
  PKG_MGR="yum"; WEB_USER="nginx"; NGINX_CONF="/etc/nginx/conf.d"
fi

# ==========================================
# FUNGSI: AUTO-CREATE db.txt (Jika belum ada)
# ==========================================
create_credentials() {
  mkdir -p "$DB_DIR"
  echo -e "\n${CY}[*] DATA db.txt BELUM ADA - Silakan isi data berikut (otomatis disimpan ke $DB_FILE):${R}"
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
  echo -e "${CG}[✓] Data berhasil disimpan otomatis ke $DB_FILE${R}\n"
}

load_credentials() {
  if [ -f "$DB_FILE" ]; then
    echo -e "${CG}[✓] Menggunakan data dari $DB_FILE${R}"
    source "$DB_FILE"
  else
    create_credentials
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

# Fungsi Memperbaiki Hak Akses 
fix_permissions_and_cache() {
  echo -e "${CY}[*] Memperbaiki Hak Akses dan Membersihkan Cache Sistem...${R}"
  cd "$PANEL_DIR"
  php artisan view:clear
  php artisan config:clear
  php artisan cache:clear
  php artisan optimize:clear
  rm -rf storage/framework/sessions/* 2>/dev/null || true
  chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
  chmod -R 775 storage bootstrap/cache
}

# ==========================================
# EKSEKUSI BERDASARKAN PILIHAN MENU
# ==========================================

if [ "$OPTION" == "1" ]; then
  load_credentials
  echo -e "${CY}[*] Memulai proses instalasi pada OS ${OS_NAME^^}...${R}"
  
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
  
  # ========================================================
  # CEK DATABASE LAMA (Ide dari Rehan - Mengatasi Error 500)
  # ========================================================
  if mysql -e "SHOW DATABASES;" | grep -q "^${DB_NAME}$"; then
    echo -e "\n${CR}========================================================================${R}"
    echo -e "${CY}[!] PERINGATAN: Database '${DB_NAME}' sudah ada di sistem beserta datanya.${R}"
    echo -e "${CY}[!] Jika ini adalah Install Ulang, menggunakan database lama bisa memicu${R}"
    echo -e "${CY}    Error 500 karena Kunci Enkripsi (APP_KEY) yang baru tidak cocok.${R}"
    echo -e "${CR}========================================================================${R}"
    
    read -p "Apakah Anda ingin MENGHAPUS & MERESET database tersebut? (y/n): " RESET_DB
    if [[ "$RESET_DB" == "y" || "$RESET_DB" == "Y" ]]; then
      mysql -e "DROP DATABASE \`${DB_NAME}\`;"
      echo -e "${CG}[✓] Database lama berhasil dihapus! Melanjutkan Fresh Install...${R}"
    else
      echo -e "${CC}[*] Tetap menggunakan database lama. (Mengabaikan pembuatan akun baru)${R}"
    fi
  fi
  # ========================================================

  mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
  mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
  mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "FLUSH PRIVILEGES;"

  echo -e "${CY}[*] Mengunduh File Inti Pterodactyl Panel...${R}"
  mkdir -p "$PANEL_DIR"
  curl -Lo /tmp/panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  tar -xzvf /tmp/panel.tar.gz -C "$PANEL_DIR"
  rm -f /tmp/panel.tar.gz
  
  echo -e "${CY}[*] Menimpa dengan tema aThemes dari GitHub...${R}"
  cd /tmp 
  rm -rf /tmp/athemes_tmp
  git clone https://github.com/AlnoXD404/athemes.git /tmp/athemes_tmp
  rsync -av --exclude='.git' /tmp/athemes_tmp/ "$PANEL_DIR/"
  rm -rf /tmp/athemes_tmp
  
  sed -i 's|</head>|<style>input, input:focus { color: #1f2937 !important; }</style></head>|g' "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
  
  cd "$PANEL_DIR"
  [ ! -f ".env" ] && ([ -f ".env.example" ] && cp .env.example .env || touch .env)
  sed -i "s|APP_URL=.*|APP_URL=$PANEL_URL|" .env
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
  
  sed -i "s|APP_ENVIRONMENT_ONLY=true|APP_ENVIRONMENT_ONLY=false|g" .env
  grep -q "APP_ENVIRONMENT_ONLY=false" .env || echo "APP_ENVIRONMENT_ONLY=false" >> .env

  grep -q "^APP_KEY=" .env && sed -i 's|^APP_KEY=.*|APP_KEY=base64:WnBqa1R6Y0N1R2R1a0hOa1R6Y0N1R2R1a0hOa1R6YWM=|' .env || echo "APP_KEY=base64:WnBqa1R6Y0N1R2R1a0hOa1R6Y0N1R2R1a0hOa1R6YWM=" >> .env

  echo -e "${CY}[*] Instalasi Composer (Backend)...${R}"
  composer install --no-dev --optimize-autoloader --no-interaction
  
  php artisan key:generate --force
  
  echo -e ""
  read -p "Apakah Anda ingin memasang Addon kustom? (y/n): " ASK_ADDON
  if [[ "$ASK_ADDON" == "y" || "$ASK_ADDON" == "Y" ]]; then
    read -p "Masukkan URL / Path Addon (.zip): " ADDON_URL
    [ -n "$ADDON_URL" ] && process_addon "$ADDON_URL"
  fi

  echo -e "${CY}[*] Memproses dan mengkompilasi aset UI (Yarn Build)...${R}"
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  
  echo -e "\n${CY}[*] Mengonfigurasi Nginx Server Block...${R}"
  DOMAIN_ONLY=$(echo "$PANEL_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
  
  if [ "$PKG_MGR" == "apt" ]; then
    PHP_V=$(php -v | head -n 1 | awk '{print $2}' | cut -d. -f1,2)
    PHP_SOCKET="/run/php/php${PHP_V}-fpm.sock"
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
  
  echo -e "\n${CY}[*] Menyiapkan Database, Akun Admin, dan Auto-Setup Node...${R}"
  php artisan migrate --force
  
  # Pembuatan User dilindungi || true (Akan gagal tapi aman jika user pilih "n" di reset DB tadi)
  php artisan p:user:make --email="$ADMIN_EMAIL" --username="$ADMIN_USER" --name-first="$ADMIN_FIRST" --name-last="$ADMIN_LAST" --password="$ADMIN_PASS" --admin=1 --no-interaction > /dev/null 2>&1 || true
  
  cat << EOF > /var/www/pterodactyl/auto_setup.php
\$loc = \Pterodactyl\Models\Location::firstOrCreate(
    ['short' => 'ID-1'],
    ['long' => 'Indonesia Server']
);
\$node = \Pterodactyl\Models\Node::firstOrCreate(
    ['name' => 'Node-01'],
    [
        'description' => 'Node Otomatis dari Installer',
        'location_id' => \$loc->id,
        'public' => 1,
        'fqdn' => '$DOMAIN_ONLY',
        'scheme' => 'http',
        'behind_proxy' => 0,
        'memory' => 4096,
        'memory_overallocate' => 0,
        'disk' => 40960,
        'disk_overallocate' => 0,
        'daemon_listen' => 8080,
        'daemon_sftp' => 2022,
        'daemonBase' => '/var/lib/pterodactyl/volumes',
    ]
);
for (\$port = 25565; \$port <= 25575; \$port++) {
    \Pterodactyl\Models\Allocation::firstOrCreate([
        'node_id' => \$node->id,
        'ip' => '0.0.0.0',
        'port' => \$port
    ]);
}
EOF
  php artisan tinker < /var/www/pterodactyl/auto_setup.php
  rm -f /var/www/pterodactyl/auto_setup.php
  
  fix_permissions_and_cache
  
  echo -e "\n${CY}[*] Mengonfigurasi SSL Certbot...${R}"
  if [[ ! "$DOMAIN_ONLY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    certbot --nginx -d "$DOMAIN_ONLY" --non-interactive --agree-tos -m "$ADMIN_EMAIL" --redirect || true
  fi
  
  echo -e "${CG}[✓] Instalasi Full aThemes berhasil diselesaikan! Panel Siap Pakai!${R}"

elif [ "$OPTION" == "2" ]; then
  load_credentials
  echo -e "\n${CY}[*] Mereset Database Pterodactyl...${R}"
  mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\`; GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"
  cd "$PANEL_DIR" && php artisan migrate:fresh --force
  echo -e "${CG}[✓] Database berhasil direset!${R}"

elif [ "$OPTION" == "3" ]; then
  cd "$PANEL_DIR" && setup_swap && install_nodejs
  cd /tmp 
  rm -rf /tmp/athemes_tmp
  git clone https://github.com/AlnoXD404/athemes.git /tmp/athemes_tmp
  rsync -av --exclude='.git' /tmp/athemes_tmp/ "$PANEL_DIR/"
  rm -rf /tmp/athemes_tmp
  
  sed -i 's|</head>|<style>input, input:focus { color: #1f2937 !important; }</style></head>|g' "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
  
  cd "$PANEL_DIR"
  yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
  fix_permissions_and_cache
  echo -e "${CG}[✓] UI Berhasil di-rebuild.${R}"

elif [ "$OPTION" == "4" ]; then
  systemctl stop wings || true
  curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod +x /usr/local/bin/wings
  systemctl start wings
  echo -e "${CG}[✓] Wings diperbarui/diinstall!${R}"

elif [ "$OPTION" == "5" ]; then
  rm -f "$DB_FILE"
  echo -e "${CG}[✓] File db.txt berhasil dihapus dari $DB_DIR.${R}"

elif [ "$OPTION" == "6" ]; then
  read -p "Masukkan URL / Path Addon (.zip): " ADDON_URL
  if [ -n "$ADDON_URL" ]; then
    process_addon "$ADDON_URL"
    cd "$PANEL_DIR" && setup_swap && install_nodejs
    yarn install && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production
    fix_permissions_and_cache
    echo -e "${CG}[✓] Addon Dipasang!${R}"
  fi

elif [ "$OPTION" == "7" ]; then
  echo -e "\n${CY}[*] Mengunduh dan Menyuntikkan Nests & Eggs Bawaan Pterodactyl...${R}"
  if [ -d "$PANEL_DIR" ]; then
    cd "$PANEL_DIR"
    php artisan db:seed --force
    php artisan cache:clear
    echo -e "${CG}[✓] Sukses! Semua Eggs bawaan telah ditambahkan ke panel.${R}"
  else
    echo -e "${CR}[!] Error: Pterodactyl belum terinstal di server ini!${R}"
  fi

elif [ "$OPTION" == "8" ]; then
  source "$DB_FILE" 2>/dev/null
  echo -e "\n${CR}====================================================${R}"
  echo -e "${CR} PERINGATAN BAHAYA: PROSES INI BERSIFAT PERMANEN! ${R}"
  echo -e "${CR}====================================================${R}"
  
  read -p "Apakah Anda ingin UNINSTALL PTERODACTYL PANEL? (y/n): " DEL_PANEL
  read -p "Apakah Anda ingin UNINSTALL WINGS? (y/n): " DEL_WINGS
  read -p "Apakah Anda ingin HAPUS KONFIGURASI SSL/CERTBOT? (y/n): " DEL_CERT
  
  echo -e "\nKonfirmasi Pilihan Anda:"
  [[ "$DEL_PANEL" == "y" || "$DEL_PANEL" == "Y" ]] && echo - "- Hapus Panel (Database & File)"
  [[ "$DEL_WINGS" == "y" || "$DEL_WINGS" == "Y" ]] && echo - "- Hapus Wings (Daemon & Data Server)"
  [[ "$DEL_CERT" == "y" || "$DEL_CERT" == "Y" ]] && echo - "- Hapus SSL/Certbot Nginx"
  
  echo -e ""
  read -p "Apakah Anda YAKIN ingin melanjutkan eksekusi ini? (y/n): " CONFIRM_ALL
  
  if [[ "$CONFIRM_ALL" == "y" || "$CONFIRM_ALL" == "Y" ]]; then
    if [[ "$DEL_PANEL" == "y" || "$DEL_PANEL" == "Y" ]]; then
      echo -e "\n${CY}[*] Menghapus File Panel & Web Server...${R}"
      systemctl stop pteroq 2>/dev/null
      rm -rf /var/www/pterodactyl
      rm -rf /var/www/athemes
      rm -f /etc/nginx/sites-available/pterodactyl.conf
      rm -f /etc/nginx/sites-enabled/pterodactyl.conf
      rm -f /etc/nginx/conf.d/pterodactyl.conf
      systemctl restart nginx 2>/dev/null
      rm -f /etc/systemd/system/pteroq.service
      systemctl daemon-reload
      
      echo -e "${CY}[*] Menghapus Database Panel...${R}"
      mysql -e "DROP DATABASE IF EXISTS \`panel\`;"
      mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;"
      mysql -e "DROP USER IF EXISTS 'pterodactyl'@'localhost';"
      echo -e "${CG}[✓] Panel Pterodactyl berhasil dihapus!${R}"
    fi

    if [[ "$DEL_WINGS" == "y" || "$DEL_WINGS" == "Y" ]]; then
      echo -e "\n${CY}[*] Menghapus Wings & Konfigurasi Sistem...${R}"
      systemctl stop wings 2>/dev/null
      rm -rf /etc/pterodactyl
      rm -rf /var/lib/pterodactyl
      rm -f /usr/local/bin/wings
      rm -f /etc/systemd/system/wings.service
      systemctl daemon-reload
      echo -e "${CG}[✓] Wings berhasil dihapus!${R}"
    fi

    if [[ "$DEL_CERT" == "y" || "$DEL_CERT" == "Y" ]]; then
      echo -e "\n${CY}[*] Membersihkan Konfigurasi SSL/Certbot...${R}"
      if [ "$PKG_MGR" == "apt" ]; then
        apt-get remove --purge -y certbot python3-certbot-nginx
      else
        yum remove -y certbot python3-certbot-nginx
      fi
      rm -rf /etc/letsencrypt
      rm -rf /var/lib/letsencrypt
      rm -rf /var/log/letsencrypt
      echo -e "${CG}[✓] SSL dan Certbot berhasil dibersihkan!${R}"
    fi
    echo -e "\n${CG}[✓] Proses Uninstall Selesai!${R}"
  else
    echo -e "\n${CC}[*] Proses uninstall dibatalkan. Kembali ke terminal...${R}"
  fi

fi
