#!/bin/bash
# =======================================================
# PTERODACTYL aTHEMES MASTER INSTALLER (v3.0 MODULAR)
# Cross-Platform & Modular Engine
# =======================================================

set -e
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Error: Silakan jalankan skrip ini menggunakan akses Root (sudo)!\e[0m"
  exit 1
fi

CG="\e[32m"; CR="\e[31m"; CY="\e[33m"; CB="\e[34m"; CC="\e[36m"; R="\e[0m"

# Pastikan URL ini mengarah ke repositori GitHub Anda
REPO_URL="https://raw.githubusercontent.com/sohivot/installer-athemes/main"

clear
echo -e "${CB}==================================================${R}"
echo -e "${CG}     aTHEMES INSTALLER V3.0 (MODULAR ENGINE)      ${R}"
echo -e "${CB}==================================================${R}"
echo -e " ${CY}[1]${R} Install Full aThemes (Panel, Nginx, SSL, Database)"
echo -e " ${CY}[2]${R} Reset Database (Clean Install)"
echo -e " ${CY}[3]${R} Update Tema aThemes & Rebuild UI"
echo -e " ${CY}[4]${R} Update Wings Daemon ke Versi Terbaru"
echo -e " ${CY}[5]${R} Hapus Cache Konfigurasi (Reset db.txt)"
echo -e " ${CC}[6]${R} Pasang Addon Kustom (Membutuhkan URL/Path .zip)"
echo -e " ${CR}[8]${R} Menu Uninstall & Ganti Tema (Revert ke Original)"
echo -e " ${CR}[0]${R} Keluar dari Installer"
echo -e "${CB}==================================================${R}"
read -p "Silakan pilih opsi [0-8]: " OPTION

case $OPTION in
  1|2|3|4|5|6)
    echo -e "\n${CY}[*] Mengunduh modul instalasi dari GitHub...${R}"
    curl -sL "$REPO_URL/core.sh" | bash -s -- "$OPTION"
    ;;
  8)
    echo -e "\n${CY}[*] Mengunduh modul Uninstaller...${R}"
    curl -sL "$REPO_URL/uninstall.sh" | bash
    ;;
  0)
    echo -e "${CG}Terima kasih telah menggunakan layanan kami.${R}"
    exit 0
    ;;
  *)
    echo -e "${CR}[-] Pilihan tidak valid, silakan coba lagi.${R}"
    ;;
esac
