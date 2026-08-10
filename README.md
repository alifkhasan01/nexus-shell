<iframe widht="560" height="315" src="https://youtu.be/NyO79qD3V_0?si=dUqW6U2ApIo5KxVF" frame="0" allowfullscreen></iframe>



# Quickshell Config

Shell desktop berbasis [Quickshell](https://quickshell.outfoxxed.me) untuk Hyprland.
Mencakup bar, dashboard, panel, notifikasi, OSD, lockscreen, dan power menu — semua dalam satu config QML.

## ✨ Fitur Unggulan

- **Sparkline System Monitor** — Real-time CPU, GPU, RAM, Disk usage dengan line chart mini dan auto-scaling
- **Live Theme Switching** — 4 flavor Catppuccin (Latte, Frappé, Macchiato, Mocha) bisa ganti tanpa restart
- **Smart Wallpaper Manager** — Grid thumbnail, preview, slideshow otomatis, transisi animasi via swww
- **Cava Audio Visualizer** — Cincin visualizer yang mengelilingi cover art media player
- **Quick Toggles** — Panel aksi cepat: screenshot, record, idle, DND, night light
- **Bluetooth Auto-Pairing** — Agent background yang auto-accept pairing request
- **PAM Lock Screen** — Autentikasi native dengan blur background dan animasi smooth

## Tampilan

- **Bar** — panel atas dengan workspace, clock, status network/bluetooth/volume/brightness/battery
- **Dashboard** — dropdown dari clock: media player, quick toggles, system stats, settings
- **System Info** — monitoring real-time CPU, GPU, RAM, Disk dengan sparkline chart dan auto-scaling
- **Panel Wi-Fi & Bluetooth** — panel popup dengan daftar jaringan & perangkat
- **Volume Panel** — mixer per-aplikasi + device selector
- **Wallpaper Panel** — grid thumbnail, preview, slideshow, transisi via `swww`
- **Power Menu** — shutdown, reboot, suspend, logout, lock
- **Notifikasi** — popup notifikasi native + OSD untuk volume & brightness
- **Lock Screen** — blur screencopy background, jam besar, input PAM
- **Tema** — 4 flavor Catppuccin (Latte, Frappé, Macchiato, Mocha), bisa ganti live dari dashboard

---

## Struktur

```
~/.config/quickshell/
├── shell.qml                    # Entry point — spawn Bar, LockScreen, NotificationPopup
├── qmldir                       # Registrasi singleton (Colors, CavaService)
├── theme                        # File teks: nama tema aktif saat ini
├── wallpaper.json               # Konfigurasi wallpaper (folder, transisi, slideshow)
│
├── services/
│   ├── Colors.qml               # Singleton palette Catppuccin (4 flavor)
│   └── CavaService.qml          # Singleton data visualizer cava
│
├── bar/
│   ├── Bar.qml                  # PanelWindow bar atas
│   └── widgets/
│       ├── Battery.qml          # Status baterai + notif 30% / 90%
│       ├── BluetoothStatus.qml  # Toggle BT (klik kiri) + buka panel (klik kanan)
│       ├── Brightness.qml       # Brightness via brightnessctl + OSD
│       ├── Clock.qml            # Jam — klik buka/tutup dashboard
│       ├── MenuButton.qml       # Tombol app launcher (walker/fuzzel)
│       ├── NetworkStatus.qml    # Toggle WiFi (klik kiri) + buka panel (klik kanan)
│       ├── PowerButton.qml      # Buka power menu
│       ├── Volume.qml           # Volume via Pipewire + OSD
│       ├── WallpaperRandom.qml  # Randomizer wallpaper (selalu aktif di background)
│       └── Workspaces.qml       # Indikator workspace Hyprland
│
├── dashboard/
│   ├── Dashboard.qml            # Panel dropdown dashboard
│   ├── CavaRingDank.qml         # Visualizer cava cincin di media card
│   ├── MediaCard.qml            # Media player via MPRIS
│   ├── QuickToggle.qml          # Komponen pill toggle generik (dengan notifikasi)
│   ├── QuickToggles.qml         # Grid toggle: idle, screenshot, recorder, DND, night
│   ├── SettingsTab.qml          # Tab settings (slider volume/brightness, theme)
│   ├── SliderRow.qml            # Komponen slider generik
│   ├── SystemInfo.qml           # Info sistem dengan sparkline chart (CPU, GPU, RAM, Disk)
│   ├── SystemStats.qml          # Bar stats ringkas di dashboard
│   ├── ThemeSelector.qml        # Selector 4 flavor Catppuccin
│   └── cava_feed.sh             # Script feed data cava ke named pipe
│
├── panels/
│   ├── ConnectPanel.qml         # Panel Wi-Fi + Bluetooth (dua tab)
│   ├── VolumePanel.qml          # Mixer volume per-aplikasi + device
│   ├── WallpaperButton.qml      # Tombol wallpaper di panel
│   └── WallpaperPanel.qml       # Panel pilih wallpaper (grid + preview + slideshow)
│
├── notifications/
│   ├── NotificationPopup.qml    # Popup notifikasi (NotificationServer Quickshell)
│   └── Osd.qml                  # OSD volume & brightness
│
├── power/
│   ├── PowerMenu.qml            # Menu power (shutdown/reboot/suspend/logout/lock)
│   └── PowerMenuItem.qml        # Item menu power
│
├── lockscreen/
│   └── LockScreen.qml           # Lock screen via PAM + blur screencopy
│
├── scripts/
│   ├── btagent.sh               # BlueZ agent — auto-accept pairing bluetooth
│   ├── record.sh                # Toggle recording via wf-recorder
│   └── screenshot.sh            # Helper screenshot
│
└── docs/
    ├── hyprland-integration.md  # Panduan keybinding & IPC Hyprland
    ├── components.md            # Dokumentasi semua komponen QML
    └── configuration.md        # Panduan kustomisasi & wallpaper.json
```

---

## Instalasi

```bash
git clone https://github.com/alifkhasan01/qs.git ~/.config/quickshell
qs
```

Tambahkan ke `hyprland.conf` untuk autostart:

```ini
hl.exec_cmd("qs") or hl.exec_cmd("quickshell")
```

Lihat [docs/hyprland-integration.md](docs/hyprland-integration.md) untuk panduan lengkap keybinding.

---

## Hyprland Integration

Quickshell berkomunikasi dengan Hyprland lewat dua mekanisme:

**GlobalShortcut** (diregistrasi ke Hyprland compositor):
```ini
bind = $mod, D, global, quickshell:dashboard
```

**IPC call** (dipanggil via `exec`):
```ini
bind = $mod, L,       exec, quickshell ipc call lockscreen lock
bind = $mod, P,       exec, quickshell ipc call powermenu toggle
bind = $mod, W,       exec, quickshell ipc call wallpaper toggle
bind = $mod SHIFT, W, exec, quickshell ipc call wallpaper random
```

Lihat [docs/hyprland-integration.md](docs/hyprland-integration.md) untuk referensi lengkap.

---

## Dependencies

### Wajib
- [`quickshell`](https://quickshell.outfoxxed.me) — build terbaru dengan module:
  - `Quickshell.Wayland` / `Quickshell.Hyprland`
  - `Quickshell.Services.Pipewire`
  - `Quickshell.Services.UPower`
  - `Quickshell.Services.Mpris`
  - `Quickshell.Services.Notifications`
  - `Quickshell.Services.Pam`
- `hyprland` — compositor
- Nerd Font — semua ikon pakai glyph Nerd Font (direkomendasikan: CaskaydiaCove Nerd Font)

### Fitur Tambahan
| Package | Dipakai untuk |
|---|---|
| `brightnessctl` | Kontrol brightness |
| `nmcli` (NetworkManager) | Toggle & daftar jaringan WiFi |
| `bluetoothctl` (bluez) | Toggle & daftar perangkat bluetooth |
| `wf-recorder` | Screen recording |
| `grimblast` | Screenshot |
| `swww` | Set wallpaper dengan transisi (`awww` / `awww-daemon`) |
| `pipewire` / `pactl` | Audio mixing untuk recorder |
| `cava` | Visualizer audio di media card |
| `hypridle` | Idle monitor management |
| `hyprsunset` | Night light / color temperature |
| `walker` | App launcher (bisa diganti fuzzel, dll) |
| `matugen` | Sinkronisasi tema ke app lain (opsional) |
| `zenity` | Picker foto profil & folder wallpaper |

---

## Kustomisasi

| Yang ingin diubah | File |
|---|---|
| Warna / tema | `services/Colors.qml` |
| App launcher | `bar/widgets/MenuButton.qml` |
| Jumlah workspace | `bar/widgets/Workspaces.qml` |
| Command toggle idle/night/DND | `dashboard/QuickToggles.qml` |
| Output folder screenshot | `bar/Bar.qml` — `screenshotProc` / `grimProc` |
| Output folder recording | `scripts/record.sh` — `OUTDIR` |
| Threshold notif baterai | `bar/widgets/Battery.qml` |
| Foto profil | `~/.face` (bisa diubah dari tombol di dashboard) |
| Folder & config wallpaper | `wallpaper.json` |

Lihat [docs/configuration.md](docs/configuration.md) untuk detail lengkap.

---

## Changelog

### v2.0 - Sparkline Charts
- **[NEW]** Sparkline chart untuk CPU, GPU, RAM, Disk di SystemInfo panel
- **[NEW]** Auto-scaling visualization - grafik otomatis zoom untuk menampilkan perubahan lebih jelas
- **[NEW]** History tracking hingga 30 data points dengan smooth animation
- **[IMPROVED]** Update interval lebih cepat (1 detik) untuk monitoring real-time
- **[IMPROVED]** Color-coded threshold dengan transisi smooth

### v1.0 - Initial Release
- Dashboard dengan media player dan quick toggles
- Wallpaper manager dengan grid dan slideshow
- Lock screen dengan PAM authentication
- Multi-theme support (4 Catppuccin flavors)

---

## Dokumentasi

- [docs/hyprland-integration.md](docs/hyprland-integration.md) — keybinding, IPC, GlobalShortcut
- [docs/components.md](docs/components.md) — semua komponen QML dan cara kerjanya
- [docs/configuration.md](docs/configuration.md) — kustomisasi, wallpaper.json, tema
