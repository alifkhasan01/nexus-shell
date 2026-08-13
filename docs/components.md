# Components

Dokumentasi semua komponen QML di config Quickshell ini.

---

## Architecture Overview

Config Quickshell menggunakan arsitektur modular dengan singleton services untuk state management:

```
shell.qml (ROOT)
├── Services (Singleton)
│   ├── ShellState         ← Global state management
│   ├── VolumeControl      ← Audio control with debouncing
│   ├── BrightnessControl  ← Brightness control with debouncing
│   ├── Colors             ← Theme palette (Catppuccin)
│   ├── CavaService        ← Audio visualizer data
│   ├── BrightnessService  ← Hardware brightness
│   └── ...others
├── Shell Components
│   ├── GlobalShortcuts    ← All keybinding definitions
│   └── ProcessManager     ← Background processes (screenshots, cava, btagent)
├── UI Components
│   ├── Bar (per monitor)
│   ├── Dashboard
│   ├── Panels
│   └── LockScreen
└── Supporting Services
    └── BluetoothDevicePromotion ← Auto-promote BT sink
```

---

## Entry Point

### `shell.qml`

Root dari seluruh shell (sekarang ~120 lines, jauh lebih clean). Bertanggung jawab untuk:

- Spawn `Bar` per monitor via `Variants { model: Quickshell.screens }`
- Inisialisasi services: ShellState, VolumeControl, BrightnessControl
- Setup GlobalShortcuts dan ProcessManager
- Render LockScreen dan NotificationPopup di level root
- Setup BluetoothDevicePromotion untuk auto-promote BT sinks

**Startup Logging:**
```
[Quickshell] Started successfully
[Quickshell] Screen count: 2
```

---

## Services (Singleton)

### `services/ShellState.qml` ⭐ NEW

Singleton service untuk state global shell. Sumber kebenaran untuk semua panel states.

**Properties:**

| Property | Tipe | Fungsi |
|---|---|---|
| `dashboardOpen` | `bool` | Buka/tutup dashboard |
| `powerMenuOpen` | `bool` | Buka/tutup power menu |
| `wallpaperPanelOpen` | `bool` | Buka/tutup wallpaper panel |
| `menuOpen` | `bool` | Buka/tutup menu panel |
| `calendarOpen` | `bool` | Buka/tutup calendar panel |
| `connectionOpen` | `bool` | Buka/tutup connection panel |
| `clipboardOpen` | `bool` | Buka/tutup clipboard panel |
| `dnd` | `bool` | Status Do Not Disturb |
| `wallpaperRandom` | `var` | Referensi ke WallpaperRandom instance |
| `lockFn` | `function` | Lock screen function |

**Methods:**
- `togglePanel(panelName: string)` — Toggle panel dengan nama
- `closeAllPanels()` — Close semua panels
- `log(message: string)` — Log dengan prefix [ShellState]

### `services/VolumeControl.qml` ⭐ ENHANCED

Service untuk kontrol volume dengan debouncing dan error handling.

**Properties:**
- `osdRef` — Injected OSD reference
- `updateCount` — Tracking jumlah update
- `errorCount` — Tracking jumlah error
- `lastError` — Last error message

**Methods:**
- `volumeUp()` → `boolean` — Naikkan volume 5%
- `volumeDown()` → `boolean` — Turunkan volume 5%
- `toggleMute()` → `boolean` — Toggle mute
- `getSinkInfo()` → `string` — Get current sink info
- `getDebugInfo()` → `object` — Get detailed debug info

**Features:**
- Auto-detect bluetooth device, prioritize jika aktif
- Debounce OSD updates (50ms) untuk performa
- Error handling dengan logging
- Track update count untuk debugging

### `services/BrightnessControl.qml` ⭐ ENHANCED

Service untuk kontrol brightness dengan debouncing dan error handling.

**Properties:**
- `osdRef` — Injected OSD reference
- `debounceInterval` — Debounce timer interval (100ms)
- `updateCount` — Tracking jumlah update
- `errorCount` — Tracking jumlah error
- `lastError` — Last error message

