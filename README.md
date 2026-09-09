# 🚀 Pterodactyl aThemes Master Installer

![Version](https://img.shields.io/badge/version-1.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Pterodactyl-informational.svg)
![OS](https://img.shields.io/badge/os-Ubuntu%20%7C%20Debian-success.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-success.svg)

Master Installer super cepat, aman, dan stabil untuk memasang **Pterodactyl Panel, aThemes, Wings**, dan **Addon Kustom** secara bersamaan. Dikembangkan khusus untuk menghindari *Error 500* dan masalah *UI berantakan* yang sering disebabkan oleh modifikasi pihak ketiga (seperti Blueprint).

Dikembangkan oleh **Exeren** untuk komunitas server *hosting* dan *developer*.

---

## ✨ Fitur Unggulan

- 🛡️ **Pure Edition (100% Stabil):** Tidak mengubah file *core* Pterodactyl secara paksa. Dijamin bebas dari *Error 500/White Screen*.
- 🧩 **Smart Addon Engine:** Ingin pasang Trash Bin atau addon lain? Cukup masukkan URL/Link `.zip`-nya, dan sistem akan otomatis menyatukannya dengan tema tanpa merusak UI.
- 🧠 **Anti-Crash Memory System:** Otomatis mendeteksi RAM dan membuat Virtual RAM (Swap) 2GB agar proses `yarn build:production` tidak pernah gagal (*exit code 1*).
- 💾 **Auto-Database & Credentials Cache:** Konfigurasi MySQL otomatis. Data login tersimpan aman di `db.txt` agar instalasi ulang lebih cepat.
- 🧹 **Clean Uninstaller (Danger Zone):** Fitur untuk menghapus Pterodactyl, Wings, dan Database hingga bersih tanpa sisa jika ingin mereset server.

---

## 🖥️ Sistem Operasi yang Didukung (Supported OS)

Skrip ini dioptimalkan untuk sistem operasi berbasis `apt` (Debian/Ubuntu). Sangat disarankan untuk menjalankan skrip ini pada **OS Linux yang masih segar (Fresh Install)**.

| OS | Versi | Status |
| :--- | :--- | :--- |
| **Ubuntu** | 20.04, 22.04, 24.04 | ✅ Didukung Sepenuhnya |
| **Debian** | 11, 12, 13 | ✅ Didukung Sepenuhnya |

*⚠️ **Peringatan:** Skrip ini belum mendukung CentOS, AlmaLinux, atau Rocky Linux (keluarga RHEL).*

---

## ⚡ Cara Instalasi (Quick Start)

Login ke VPS Anda menggunakan akses **root** (via SSH), lalu jalankan satu baris perintah sakti berikut:

```bash
bash <(curl -sL https://install.rensth.biz.id/)
