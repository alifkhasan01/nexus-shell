# PWA/Web Apps Filter Guide

## Overview
Menu aplikasi sekarang mendukung filtering khusus untuk Progressive Web Apps (PWA) dan aplikasi web yang diinstall dari browser berbasis Chromium (Chrome, Brave, Edge, Vivaldi, Opera, dll).

## Fitur

### 1. Kategori "WebApps"
- Kategori baru yang menampilkan **hanya** aplikasi PWA/web apps
- Muncul di list kategori setelah "Utility"
- Ideal untuk mengakses aplikasi web seperti Discord, Spotify Web, WhatsApp Web, dll

### 2. Toggle Filter PWA
- **Lokasi**: Di header menu, sebelah kanan counter "X apps"
- **Icon**: 󰖟 (Web icon)
- **Warna**:
  - Hijau = PWA ditampilkan
  - Abu-abu = PWA disembunyikan
- **Hanya muncul** di kategori "All"
- Hover untuk tooltip info

### 3. Badge PWA
- Setiap aplikasi PWA ditandai dengan badge hijau bertulisan "PWA"
- Badge muncul di sebelah nama aplikasi
- Memudahkan identifikasi aplikasi web vs native

## Cara Kerja Deteksi PWA

Aplikasi terdeteksi sebagai PWA jika memenuhi salah satu kriteria:

### 1. Desktop ID mengandung prefix browser
   - `chrome-`, `chromium-`, `brave-`, `msedge-`, `vivaldi-`, `opera-`
   - Contoh: `brave-app_discord_com-Default.desktop`

### 2. Exec command menggunakan flag browser apps
   - `--app-id=`, `--app=`, atau `--profile-directory=`
   - Contoh: `/usr/bin/brave --app-id=abcdef123456`

### 3. Icon path menunjuk ke browser profile
   - Path mengandung nama browser + "Profile" atau "Default"
   - Contoh: `/home/user/.config/BraveSoftware/Brave-Browser/Default/Web Applications/`

## Browser yang Didukung

✓ **Google Chrome** / Chromium  
✓ **Brave Browser**  
✓ **Microsoft Edge**  
✓ **Vivaldi**  
✓ **Opera** / Opera GX  
✓ Browser berbasis Chromium lainnya

## Penggunaan

### Filter PWA dari kategori "All"
1. Buka menu aplikasi
2. Pastikan kategori "All" aktif
3. Klik toggle icon Web (󰖟) di header
4. PWA akan hilang/muncul sesuai toggle

### Lihat hanya PWA
1. Buka menu aplikasi
2. Pilih kategori "WebApps"
3. Hanya aplikasi PWA yang ditampilkan

### Keyboard Navigation
- Toggle PWA tidak bisa diakses via keyboard (hanya mouse)
- Kategori "WebApps" bisa diakses dengan Tab → Arrow keys

## Tips

- **Desktop Entries**: PWA biasanya berada di `~/.local/share/applications/`
- **Brave**: PWA dari Brave punya prefix `brave-` di desktop ID
- **Edge**: PWA dari Edge punya prefix `msedge-` di desktop ID
- **Multiple Profiles**: Jika browser punya multiple profiles, setiap PWA per profile akan muncul sebagai aplikasi terpisah
- **Uninstall PWA**: Hapus dari browser settings (Menu > Apps > Manage apps), file `.desktop` akan otomatis terhapus

## Contoh PWA Populer

- Discord Web App
- Spotify Web Player
- WhatsApp Web
- Notion
- Figma
- ChatGPT
- YouTube Music
- Google Drive/Docs/Sheets
- Slack Web

## Troubleshooting

### PWA tidak terdeteksi
- Pastikan PWA diinstall lewat browser Chromium (Menu > Install app / Apps)
- Cek apakah file `.desktop` ada di `~/.local/share/applications/`
- Restart quickshell untuk refresh DesktopEntries

### Aplikasi native salah terdeteksi sebagai PWA
- Fungsi `isWebApp()` di `MenuPanel.qml` bisa disesuaikan
- Edit kriteria deteksi jika ada false positive

### Toggle tidak muncul
- Toggle hanya muncul di kategori "All"
- Pindah ke kategori lain lalu kembali ke "All"

### Browser selain Chromium (Firefox, Safari)
- Firefox belum mendukung PWA dengan baik di Linux
- Deteksi saat ini fokus ke browser berbasis Chromium
- Bisa ditambahkan jika Firefox mulai support PWA

## Customization

Edit file: `panels/MenuPanel.qml`

### Ubah warna badge PWA
```qml
Rectangle {
    visible: modelData && menuModel.isWebApp(modelData)
    color: Root.Colors.green  // ← ubah warna di sini
    // ...
}
```

### Ubah teks badge
```qml
Text {
    text: "PWA"  // ← ubah teks di sini
    // ...
}
```

### Ubah kriteria deteksi
```qml
function isWebApp(app) {
    // Tambah browser lain di sini jika perlu
    // Contoh untuk browser custom:
    if (desktopId.includes("mybrowser-")) return true
    // ...
}
```

### Default toggle state
```qml
QtObject {
    id: navState
    property bool showWebApps: true  // ← false untuk hide by default
    // ...
}
```

## Icon Reference

- 󰣇 = Applications
- 󰖟 = Web Apps (PWA)
- 󰍉 = Search
- 󰅖 = Clear
- 󰅂 = Launch arrow

---

**Version**: 2.2  
**Date**: 2026-08-14  
**Author**: Quickshell PWA Enhancement  
**Supported Browsers**: Chrome, Chromium, Brave, Edge, Vivaldi, Opera, dan browser Chromium-based lainnya