**Methods:**
- `brightnessUp()` → `boolean` — Naikkan brightness 5%
- `brightnessDown()` → `boolean` — Turunkan brightness 5%
- `getBrightnessInfo()` → `string` — Get current brightness %
- `getDebugInfo()` → `object` — Get detailed debug info

**Features:**
- Debounce OSD updates (100ms) untuk performa
- Error handling dengan logging
- Hardware check sebelum modify
- Track update count untuk debugging

### `services/Colors.qml`

Singleton palette warna. Supports 4 Catppuccin flavors.

| Property | Nilai tersedia |
|---|---|
| `currentTheme` | `"catppuccin-latte"` / `"catppuccin-frappe"` / `"catppuccin-macchiato"` / `"catppuccin-mocha"` |

Saat tema berubah, juga menjalankan `matugen` untuk sinkronisasi warna ke GTK, Hyprland, dll.

### `services/CavaService.qml`

Singleton yang membaca data dari named pipe `/tmp/qs-cava.out` (output dari `cava_feed.sh`).

Dipakai oleh `CavaRingDank.qml` untuk visualizer cincin di media card.

### `services/BluetoothDevicePromotion.qml` ⭐ NEW

Service untuk auto-promote bluetooth device sebagai default audio sink. Saat perangkat bluetooth connect, sink audionya otomatis menjadi default.

---

## Shell Components

### `shell/GlobalShortcuts.qml` ⭐ NEW

Centralized management untuk semua GlobalShortcut definitions. Sebelumnya tersebar di `shell.qml`, sekarang dikumpulkan di satu file untuk maintainability.

**Shortcuts yang didefine:**

| Name | Description |
|---|---|
| `dashboard` | Toggle dashboard panel |
| `powermenu` | Toggle power menu |
| `menu` | Toggle menu panel |
| `lock` | Lock screen |
| `wallpaper-toggle` | Toggle wallpaper panel |
| `wallpaper-random` | Set random wallpaper |
| `calendar` | Toggle calendar panel |
| `connection` | Toggle connection panel |
| `clipboard` | Toggle clipboard panel |
| `volume:up` | Raise volume by 5% |
| `volume:down` | Lower volume by 5% |
| `volume:mute` | Toggle mute |
| `brightness:up` | Raise brightness by 5% |
| `brightness:down` | Lower brightness by 5% |

### `shell/ProcessManager.qml` ⭐ ENHANCED

Manager untuk semua background processes dengan comprehensive error handling & logging.

**Managed Processes:**

1. **Screenshot Processes** (2):
   - `screenshotSelectProc` — grimblast area selection
   - `screenshotFullProc` — grimblast full screen
   - Features: Retry logic (max 3), stderr capture, notification

2. **BlueZ Agent**:
   - `btAgent` — Auto-answer bluetooth pairing
   - Features: Restart on crash, retry tracking, logging

3. **Cava Feed** ⭐:
   - `cavaFeed` — Audio visualizer feed
   - **BARU**: Auto-start saat Quickshell berjalan (tidak perlu dari hyprland config)
   - Features: Continuous feed, restart on crash

**Methods:**
- `takeScreenshotSelect()` — Trigger area screenshot
- `takeScreenshotFull()` — Trigger full screen screenshot
- `getProcessStatus()` → `string` — Get JSON of all process states

**Logging:**
```
[Screenshot:Select] Triggered from shortcut
[Screenshot:Select] Saved to: /home/user/Pictures/Screenshots/screenshot-20260810-143022.png
[CavaFeed] Started successfully
[BTAgent] Attempting restart (1/3)...
```

---

## Bar

### `bar/Bar.qml`

`PanelWindow` utama di atas setiap monitor (tidak ada perubahan signifikan dari architecture).

---

## Bar Widgets

### `bar/widgets/*`

Semua widgets sudah ada. Tidak ada perubahan major di task ini.

---

## Dashboard

### `dashboard/Dashboard.qml`

Dashboard panel (tidak ada perubahan dari refactor ini).

---

## Panels

### Semua panels di `panels/`

