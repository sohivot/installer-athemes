#!/bin/bash
# =======================================================
# MODUL UNINSTALLER: CLEANING & DB MANAGER
# By: Exeren
# =======================================================
OPTION=$1
CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CC="\e[36m"; R="\e[0m"
PANEL_DIR="/var/www/pterodactyl"

. /etc/os-release
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  WEB_USER="www-data"
else
  WEB_USER="nginx"
fi

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

# 4. UNINSTALL ATHEMES (Kembali ke Original)
if [[ "$OPTION" == "4" ]]; then
  echo -e "\n${CY}[*] Menghapus aThemes dan mengembalikan Panel Original...${R}"
  cd "$PANEL_DIR"
  curl -sLo /tmp/panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  tar -xzf /tmp/panel.tar.gz -C "$PANEL_DIR"
  rm -f /tmp/panel.tar.gz
  
  echo -e "${CY}[*] Membangun ulang UI Original...${R}"
  yarn install >/dev/null 2>&1 && NODE_OPTIONS=--max_old_space_size=4096 yarn build:production >/dev/null 2>&1
  fix_permissions_and_cache
  echo -e "${CG}[✓] Tema berhasil dikembalikan ke default!${R}"

# 5. SMART UNINSTALLER (Sistem Selektif)
elif [[ "$OPTION" == "5" ]]; then
  echo -e "\n${CY}--- SMART UNINSTALLER ---${R}"
  echo -e "Pilih komponen yang ingin dihapus (Ketik y untuk hapus, n untuk lewati)."
  
  read -p "1. Hapus File Panel Pterodactyl? (y/n): " DEL_PANEL
  read -p "2. Hapus Daemon Wings? (y/n): " DEL_WINGS
  read -p "3. Hapus Konfigurasi Webserver (Nginx & SSL)? (y/n): " DEL_WEB
  
  echo -e "\n${CY}[*] DAFTAR DATABASE DI SERVER:${R}"
  # Ambil daftar DB kecuali DB bawaan sistem
  DB_LIST=$(mysql -e "SHOW DATABASES;" | awk 'NR>1 {print $1}' | grep -Ev "^(information_schema|performance_schema|mysql|sys|phpmyadmin)$")
  
  if [ -z "$DB_LIST" ]; then
    echo -e "${CC}(Tidak ada database panel/kustom yang ditemukan)${R}"
    DEL_DB=""
  else
    echo -e "${CC}$DB_LIST${R}"
    echo -e "------------------------------------"
    read -p "4. Ketik NAMA DATABASE yang ingin dihapus (Kosongkan lalu Enter jika tidak ada): " DEL_DB
  fi
  
  echo -e "\n${CR}--- KONFIRMASI PENGHAPUSAN ---${R}"
  [[ "$DEL_PANEL" == "y" || "$DEL_PANEL" == "Y" ]] && echo "- Hapus File Panel Pterodactyl"
  [[ "$DEL_WINGS" == "y" || "$DEL_WINGS" == "Y" ]] && echo "- Hapus Daemon Wings"
  [[ "$DEL_WEB" == "y" || "$DEL_WEB" == "Y" ]] && echo "- Hapus Konfigurasi Nginx & SSL"
  [[ -n "$DEL_DB" ]] && echo "- Hapus Database MySQL: $DEL_DB"
  
  read -p "Apakah Anda YAKIN ingin mengeksekusi penghapusan di atas? (y/n): " CONFIRM_ALL
  
  if [[ "$CONFIRM_ALL" == "y" || "$CONFIRM_ALL" == "Y" ]]; then
     
     if [[ "$DEL_PANEL" == "y" || "$DEL_PANEL" == "Y" ]]; then
        echo -e "${CY}[*] Menghapus File Panel...${R}"
        systemctl stop pteroq 2>/dev/null || true
        rm -rf /var/www/pterodactyl /var/www/athemes
     fi
     
     if [[ "$DEL_WINGS" == "y" || "$DEL_WINGS" == "Y" ]]; then
        echo -e "${CY}[*] Menghapus Wings...${R}"
        systemctl stop wings 2>/dev/null || true
        systemctl disable wings 2>/dev/null || true
        rm -rf /etc/pterodactyl /var/lib/pterodactyl /usr/local/bin/wings
        rm -f /etc/systemd/system/wings.service
     fi
     
     if [[ "$DEL_WEB" == "y" || "$DEL_WEB" == "Y" ]]; then
        echo -e "${CY}[*] Menghapus Konfigurasi Nginx...${R}"
        rm -f /etc/nginx/sites-available/pterodactyl.conf
        rm -f /etc/nginx/sites-enabled/pterodactyl.conf
     fi
     
     if [ -n "$DEL_DB" ]; then
        if echo "$DB_LIST" | grep -wq "^${DEL_DB}$"; then
           echo -e "${CY}[*] Menghapus Database '${DEL_DB}'...${R}"
           mysql -e "DROP DATABASE \`${DEL_DB}\`;"
        else
           echo -e "${CR}[!] Error: Database '${DEL_DB}' tidak ditemukan, penghapusan DB dibatalkan.${R}"
        fi
     fi
     
     systemctl daemon-reload
     systemctl restart nginx 2>/dev/null || true
     echo -e "${CG}[✓] Proses Smart Uninstall Selesai!${R}"
  else
     echo -e "${CC}[*] Proses uninstall dibatalkan. Tidak ada yang dihapus.${R}"
  fi
fi
