#!/bin/bash
# =======================================================
# MODUL UNINSTALLER & REVERT THEME
# =======================================================
CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CB="\e[34m"; CC="\e[36m"; R="\e[0m"
PANEL_DIR="/var/www/pterodactyl"

# OS Detection
. /etc/os-release
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  PKG_MGR="apt"; WEB_USER="www-data"
else
  PKG_MGR="yum"; WEB_USER="nginx"
fi

clear
echo -e "${CB}==================================================${R}"
echo -e "${CR}        MENU PENGHAPUSAN & PEMULIHAN SISTEM       ${R}"
echo -e "${CB}==================================================${R}"
echo -e " ${CY}[1]${R} Kembalikan ke Tema Pterodactyl Original (Hapus aThemes)"
echo -e " ${CR}[2]${R} Hapus Panel & Tema Saja (Data Nginx & DB dibersihkan)"
echo -e " ${CR}[3]${R} Hapus Wings / Daemon Saja"
echo -e " ${CR}[4]${R} Hapus Total (Panel, Wings, Database, Nginx, dan SSL)"
echo -e " ${CC}[0]${R} Batal dan Keluar"
echo -e "${CB}==================================================${R}"
read -p "Silakan pilih opsi penghapusan [0-4]: " UN_OPT

case $UN_OPT in
  1)
    echo -e "\n${CY}[*] Menghapus aThemes dan mengunduh Pterodactyl versi resmi...${R}"
    cd "$PANEL_DIR"
    
    # Membersihkan aset tema khusus
    echo -e "${CY}[*] Membersihkan aset tema lama...${R}"
    rm -rf resources/ public/assets/ /var/www/athemes
    
    # Mengunduh panel resmi
    echo -e "${CY}[*] Mengunduh arsip Pterodactyl resmi...${R}"
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    
    echo -e "${CY}[*] Menyesuaikan konfigurasi Composer...${R}"
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    chown -R $WEB_USER:$WEB_USER "$PANEL_DIR"
    echo -e "${CG}[✓] Berhasil! Tampilan panel telah kembali ke versi Pterodactyl original.${R}"
    ;;
    
  2)
    echo -e "\n${CR}[*] Memulai penghapusan Panel Pterodactyl dan konfigurasinya...${R}"
    rm -rf "$PANEL_DIR" /var/www/athemes
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/conf.d/pterodactyl.conf
    systemctl restart nginx 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS \`panel\`;" 2>/dev/null || true
    echo -e "${CG}[✓] Panel dan konfigurasinya berhasil dihapus dari server.${R}"
    ;;
    
  3)
    echo -e "\n${CR}[*] Menghentikan dan menghapus layanan Wings...${R}"
    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    rm -f /usr/local/bin/wings
    rm -rf /etc/pterodactyl
    echo -e "${CG}[✓] Layanan Wings telah berhasil dihapus.${R}"
    ;;
    
  4)
    echo -e "\n${CR}[*] PERINGATAN: Menghapus seluruh sistem Pterodactyl...${R}"
    
    # Hapus Wings
    systemctl stop wings 2>/dev/null || true
    rm -f /etc/systemd/system/wings.service && systemctl daemon-reload
    rm -f /usr/local/bin/wings /etc/pterodactyl -r
    
    # Hapus Panel & Nginx
    rm -rf "$PANEL_DIR" /var/www/athemes
    rm -f /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/conf.d/pterodactyl.conf
    systemctl restart nginx 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS \`panel\`;" 2>/dev/null || true
    
    # Hapus Certbot
    $PKG_MGR remove -y certbot python3-certbot-nginx 2>/dev/null || true
    echo -e "${CG}[✓] Selesai. Seluruh sistem Pterodactyl telah dibersihkan dari VPS ini.${R}"
    ;;
    
  0)
    exit 0
    ;;
  *)
    echo -e "${CR}[-] Pilihan tidak valid. Silakan coba lagi.${R}"
    ;;
esac
