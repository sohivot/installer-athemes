echo -e "${CY}======================================${R}"
echo -e "${CG}     INSTALLER PTERODACTYL aTHEMES    ${R}"
echo -e "${CY}======================================${R}"
echo -e " [1] Install Panel aThemes (Full Auto-Setup)"
echo -e " [2] Reset Database Panel"
echo -e " [3] Update / Rebuild Tema UI"
echo -e " [4] Install / Update Wings"
echo -e " [5] Hapus Kredensial (db.txt)"
echo -e " [6] Pasang Addon Kustom (.zip)"
echo -e " [7] Pasang/Update Default Eggs Pterodactyl"
echo -e "${CR} [8] Uninstall (Panel/Wings/Full)${R}"
echo -e "${CR} [0] Exit / Keluar Installer${R}"
echo -e "${CY}======================================${R}"
read -p " Pilih Opsi [0-8]: " PILIHAN

if [ "$PILIHAN" == "0" ]; then
  echo -e "\n${CG}[*] Terima kasih telah menggunakan installer ini! Keluar...${R}\n"
  exit 0
fi

echo -e "\n[*] Memuat modul inti (core.sh)..."
curl -sLo /tmp/core.sh https://raw.githubusercontent.com/sohivot/installer-athemes/main/core.sh
bash /tmp/core.sh $PILIHAN
