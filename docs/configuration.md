# Configuration

Panduan kustomisasi lengkap untuk config Quickshell ini.

---

## Architecture & Services

### New Singleton Services (v2.0)

Config sudah di-refactor menjadi modular architecture dengan proper singleton services:

| Service | File | Fungsi |
|---|---|---|
| `ShellState` | `services/ShellState.qml` | Global state management (panels, DND, etc) |
| `VolumeControl` | `services/VolumeControl.qml` | Audio volume control dengan debouncing |
| `BrightnessControl` | `services/BrightnessControl.qml` | Brightness control dengan debouncing |
| `BluetoothDevicePromotion` | `services/BluetoothDevicePromotion.qml` | Auto-promote BT sink as default |
| `GlobalShortcuts` | `shell/GlobalShortcuts.qml` | All keybinding definitions |
| `ProcessManager` | `shell/ProcessManager.qml` | Background processes: cava, screenshots, btagent |

**Benefit:**
- ✅ Cleaner `shell.qml` (600+ → ~120 lines)
- ✅ Better error handling & logging
- ✅ Easier to debug & maintain
- ✅ Proper separation of concerns
- ✅ Type-safe singleton access

### Accessing Services

```qml
// Access global state
ShellState.dashboardOpen = true
ShellState.togglePanel("calendar")
ShellState.closeAllPanels()

// Access services (already injected)
VolumeControl.volumeUp()
BrightnessControl.brightnessDown()

// Debug info
console.log(VolumeControl.getDebugInfo())
console.log(BrightnessControl.getDebugInfo())
```

Tema diatur oleh singleton `services/Colors.qml`. Ada 4 flavor Catppuccin:

| Nilai `currentTheme` | Label | Jenis |
|---|---|---|
| `catppuccin-latte` | Latte | Light |
| `catppuccin-frappe` | Frappé | Dark (medium) |
| `catppuccin-macchiato` | Macchiato | Dark |
| `catppuccin-mocha` | Mocha | Dark (default) |

### Ganti tema secara live

Dari dashboard → tab Settings → klik salah satu flavor. Tema langsung berubah tanpa restart.

### Ganti tema default

Edit `services/Colors.qml`, ubah nilai `currentTheme`:

```qml
property string currentTheme: "catppuccin-macchiato"
```

### Sinkronisasi tema ke app lain

Jika `matugen` terinstall, setiap ganti tema akan otomatis:
- Generate palette Material You dari base color flavor yang dipilih
- Apply ke GTK 3/4, foot terminal, btop, Hyprland border
- Toggle dark/light mode via `gsettings`

Konfigurasi `matugen` ada di `~/.config/matugen/config.toml`.

---

## Wallpaper

### `wallpaper.json`

File konfigurasi utama wallpaper di `~/.config/quickshell/wallpaper.json`:

```json
{
  "wallpaper_dir": "/home/user/Pictures/Wallpapers",
  "transition_type": "wipe",
  "transition_duration": 1.0,
  "transition_fps": 60,
  "thumb_size": 220,
  "columns": 4,
  "slideshow_enabled": false,
  "slideshow_interval_minutes": 5
}
```

| Field | Tipe | Default | Keterangan |
|---|---|---|---|
| `wallpaper_dir` | string | `~/Pictures/Wallpapers` | Folder yang di-scan untuk daftar wallpaper |
| `transition_type` | string | `"wipe"` | Jenis transisi `swww` (lihat di bawah) |
| `transition_duration` | float | `1.0` | Durasi transisi dalam detik (0.1–5.0) |
| `transition_fps` | int | `60` | FPS transisi (24–144) |
| `thumb_size` | int | `220` | Target lebar thumbnail di grid (px) |
| `columns` | int | `4` | Kolom grid (saat ini adaptif otomatis, field ini diabaikan) |
| `slideshow_enabled` | bool | `false` | Aktifkan slideshow otomatis |
| `slideshow_interval_minutes` | int | `5` | Interval slideshow dalam menit |

### Jenis transisi `swww`

| Nilai | Efek |
|---|---|
| `simple` | Ganti instan tanpa transisi |
| `fade` | Fade in/out |
| `wipe` | Wipe dari kiri ke kanan |
| `wave` | Gelombang |
| `grow` | Grow dari tengah |
| `center` | Expand dari tengah |
| `outer` | Expand dari luar ke dalam |
| `random` | Pilih transisi acak tiap ganti wallpaper |

### Set wallpaper via IPC

```bash
# Wallpaper acak
quickshell ipc call wallpaper random

# Buka panel untuk pilih manual
quickshell ipc call wallpaper toggle
```

### Cache wallpaper aktif

