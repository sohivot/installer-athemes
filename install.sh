echo -e "${CY}======================================${R}"
echo -e "${CG}     INSTALLER PTERODACTYL aTHEMES    ${R}"
echo -e "${CY}======================================${R}"
echo -e " [1] Install Panel aThemes (Full Auto-Setup)"
echo -e " [2] Reset Database Panel"
echo -e " [3] Update / Rebuild Tema UI"
echo -e " [4] Install / Update Wings"
echo -e " [5] Hapus Kredensial (db.txt)"
echo -e " [6] Pasang Addon Kustom (.zip)"
echo -e "${CC} [7] Pasang/Update Default Eggs Pterodactyl${R}"
echo -e "${CY}======================================${R}"
read -p " Pilih Opsi [1-7]: " PILIHAN

# --- MENGHUBUNGKAN KE MESIN CORE.SH ---
echo -e "\n[*] Memuat modul inti (core.sh)..."
curl -sLo /tmp/core.sh https://raw.githubusercontent.com/sohivot/installer-athemes/main/core.sh

# Menjalankan core.sh dengan membawa nomor pilihan
bash /tmp/core.sh $PILIHAN
