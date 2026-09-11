#!/bin/bash
# ===================================================================
# PTERODACTYL & aTHEMES AUTO INSTALLER (MENU UTAMA)
# ===================================================================

G='\033[0;32m'
B='\033[0;36m'
Y='\033[1;33m'
N='\033[0m'

clear
echo -e "${B}==================================================================${N}"
echo -e "${G}      PTERODACTYL PANEL & aTHEMES INSTALLATION SCRIPT      ${N}"
echo -e "${B}==================================================================${N}"
echo -e " Script Otomatis by Exeren"
echo -e "${B}==================================================================${N}\n"

echo -e "${Y}--- MENU INSTALASI ---${N}"
echo -e "  ${G}[1]${N} Install Pterodactyl Panel (Original)"
echo -e "  ${G}[2]${N} Install Pterodactyl Panel + aThemes (Custom UI)"
echo -e "  ${G}[3]${N} Install Wings (Node/Daemon) Saja\n"

echo -e "${Y}--- MENU UNINSTALLER ---${N}"
echo -e "  ${G}[4]${N} Uninstall aThemes (Kembali ke Tampilan Original)"
echo -e "  ${G}[5]${N} Smart Uninstaller (Pilih sendiri apa yang mau dihapus!)\n"

echo -e "  ${G}[0]${N} Keluar\n"

read -p "Masukkan pilihan Anda [0-5]: " OPTION

if [[ "$OPTION" == "0" ]]; then
  echo -e "\nKeluar dari installer..."
  exit 0
fi

# ROUTER: Pisahkan eksekusi berdasarkan file
if [[ "$OPTION" == "1" || "$OPTION" == "2" || "$OPTION" == "3" ]]; then
  if [ -f "core.sh" ]; then
    bash core.sh "$OPTION"
  else
    curl -sL "https://install.rensth.biz.id/core.sh" -o /tmp/core.sh
    bash /tmp/core.sh "$OPTION"
  fi
elif [[ "$OPTION" == "4" || "$OPTION" == "5" ]]; then
  if [ -f "uninstall.sh" ]; then
    bash uninstall.sh "$OPTION"
  else
    curl -sL "https://install.rensth.biz.id/uninstall.sh" -o /tmp/uninstall.sh
    bash /tmp/uninstall.sh "$OPTION"
  fi
else
  echo -e "Pilihan tidak valid!"
fi
