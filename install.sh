#!/bin/bash
# =======================================================
# PTERODACTYL aTHEMES INSTALLER (v1.7)
# Ultimate Edition + Smart Addon Engine (Jadi 1)
# Developed by Exeren
# =======================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Error: Harap jalankan skrip ini menggunakan sudo!\e[0m"
  exit 1
fi

CG="\e[32m"
CR="\e[31m"
CY="\e[33m"
CB="\e[34m"
CC="\e[36m"
R="\e[0m"

PANEL_DIR="/var/www/pterodactyl"
ATHEMES_DIR="/var/www/athemes"
ATHEMES_REPO="https://github.com/AlnoXD404/athemes.git"
DB_FILE="$ATHEMES_DIR/db.txt"

load_credentials() {
  mkdir -p "$ATHEMES_DIR"
  if [ -f "$DB_FILE" ]; then
    echo -e "${CG}[✓] Menggunakan kredensial permanen dari $DB_FILE${R}"
    source "$DB_FILE"
    sleep 1
    return
  fi

  clear
  echo -e "${CB}==================================================${R}"
  echo -e "${CC}   aTHEMES INSTALLER + SMART ADDON ENGINE         ${R}"
  echo -e "${CB}==================================================${R}"
  echo -e "${CY}[*] SETUP PERTAMA - Kredensial akan disimpan di db.txt${R}"
  read -p "    URL Panel / Domain (cth: http://127.0.0.1): " PANEL_URL
  echo ""
  echo -e "${CY}--- Konfigurasi Database MariaDB ---${R}"
  read -p "    Nama Database [panel]: " DB_NAME
  DB_NAME=${DB_NAME:-panel}
  read -p "    Database Username [pterodactyl]: " DB_USER
  DB_USER=${DB_USER:-pterodactyl}
  read -s -p "    Database Password: " DB_PASS
  echo ""
  echo ""
  echo -e "${CY}--- Akun Administrator Panel ---${R}"
  read -p "    Email Admin: " ADMIN_EMAIL
  read -p "    Username Admin: " ADMIN_USER
  read -p "    Nama Depan Admin: " ADMIN_FIRST
  read -p "    Nama Belakang Admin: " ADMIN_LAST
  read -s -p "    Password Admin: " ADMIN_PASS
  echo ""

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
  echo -e "${CG}[✓] Kredensial berhasil disimpan PERMANEN di db.txt${R}"
  sleep 1
}

setup_swap() {
  SWAP_SIZE=$(free -m | awk '/^Swap:/ {print $2}')
  if [ "$SWAP_SIZE" -lt 2000 ]; then
    echo -e "${CY}[*] Menambahkan Virtual RAM (Swap) 2GB...${R}"
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    fi
  fi
}

install_nodejs() {
  if ! command -v node > /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
  fi
  if ! command -v yarn > /dev/null; then
    npm install -g yarn
  fi
}