Tidak ada perubahan dari refactor architecture ini.

---

## Notifications

### Semua notifications di `notifications/`

Tidak ada perubahan dari refactor ini.

---

## Power Menu

### Semua power menu di `power/`

Tidak ada perubahan dari refactor ini.

---

## Lock Screen

### `lockscreen/LockScreen.qml`

Tidak ada perubahan dari refactor ini.

---

## Scripts

### `scripts/btagent.sh`

BlueZ agent yang menjawab otomatis prompt pair/confirm Bluetooth. Dijalankan di background via ProcessManager.

### `scripts/record.sh`

Toggle screen recording via `wf-recorder` (tidak berubah).

### `dashboard/cava_feed.sh` ⭐ AUTO-STARTED

**BARU**: Sekarang auto-start saat Quickshell berjalan! ✅

Sebelumnya perlu dijalankan secara manual dari Hyprland config. Sekarang ProcessManager menangani:

```bash
# Before: Harus setup di hyprland.conf
exec-once = bash ~/.config/quickshell/dashboard/cava_feed.sh

# After: Auto-run via ProcessManager
[CavaFeed] Started successfully
```

Script ini menjalankan `cava` dengan output ke `/tmp/qs-cava.out` yang dibaca `CavaService.qml`.

---

## Summary of Improvements

| Area | Before | After |
|---|---|---|
| `shell.qml` size | 600+ lines | ~120 lines |
| State management | Inline `QtObject` | Proper `ShellState` singleton |
| Volume control | Inline Item | Separate `VolumeControl` service |
| Brightness control | Inline QtObject | Separate `BrightnessControl` service |
| Shortcuts | Hardcoded in shell.qml | Centralized `GlobalShortcuts.qml` |
| Processes | Scattered in shell.qml | Centralized `ProcessManager.qml` |
| Error handling | Minimal | Comprehensive with logging |
| Debouncing | None | Added for volume & brightness |
| Logging | Basic | Detailed with prefixes |
| Cava feed | Manual start | Auto-start via ProcessManager |
| BT device promo | Inline logic | Separate service |

---

## Services (Singleton)

### `services/Colors.qml`

Singleton palette warna. Diakses dari semua komponen via `Root.Colors.*`.

Mendukung 4 flavor Catppuccin yang bisa diganti live:

| Property | Nilai tersedia |
|---|---|
| `currentTheme` | `"catppuccin-latte"` / `"catppuccin-frappe"` / `"catppuccin-macchiato"` / `"catppuccin-mocha"` |

Tema aktif disimpan ke `~/.config/quickshell/theme` dan di-load saat startup.

Saat tema berubah, `Colors.qml` juga menjalankan:
- `matugen color hex <seed> -m <mode>` — sinkronisasi warna ke GTK, foot, btop, Hyprland
- `gsettings set ... color-scheme` — toggle GTK dark/light mode
- `gsettings set ... gtk-theme` — set theme `adw-gtk3` / `adw-gtk3-dark`

**Warna yang diexpose:**

`base`, `mantle`, `surface0`, `surface1`, `surface2`, `text`, `subtext`, `blue`, `lavender`, `green`, `yellow`, `peach`, `red`, `mauve`

### `services/CavaService.qml`

Singleton yang membaca data dari named pipe output `cava_feed.sh`. Dipakai oleh `CavaRingDank.qml` untuk visualizer cincin di media card. Hanya aktif saat dashboard terbuka.

---

## Bar

### `bar/Bar.qml`

`PanelWindow` utama yang ditempatkan di atas setiap monitor. Berisi semua widget dan semua panel sebagai `LazyLoader`.

**Panel yang di-host di Bar:**

| Panel | LazyLoader aktif saat |
|---|---|
| `PowerMenu` | `powerMenuOpen` atau `powerCloseTimer` running |
| `Dashboard` | `dashboardOpen` atau `dashCloseTimer` running |
| `ConnectPanel` | `connectPanelOpen` atau `connectCloseTimer` running |
| `VolumePanel` | `volumePanelOpen` atau `volumeCloseTimer` running |
| `WallpaperPanel` | `wallpaperPanelOpen` atau `wallpaperCloseTimer` running |

