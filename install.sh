#!/bin/bash
# not rebranding and not re-upload tanpa seizin pemilik!!

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
echo -e " ${CR}[7]${R} Menu Uninstall & Ganti Tema (Revert ke Original)"
echo -e " ${CB}[8]${R} Credits & Komunitas Discord (Informasi Sistem)"
echo -e " ${CR}[0]${R} Keluar dari Installer"
echo -e "${CB}==================================================${R}"
read -p "Silakan pilih opsi [0-8]: " OPTION

case $OPTION in
  1|2|3|4|5|6)
    echo -e "\n${CY}[*] Mengunduh modul instalasi dari GitHub...${R}"
    # Menggunakan metode temp file agar fungsi input (read) di dalam modul tidak terganggu
    curl -sL "$REPO_URL/core.sh" -o /tmp/core.sh
    bash /tmp/core.sh "$OPTION"
    rm -f /tmp/core.sh
    ;;
  7)
    echo -e "\n${CY}[*] Mengunduh modul Uninstaller...${R}"
    # Menggunakan metode temp file agar fungsi input (read) di dalam modul tidak terganggu
    curl -sL "$REPO_URL/uninstall.sh" -o /tmp/uninstall.sh
    bash /tmp/uninstall.sh
    rm -f /tmp/uninstall.sh
    ;;
  8)
    clear
    echo -e "${CB}==================================================${R}"
    echo -e "${CC}               CREDITS & INFORMASI                ${R}"
    echo -e "${CB}==================================================${R}"
    echo -e " ${CY}Tema Kustom (aThemes):${R} Dikembangkan oleh ${CG}AlnoXD404${R} & ${CG}Exeren${R}"
    echo -e " ${CY}Sistem Installer:${R} Dirancang & Dikembangkan oleh ${CG}Exeren${R}"
    echo -e "\n ${CC}Proyek ini bersifat 100% Open Source.${R}"
    echo -e " Kami percaya pada kebebasan berbagi dan berkolaborasi."
    echo -e " Anda bebas memodifikasi, menggunakan, dan mempelajari kode ini."
    echo -e "\n ${CB}[ Komunitas & Bantuan ]${R}"
    echo -e " Punya pertanyaan, kendala, atau ingin ikut mabar (main bareng)?"
    echo -e " Bergabunglah dengan server Discord kami!"
    echo -e " ${CY}➔ Link Discord:${R} ${CG}https://discord.gg/LINK_DISCORD_KAMU_DISINI${R}"
    echo -e "${CB}==================================================${R}"
    read -p "Tekan [Enter] untuk kembali ke menu utama..." < /dev/tty
    bash "$0"
    ;;
  0)
    echo -e "${CG}Terima kasih telah menggunakan layanan kami.${R}"
    exit 0
    ;;
  *)
    echo -e "${CR}[-] Pilihan tidak valid, silakan coba lagi.${R}"
    sleep 1
    bash "$0"
    ;;
esac