Path wallpaper yang sedang aktif disimpan ke:
- `~/.cache/wallpaper/current` — path teks plain
- `~/.cache/wallpaper/hyprlock-bg` — symlink ke file wallpaper (untuk hyprlock background)

---

## App Launcher

Default launcher adalah `walker`. Untuk ganti ke `fuzzel`, `rofi`, atau lainnya, edit `bar/widgets/MenuButton.qml`:

```qml
// Cari baris ini
Process { command: ["walker"] }

// Ganti dengan launcher pilihan
Process { command: ["fuzzel"] }
Process { command: ["rofi", "-show", "drun"] }
```

---

## Screenshot

Output folder default: `~/Pictures/Screenshots/`  
Format nama file: `screenshot-YYYYMMDD-HHMMSS.png`

Untuk mengubah folder, edit `bar/Bar.qml` — cari `screenshotProc` dan `grimProc`:

```qml
Process {
    id: screenshotProc
    command: ["sh", "-c",
        "DIR=~/Pictures/Screenshots; " +   // <-- ubah di sini
        ...
    ]
}
```

---

## Recording

Output folder default: `~/Videos/Recordings/`  
Format nama file: `YYYYMMDD_HHMMSS.mp4`

Untuk mengubah folder, edit `scripts/record.sh`:

```bash
OUTDIR="$HOME/Videos/Recordings"   # <-- ubah di sini
```

Codec default: `h264`. Untuk ganti ke `vp9` atau `hevc`:

```bash
setsid -f wf-recorder \
    --audio-backend=pipewire \
    -a "$DESKTOP_MONITOR" \
    -c vp9 \                        # <-- ubah codec di sini
    -f "$OUTFILE" ...
```

---

## Battery Notification

Edit threshold di `bar/widgets/Battery.qml`:

```qml
// Warning low battery
readonly property int warnLevel: 30     // <-- ubah threshold

// Almost full (saat charging)
readonly property int fullLevel: 90     // <-- ubah threshold
```

---

## Foto Profil

Foto profil diambil dari `~/.face`. Bisa berupa file gambar apa saja (PNG, JPG, WebP).

Cara ganti:
1. Dari dashboard → klik foto profil → pilih file via dialog
2. Atau langsung copy file ke `~/.face`:
   ```bash
   cp ~/foto.png ~/.face
   ```

---

## Lock Screen

Username yang ditampilkan di lock screen di-hardcode di `lockscreen/LockScreen.qml`:

```qml
Text {
    text: "xans"    // <-- ubah ke username kamu
}
```

Path foto profil di lock screen juga perlu disesuaikan jika username beda:

```qml
source: "file:///home/xans/.face"   // <-- ubah username
```

PAM config default menggunakan `system-auth`. Jika sistem kamu menggunakan config PAM berbeda, ubah:

```qml
PamContext {
    config: "system-auth"   // <-- sesuaikan dengan sistem
}
```

---

## Bluetooth Agent

`scripts/btagent.sh` berjalan di background untuk auto-accept Bluetooth pairing. Jika tidak diinginkan, comment out di `shell.qml`:

```qml
// Process {
//     id: btAgent
//     command: ["bash", "scripts/btagent.sh"]
//     running: true
// }
```

---

## Cava Visualizer

### Auto-Start (v2.0) ⭐

**Cava feed sekarang auto-start saat Quickshell berjalan!** Tidak perlu lagi setup manual di `hyprland.conf`.

**Before (v1.0):**
```bash
# hyprland.conf - perlu disetup manual
exec-once = bash ~/.config/quickshell/dashboard/cava_feed.sh
```

**After (v2.0):**
```bash
# ProcessManager otomatis menjalankan:
[CavaFeed] Started successfully
```

### How It Works

1. `shell/ProcessManager.qml` auto-start `cavaFeed` process saat Quickshell launch
2. Script `dashboard/cava_feed.sh` menjalankan `cava` dengan output ke `/tmp/qs-cava.out`
3. `CavaService.qml` membaca data dari named pipe tersebut
4. `CavaRingDank.qml` (di media card) menampilkan visualisasi

### Proses Restart

Jika `cava` crash, ProcessManager otomatis restart dengan logic:

```
Max Retries: 3
Retry Interval: 2 detik
```

Logging:
```
[CavaFeed] Started successfully
[CavaFeed] Process stopped (exit code: 1), will restart in 2 seconds
[CavaFeed] Attempting restart (1/3)...
[CavaFeed] Started successfully
```

### Troubleshooting

Jika visualizer tidak muncul:

1. **Check cava terinstall:**
   ```bash
   which cava
   cava --help
   ```