**Proses yang dijalankan dari Bar:**

| Process ID | Fungsi |
|---|---|
| `screenshotProc` | `grimblast copysave area` — screenshot area pilihan |
| `grimProc` | `grimblast copysave screen` — screenshot layar penuh |
| `recorderProc` | `scripts/record.sh desktop-only` — record tanpa mic |
| `recorderMicProc` | `scripts/record.sh both` — record dengan mic |
| `facePickerProc` | `zenity --file-selection` — ganti foto profil |
| `controlCenterProcess` | `control-center` — buka GNOME Control Center |

Semua screenshot disimpan ke `~/Pictures/Screenshots/` dengan nama `screenshot-YYYYMMDD-HHMMSS.png`.
Semua recording disimpan ke `~/Videos/Recordings/` dengan nama `YYYYMMDD_HHMMSS.mp4`.

---

## Bar Widgets

### `Battery.qml`

Menampilkan ikon baterai + persentase. Menggunakan `Quickshell.Services.UPower`.

- Notif saat level ≤ 30% (warning)
- Notif saat level ≥ 90% dan sedang charging (hampir penuh)

### `BluetoothStatus.qml`

- Klik kiri → toggle Bluetooth on/off via `bluetoothctl power on/off`
- Klik kanan → buka ConnectPanel tab Bluetooth
- Menampilkan ikon berbeda saat BT off / on / ada perangkat terhubung

### `Brightness.qml`

- Scroll up/down → ubah brightness ±5% via `brightnessctl set +5%/-5%`
- Setiap perubahan trigger OSD brightness

### `Clock.qml`

- Menampilkan jam `HH:mm`
- Klik kiri → toggle dashboard
- Klik kanan → buka `control-center`

### `MenuButton.qml`

- Klik → launch app launcher (`walker`)
- Ganti ke launcher lain dengan ubah command di file ini

### `NetworkStatus.qml`

- Menampilkan ikon status koneksi + nama SSID aktif
- Klik kiri → toggle WiFi on/off via `nmcli radio wifi`
- Klik kanan → buka ConnectPanel tab Wi-Fi
- Auto-refresh status setiap beberapa detik

### `PowerButton.qml`

- Klik → toggle power menu
- Ikon berubah saat menu terbuka

### `Volume.qml`

- Menampilkan ikon + persentase volume default sink (Pipewire)
- Scroll up/down → ubah volume ±5%
- Klik kiri → toggle VolumePanel
- Klik kanan → mute/unmute
- Setiap perubahan trigger OSD volume

### `WallpaperRandom.qml`

Instance yang selalu hidup di background (`shell.qml`). Membaca daftar wallpaper dari `wallpaper.json`, memilih satu secara acak, dan menjalankan `swww img` dengan parameter transisi dari config.

Dipanggil dari:
- Klik kanan tombol wallpaper di Bar
- IPC: `quickshell ipc call wallpaper random`

### `Workspaces.qml`

Menampilkan indikator workspace Hyprland via `Quickshell.Hyprland`. Klik pada workspace → pindah ke workspace tersebut.

---

## Dashboard

### `dashboard/Dashboard.qml`

`PanelWindow` dropdown yang muncul di bawah bar. Terdiri dari tiga kolom:

| Kolom | Konten |
|---|---|
| Kiri | Foto profil, tanggal, jam, quick toggles, system stats, settings |
| Tengah | Media card (MPRIS) + visualizer cava |
| Kanan | System info dengan sparkline chart (CPU, GPU, RAM, Disk + temps) |

Signal yang dikirim ke Bar:

| Signal | Efek |
|---|---|
| `screenshotRequested` | Jalankan `screenshotProc` |
| `grimRequested` | Jalankan `grimProc` |
| `recorderToggleRequested` | Jalankan `recorderProc` |
| `recorderMicToggleRequested` | Jalankan `recorderMicProc` |
| `setFaceRequested` | Jalankan `facePickerProc` |
| `dndToggleRequested` | Toggle `shellState.dnd` |

