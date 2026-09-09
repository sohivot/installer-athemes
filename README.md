# 🚀 aThemes Master Installer v3.0

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0_Modular-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Platform-Pterodactyl-informational?style=for-the-badge">
  <img src="https://img.shields.io/badge/Auto-Nginx_%26_SSL-success?style=for-the-badge&logo=letsencrypt">
</p>

<p align="center">
  <strong>🖥️ SUPPORTED OS:</strong><br>
  <img src="https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white">
  <img src="https://img.shields.io/badge/Debian-A81D33?style=flat-square&logo=debian&logoColor=white">
  <img src="https://img.shields.io/badge/CentOS-262577?style=flat-square&logo=centos&logoColor=white">
  <img src="https://img.shields.io/badge/AlmaLinux-1046A0?style=flat-square&logo=almalinux&logoColor=white">
  <img src="https://img.shields.io/badge/Rocky_Linux-10B981?style=flat-square&logo=rockylinux&logoColor=white">
</p>

---

Auto-installer **Tema aThemes** untuk Pterodactyl. Nggak perlu ngetik kode panjang-panjang, jalankan 1 perintah dan biarkan sistem yang bekerja!

## 🌟 Fitur Unggulan
* 🐧 **Multi-OS Support:** Bebas pakai Ubuntu, Debian, atau CentOS/Alma.
* 🔒 **Auto Nginx & SSL:** Otomatis buatin web server dan pasang Gembok Hijau (Certbot).
* 🧩 **Smart Addon:** Mau tambah Addon (kayak Trash Bin)? Masukin link `.zip`-nya, sistem yang gabungin!
* 💾 **Auto-Save Data:** Password kesimpan aman. Update tema nggak usah ngetik ulang.
* ♻️ **Revert (Balik Perawan):** Bosen? Ada opsi khusus buat **Hapus Tema & Balik ke Original Pterodactyl**!
* 🧹 **Wipe Out:** Opsi hapus bersih panel & wings sampai ke akar-akarnya.

---

## ⚙️ Cara Install (1 Baris)

Login ke VPS sebagai `root`, *copy-paste* perintah ini di terminal, lalu tekan Enter:

```bash
bash <(curl -sL https://install.rensth.biz.id)
```

---

## 🧩 Cara Kerja Installer
*(Otomatis download modul sesuai pilihanmu agar script super ringan)*

```mermaid
graph TD
    A([Jalankan Script]) --> B{Menu Utama}
    B -->|Install/Update| C(Proses Core)
    B -->|Opsi Hapus| D(Proses Uninstall)
    
    C --> F{Deteksi OS}
    F -->|Ubuntu/Debian| G(Pakai APT)
    F -->|CentOS/Alma| H(Pakai YUM)
    
    G & H --> I[Install Server & Database]
    I --> J[Tarik Tema dari GitHub]
    J --> K[Opsi: Tambah Addon .zip]
    K --> L[Kompilasi UI & Setup Nginx+SSL]
    L --> M([Selesai!])
    
    D --> O{Menu Hapus}
    O --> P[Hapus Tema, Balik ke Ori]
    O --> Q[Hapus Bersih Panel/Wings]
```

---

## 🤝 Credits & Komunitas

* 🎨 **Desain Tema:** AlnoXD404 & Exeren
* 💻 **Sistem Installer:** Exeren

Proyek ini **100% Open Source**. Silakan dipakai, dimodifikasi, dan dipelajari.

> 💬 **Ada error? Butuh bantuan? Atau mau mabar?**  
> **[👉 KLIK DI SINI UNTUK JOIN DISCORD KAMI 👈](https://discord.gg/4vv975YRKW)**