2. **Check audio backend:**
   ```bash
   # PipeWire (modern)
   pactl info | grep -i pipewire
   
   # PulseAudio (lama)
   pactl info | grep -i pulseaudio
   ```

3. **Check named pipe:**
   ```bash
   # Terminal 1: watch data flow
   tail -f /tmp/qs-cava.out
   
   # Terminal 2: play audio
   ```

4. **Check permissions:**
   ```bash
   ls -la /tmp/qs-cava*
   ```

5. **Manual test:**
   ```bash
   bash ~/.config/quickshell/dashboard/cava_feed.sh
   # Harus menampilkan data saat audio playing
   ```

### Configuration

Config cava dibuat otomatis oleh script. Untuk custom config, buat `~/.config/cava/config`:

```ini
[general]
bars = 64
framerate = 60
sensitivity = 100

[input]
method = pipewire  # atau "pulse"

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 255
```

Setelah ubah config, restart Quickshell untuk reload.

### Disabling Cava (Optional)

Jika tidak ingin cava berjalan:

1. **Comment di ProcessManager (temporary)**:
   ```qml
   // Process {
   //     id: cavaFeed
   //     ...
   // }
   ```

2. **Remove from qmldir (permanent)** — tidak recommended

---

## Visualizer panel kanan dashboard menampilkan sparkline chart untuk CPU, GPU, RAM, dan Disk. Grafik ini otomatis menyesuaikan skala berdasarkan data yang ada.

### Mengubah jumlah data points

Edit `dashboard/SystemInfo.qml`:

```qml
property int maxHistoryPoints: 30   // <-- ubah jumlah data points (default 30)
```

### Mengubah update interval

```qml
Timer {
    interval: 1000   // <-- ubah interval dalam ms (default 1000 = 1 detik)
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
        cpuStatProc.running  = true
        gpuTempProc.running  = true
        gpuUsageProc.running = true
        ramProc.running      = true
        diskProc.running     = true
    }
}
```

### Mengubah color threshold

Edit bagian `StatRow` di section `// ── Card Stats: CPU · GPU · RAM · Disk`:

```qml
StatRow {
    label: "CPU"; icon: "󰻠"
    tempColor: root.cpuTemp > 85 ? Root.Colors.red      // <-- ubah threshold suhu tinggi
              : root.cpuTemp > 70 ? Root.Colors.yellow  // <-- ubah threshold suhu sedang
              : Root.Colors.blue                        // <-- warna normal
    tempText: root.cpuTemp + "°C"
    pct: root.cpuUsage
    history: root.cpuHistory
}
```

### Mematikan auto-scaling

Jika ingin menggunakan fixed range 0-100% tanpa zoom, edit Canvas `onPaint` di component `StatRow`:

```qml
// Ganti section ini
let minVal = Math.min(...box.history)
let maxVal = Math.max(...box.history)
// ... kode auto-scaling

// Dengan ini
let minVal = 0
let maxVal = 100
```

### Hardware monitor path

Path sensor temperature dan GPU usage mungkin berbeda tergantung hardware. Untuk cek path yang benar:

```bash
# CPU temperature
ls /sys/class/hwmon/hwmon*/temp*_label
cat /sys/class/hwmon/hwmon*/temp*_input

# GPU temperature
cat /sys/class/drm/card*/device/hwmon/hwmon*/temp*_input

# GPU usage
cat /sys/class/drm/card*/device/gpu_busy_percent
```

Sesuaikan path di `dashboard/SystemInfo.qml`:

```qml
Process {
    id: cpuTempProc
    command: ["sh", "-c", "cat /sys/class/hwmon/hwmon5/temp1_input"]  // <-- sesuaikan
}

Process {
    id: gpuTempProc
    command: ["sh", "-c", "cat /sys/class/hwmon/hwmon4/temp1_input"]  // <-- sesuaikan
}
```

---

## Menambahkan Quick Toggle Baru

Edit `dashboard/QuickToggles.qml`, tambahkan `QuickToggle` baru:

```qml
QuickToggle {
    Layout.fillWidth: true
    label: "LABEL"
    icon: "󰀄"                // Nerd Font glyph
    dashboardRoot: quickTogglesRoot.dashboardRoot
    checkCommand: "pgrep -x namaproses > /dev/null && echo yes || echo no"
    checkMatch: "yes"
    onCommand:  "namaproses &"
    offCommand: "pkill -x namaproses"
    notifSummaryOn:  "Proses Aktif"
    notifSummaryOff: "Proses Nonaktif"
    notifBodyOn:  "Proses sedang berjalan."
    notifBodyOff: "Proses dihentikan."
}
```