# FUNGSI SMART ADDON INSTALLER (Bisa URL atau Path Lokal)
process_addon() {
  local INPUT=$1
  if [ -z "$INPUT" ]; then return; fi
  
  echo -e "\n${CC}[*] MEMPROSES ADDON (Trash Bin / Lainnya)...${R}"
  rm -rf /tmp/exeren_addon && mkdir -p /tmp/exeren_addon
  
  if [[ "$INPUT" == http* ]]; then
    echo -e "${CY}[*] Mengunduh Addon dari URL...${R}"
    curl -L -o /tmp/addon.zip "$INPUT"
    unzip -o /tmp/addon.zip -d /tmp/exeren_addon > /dev/null
    rm -f /tmp/addon.zip
  elif [ -f "$INPUT" ]; then
    echo -e "${CY}[*] Mengekstrak Addon Lokal...${R}"
    unzip -o "$INPUT" -d /tmp/exeren_addon > /dev/null
  else
    echo -e "${CR}[-] Input tidak valid (Bukan URL / File). Melewati Addon.${R}"
    return
  fi

  echo -e "${CY}[*] Menerapkan File Addon ke Panel...${R}"
  cp -r /tmp/exeren_addon/* "$PANEL_DIR/" 2>/dev/null || true

  if [ -f "/tmp/exeren_addon/install.sh" ]; then
    chmod +x /tmp/exeren_addon/install.sh
    cd /tmp/exeren_addon && bash install.sh
  elif [ -f "/tmp/exeren_addon/patch.sh" ]; then
    chmod +x /tmp/exeren_addon/patch.sh
    cd /tmp/exeren_addon && bash patch.sh
  fi
  
  cd "$PANEL_DIR"
  rm -rf /tmp/exeren_addon
  echo -e "${CG}[✓] File Addon Berhasil Disatukan dengan aThemes!${R}"
}

show_menu() {
  clear
  echo -e "${CB}==================================================${R}"
  echo -e "${CG}        aTHEMES PURE MENU (By Exeren)             ${R}"
  echo -e "${CB}==================================================${R}"
  echo -e " ${CY}[1]${R} Install Full aThemes (Sekaligus Pasang Addon)"
  echo -e " ${CY}[2]${R} Reset & Kosongkan Database (Clean Start)"
  echo -e " ${CY}[3]${R} Update Tema & Rebuild Aset (Fix UI)"
  echo -e " ${CY}[4]${R} Update Wings Daemon"
  echo -e " ${CY}[5]${R} Hapus & Atur Ulang Data db.txt"
  echo -e " ${CC}--- SMART ADDON ENGINE ---${R}"
  echo -e " ${CC}[6]${R} Pasang Addon Kustom (Butuh URL / Path .ZIP)"
  echo -e " ${CR}--- DANGER ZONE ---${R}"
  echo -e " ${CR}[8]${R} Uninstall Panel & Wings (Hapus Total)"
  echo -e " ${CR}[0]${R} Keluar"
  echo -e "${CB}==================================================${R}"
  read -p "Pilih opsi [0-8]: " OPTION
}

load_credentials

while true; do
  show_menu
  case $OPTION in
    1)
      echo -e "\n${CY}[*] Memulai Instalasi Full aThemes...${R}"
      
      if [ -d "$PANEL_DIR" ]; then
        systemctl is-active --quiet wings && systemctl stop wings || true
        read -p "[?] Hapus folder panel lama untuk clean install? (y/n): " WIPE_CHOICE
        [[ "$WIPE_CHOICE" =~ ^[Yy]$ ]] && rm -rf "$PANEL_DIR" && mkdir -p "$PANEL_DIR"
      else
        mkdir -p "$PANEL_DIR"
      fi

      echo -e "${CY}[*] Memasang Dependensi...${R}"
      apt-get update -y
      apt-get install -y git rsync unzip curl composer mariadb-server ca-certificates gnupg
      
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

      echo -e "${CY}[*] Mengunduh Tema aThemes...${R}"
      git clone "$ATHEMES_REPO" /tmp/athemes_tmp
      mkdir -p "$ATHEMES_DIR"
      rsync -av --delete --exclude='.git' --exclude='install.sh' --exclude='db.txt' /tmp/athemes_tmp/ "$ATHEMES_DIR/"
      rm -rf /tmp/athemes_tmp

      cd "$PANEL_DIR"
      rsync -av --exclude='.git' --exclude='install.sh' --exclude='db.txt' --exclude='.env' "$ATHEMES_DIR/" "$PANEL_DIR/"

      mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache
      chmod -R 755 storage bootstrap/cache
      chown -R www-data:www-data storage bootstrap/cache

      [ ! -f ".env" ] && ([ -f ".env.example" ] && cp .env.example .env || touch .env)
      sed -i "s|APP_URL=.*|APP_URL=$PANEL_URL|" .env
      sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
      sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
      sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

      composer install --no-dev --optimize-autoloader --no-interaction
      php artisan key:generate --force
      
      # ==== INTEGRASI ADDON JADI SATU DI SINI ====
      echo -e "\n${CC}==================================================${R}"
      echo -e "${CC}[?] INTEGRASI ADDON (OPTIONAL)${R}"
      echo -e "Jika kamu punya Addon Trash Bin (atau lainnya), kamu bisa memasangnya sekarang."
      echo -e "Ketik URL Download / Path Lokal .zip, atau ${CR}tekan Enter${R} untuk melewati."
      read -p "URL / Path Addon: " ADDON_URL
      
      if [ -n "$ADDON_URL" ]; then
        process_addon "$ADDON_URL"
      fi
      # ===========================================

      echo -e "\n${CY}[*] Kompilasi Laravel & UI React (Yarn Build)...${R}"
      export NODE_OPTIONS=--max_old_space_size=4096
      yarn install && yarn build:production

      mkdir -p /etc/pterodactyl
      curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
      chmod +x /usr/local/bin/wings
      if [ ! -f /etc/systemd/system/wings.service ]; then
        cat << 'EOF' > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=always
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable wings
      fi
      systemctl start wings

      php artisan migrate --force
      php artisan p:user:make --email="$ADMIN_EMAIL" --username="$ADMIN_USER" --name-first="$ADMIN_FIRST" --name-last="$ADMIN_LAST" --password="$ADMIN_PASS" --admin=1 --no-interaction || true

      php artisan optimize:clear
      chown -R www-data:www-data "$PANEL_DIR"
      chmod -R 755 "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"

      echo -e "\n${CG}[✓] INSTALASI SELESAI DENGAN SUKSES!${R}"
      read -p "Tekan [Enter] untuk kembali..."
      ;;
    
    2|3|4)
      echo -e "\n${CY}[*] Menjalankan Opsi $OPTION...${R}"
      if [ "$OPTION" == "4" ]; then systemctl stop wings || true; curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64; chmod +x /usr/local/bin/wings; systemctl start wings; echo -e "${CG}[✓] Wings Diperbarui!${R}"; fi
      if [ "$OPTION" == "2" ]; then mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\`; GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"; cd "$PANEL_DIR" && php artisan migrate:fresh --force && echo -e "${CG}[✓] Database direset!${R}"; fi
      if [ "$OPTION" == "3" ]; then 
        cd "$PANEL_DIR" && rsync -av --exclude='.git' --exclude='install.sh' --exclude='db.txt' --exclude='.env' "$ATHEMES_DIR/" "$PANEL_DIR/"
        setup_swap; export NODE_OPTIONS=--max_old_space_size=4096; yarn install && yarn build:production
        php artisan view:clear && php artisan optimize:clear && chown -R www-data:www-data "$PANEL_DIR" && echo -e "${CG}[✓] Tema aThemes berhasil diperbarui!${R}"
      fi
      read -p "Tekan [Enter] untuk kembali..."
      ;;

    5)
      echo -e "\n${CY}[*] Menghapus data permanen di db.txt...${R}"
      rm -f "$DB_FILE"
      echo -e "${CG}[✓] Data dihapus. Silakan jalankan ulang opsi ini untuk setup baru.${R}"
      load_credentials
      ;;

    6)
      echo -e "\n${CC}[*] SMART ADDON ENGINE...${R}"
      echo -e "Ketik URL Download / Path Lokal file .zip Addon (contoh: /root/TrashBin.zip)"
      read -p "URL / Path: " ADDON_URL
      
      if [ -n "$ADDON_URL" ]; then
        process_addon "$ADDON_URL"
        echo -e "${CY}[*] Membangun ulang UI (Yarn Build)...${R}"
        cd "$PANEL_DIR"
        install_nodejs
        setup_swap
        export NODE_OPTIONS=--max_old_space_size=4096
        yarn install && yarn build:production
        php artisan optimize:clear
        chown -R www-data:www-data "$PANEL_DIR"
        echo -e "${CG}[✓] Addon Kustom Berhasil Dipasang dan Dikompilasi!${R}"
      fi
      read -p "Tekan [Enter] untuk kembali..."
      ;;

    8)
      read -p "Ketik 'HAPUS' untuk konfirmasi Uninstalasi: " CONFIRM_UNINSTALL
      if [ "$CONFIRM_UNINSTALL" == "HAPUS" ]; then
        systemctl stop wings 2>/dev/null || true
        systemctl disable wings 2>/dev/null || true
        rm -f /etc/systemd/system/wings.service
        systemctl daemon-reload
        rm -f /usr/local/bin/wings
        rm -rf /etc/pterodactyl
        mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;" 2>/dev/null || true
        mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
        rm -rf "$PANEL_DIR"
        rm -rf /root/.npm /root/.yarn /root/.cache/yarn 2>/dev/null || true
        echo -e "${CG}[✓] UNINSTALASI BERHASIL! Server telah bersih dari Panel & Wings.${R}"
      fi
      read -p "Tekan [Enter] untuk kembali ke menu..."
      ;;

    0)
      echo -e "${CG}Keluar. Terima kasih telah menggunakan Installer By Exeren!${R}"
      exit 0
      ;;
    *)
      echo -e "${CR}[-] Pilihan tidak valid!${R}"
      sleep 1
      ;;
  esac
done
