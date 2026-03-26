# XScanner – Malware Scanner for Termux & Linux

XScanner adalah tools scanner malware yang dirancang untuk Termux (Android), Linux, WSL, dan macOS. Menggunakan database signature real-time dari GitHub untuk mendeteksi malware berdasarkan hash SHA256.

![XScanner Preview](https://i.ibb.co/VYRY463t/Screenshot-20260326-084813.png)

---

Fitur

- Signature real-time – Update database langsung dari GitHub
- Multi-platform – Android (Termux), Linux, WSL, macOS
- Fast scan – Scan cepat dengan limit 500 file
- Deep scan – Scan mendalam dengan limit 5000 file
- Database dari Windows, Android, dan Linux malware signature
- Report hasil scan dalam format log

Persyaratan

- Termux (Android) atau Linux (Ubuntu/Debian/Fedora/Arch)
- Koneksi internet untuk update signature pertama kali
- Ruang penyimpanan minimal 50 MB

Cara Install

Termux (Android)

pkg update && pkg upgrade
pkg install git curl
git clone https://github.com/hey-pro-108/Xscanner.git
cd Xscanner
chmod +x xscan.sh
./xscan.sh

Linux (Ubuntu/Debian)

sudo apt update
sudo apt install git curl
git clone https://github.com/hey-pro-108/Xscanner.git
cd Xscanner
chmod +x xscan.sh
./xscan.sh

Linux (Fedora)

sudo dnf install git curl
git clone https://github.com/hey-pro-108/Xscanner.git
cd Xscanner
chmod +x xscan.sh
./xscan.sh

WSL (Windows Subsystem for Linux)

sudo apt update
sudo apt install git curl
git clone https://github.com/hey-pro-108/Xscanner.git
cd Xscanner
chmod +x xscan.sh
./xscan.sh

Cara Penggunaan

Menu Interaktif

Jalankan tanpa parameter untuk masuk ke menu:

./xscan.sh

Menu yang tersedia:
1 - Fast Scan (scan cepat dengan limit 500 file)
2 - Deep Scan (scan mendalam dengan limit 5000 file)
3 - Update (update signature database dari GitHub)
4 - Exit (keluar dari program)

Command Line

Jalankan dengan parameter untuk penggunaan non-interaktif:

./xscan.sh -f /sdcard/Download    Fast scan pada folder tertentu
./xscan.sh -d /sdcard             Deep scan pada folder tertentu
./xscan.sh -u                     Update signature database
./xscan.sh -h                     Tampilkan bantuan

Contoh Penggunaan

./xscan.sh -f /sdcard/Download
./xscan.sh -d /storage/emulated/0
./xscan.sh -u

Database Signature

XScanner mengambil signature dari GitHub dengan limit sebagai berikut:

- Windows malware: 10.000 signature dari theZoo
- Android malware: 5.000 signature dari android-malware
- Linux malware: 3.000 signature dari signature-base
- Cobalt Strike: 1.000 signature dari CobaltStrikeParser

Database diupdate setiap kali menjalankan perintah update atau saat pertama kali scan.

Lokasi File

Semua file konfigurasi dan database disimpan di:

$HOME/xscanner/
  database/      Database signature malware
  reports/       Hasil scan dalam format log
  temp/          File temporary
  settings.conf  File konfigurasi

Hasil scan deep akan disimpan di folder reports dengan format deep_scan_20260326_120000.log

Troubleshooting

Permission denied saat menjalankan script

chmod +x xscan.sh
./xscan.sh

curl: command not found

pkg install curl        # Termux
sudo apt install curl   # Ubuntu/Debian
sudo dnf install curl   # Fedora

git: command not found

pkg install git         # Termux
sudo apt install git    # Ubuntu/Debian
sudo dnf install git    # Fedora

Database tidak terupdate

Jalankan update manual:

./xscan.sh -u

Pastikan koneksi internet aktif karena script mengambil signature dari GitHub.

Target path tidak ditemukan

Pastikan path yang dimasukkan benar. Contoh path yang valid:

/sdcard/Download
/sdcard/DCIM
/storage/emulated/0
/data/data/com.termux/files/home

Lisensi

MIT License – Developed by Hexa Dev