### `dashboard/MediaCard.qml`

Menampilkan informasi track aktif via `Quickshell.Services.Mpris`:
- Cover art (128×128 sourceSize, 64×64 display)
- Judul, artis
- Tombol previous / play-pause / next

Otomatis detect player MPRIS pertama yang aktif.

### `dashboard/QuickToggles.qml`

Grid 3 kolom berisi tombol-tombol aksi cepat:

| Tombol | Klik Kiri | Klik Kanan |
|---|---|---|
| IDLE | Toggle `hypridle` on/off | — |
| SS SELECT | Screenshot area (grimblast) | — |
| SS FULL | Screenshot fullscreen (grimblast) | — |
| RECORD | Toggle `wf-recorder` (desktop audio) | Toggle dengan mic |
| DND | Toggle Do Not Disturb | — |
| NIGHT | Toggle `hyprsunset` | — |

Tombol RECORD menampilkan dot merah berkedip saat recording aktif, dan indikator mic di pojok kiri bawah.

### `dashboard/QuickToggle.qml`

Komponen pill toggle generik yang dipakai IDLE dan NIGHT. Fitur:
- `checkCommand` — shell command untuk cek state aktif/nonaktif
- `onCommand` / `offCommand` — command saat toggle
- Notifikasi otomatis via `notify-send` saat state berubah

### `dashboard/CavaRingDank.qml`

Visualizer audio berbentuk cincin yang mengelilingi cover art di media card. Membaca data dari `CavaService` (named pipe output `cava_feed.sh`). Hanya berjalan saat dashboard terbuka.

### `dashboard/SettingsTab.qml`

Tab settings di kolom kiri dashboard:
- Slider volume (Pipewire default sink)
- Slider brightness (brightnessctl)
- Theme selector (4 flavor Catppuccin)
- Tombol ganti foto profil

### `dashboard/ThemeSelector.qml`

4 pill tombol flavor Catppuccin. Klik → ubah `Colors.currentTheme` → seluruh shell re-render dengan palette baru.

### `dashboard/SystemInfo.qml` & `SystemStats.qml`

**SystemInfo.qml** (Panel kanan dashboard):
- Menampilkan statistik sistem real-time dengan **sparkline chart**
- Metrics: CPU, GPU, RAM, Disk dengan usage percentage dan temperature
- **Sparkline features:**
  - Line chart mini yang menunjukkan history hingga 30 data points
  - Auto-scaling berdasarkan min/max dari data (zoom in untuk perubahan kecil)
  - Area fill dengan transparansi untuk visualisasi lebih baik
  - Color coding dinamis: hijau/biru → kuning → merah sesuai threshold
  - Smooth animation saat data update
- Update interval: 1 detik
- Data dibaca via `Process` yang menjalankan shell commands:
  - CPU: `/proc/stat` untuk usage, `/sys/class/hwmon/hwmon5/temp1_input` untuk temperature
  - GPU: `/sys/class/drm/card*/device/gpu_busy_percent` untuk usage, `/sys/class/hwmon/hwmon4/temp1_input` untuk temperature
  - RAM: `free -b` untuk memory usage
  - Disk: `df /` untuk disk usage

**SystemStats.qml** (Bar di dashboard):
- Versi ringkas tanpa grafik, hanya menampilkan angka usage
- RAM, Disk, dan Uptime

---

## Panels

### `panels/ConnectPanel.qml`

Panel dua tab: **Wi-Fi** dan **Bluetooth**.

- Tab Wi-Fi: daftar SSID dari `nmcli`, klik untuk connect/disconnect
- Tab Bluetooth: daftar perangkat dari `bluetoothctl`, klik untuk pair/connect/disconnect

### `panels/VolumePanel.qml`

Mixer volume per-aplikasi menggunakan `Quickshell.Services.Pipewire`:
- Slider untuk setiap sink input (aplikasi yang sedang main audio)
- Selector output device (speaker, headphone, bluetooth)

### `panels/WallpaperPanel.qml`

Panel full-screen (centered overlay) untuk memilih wallpaper:

- **Grid thumbnail** — scan folder `wallpaper_dir` secara rekursif, format jpg/jpeg/png/webp/bmp
- **Preview kolom kanan** — hover thumbnail untuk preview, klik untuk set
- **Search** — filter nama file secara realtime
- **Settings collapsible** — folder, jenis transisi, durasi, FPS, slideshow
- **Slideshow** — ganti wallpaper otomatis tiap N menit

Set wallpaper menggunakan `swww img` dengan parameter transisi dari config. Path wallpaper aktif disimpan ke `~/.cache/wallpaper/current`. Symlink `~/.cache/wallpaper/hyprlock-bg` dibuat untuk dipakai sebagai background hyprlock.

### `panels/WallpaperButton.qml`

Tombol kecil di bar untuk membuka/menutup WallpaperPanel. Klik kanan langsung memilih wallpaper acak.

---

## Notifications

### `notifications/NotificationPopup.qml`

Popup notifikasi menggunakan `Quickshell.Services.Notifications` (NotificationServer). Muncul di pojok kanan atas, auto-dismiss setelah timeout.

Saat `dnd = true`, notifikasi tidak ditampilkan (tapi tetap diterima server).

### `notifications/Osd.qml`

OSD (On-Screen Display) untuk volume dan brightness. Muncul di tengah bawah layar, auto-hide setelah beberapa detik. Dipanggil dari widget `Volume` dan `Brightness`.

---

## Power Menu

### `power/PowerMenu.qml`

`PanelWindow` overlay yang muncul di pojok kanan atas. Navigasi keyboard: `↑`/`↓` untuk pilih item, `Enter` untuk eksekusi, `Escape` untuk tutup.

### `power/PowerMenuItem.qml`

Komponen item generik dalam power menu. Tiap item punya:
- `icon` — Nerd Font glyph
- `label` — teks label
- `command` — array command yang dijalankan saat diklik/dienter
- `notifyTitle` / `notifyBody` — notifikasi sebelum eksekusi

---

## Lock Screen

### `lockscreen/LockScreen.qml`

Lock screen via `WlSessionLock` (protokol `ext_session_lock_v1`). Menutup semua monitor sekaligus.

**Visual:**
- Background: blur screencopy layar aktif via `ScreencopyView` + `MultiEffect`
- Overlay gelap semi-transparan
- Jam dua warna besar (lavender : text : blue)
- Tanggal
- Foto profil bulat dari `~/.face` (dengan mask MultiEffect)
- Username
- Input pill password dengan PS-button icons (○×△□) per karakter
- Animasi shake saat password salah

**Autentikasi:**
- Menggunakan `Quickshell.Services.Pam` dengan config `system-auth`
- Ikon kunci berputar saat sedang checking
- Pesan error muncul 3 detik lalu hilang

**Trigger:**
```bash
quickshell ipc call lockscreen lock
```

---

## Scripts

### `scripts/btagent.sh`

BlueZ agent yang menjawab otomatis prompt pair/confirm Bluetooth. Dijalankan di background saat startup, restart otomatis dengan jeda 5 detik jika crash.

### `scripts/record.sh`

Toggle screen recording via `wf-recorder`:

```
record.sh [desktop-only|both]
```

- `desktop-only` (default) — rekam audio dari `<default-sink>.monitor`
- `both` — buat PulseAudio null-sink, loopback desktop + mic ke null-sink, rekam null-sink

Jika `wf-recorder` sudah berjalan → stop dan cleanup modul PulseAudio yang dibuat.

Output: `~/Videos/Recordings/YYYYMMDD_HHMMSS.mp4`

### `scripts/screenshot.sh`

Helper screenshot (dipanggil secara opsional). Screenshot utama dijalankan langsung dari `Bar.qml` via `grimblast`.

### `dashboard/cava_feed.sh`

Menjalankan `cava` dengan output ke named pipe yang dibaca `CavaService.qml`. Hanya aktif saat dashboard terbuka (`shell.qml` mengontrol proses ini).
