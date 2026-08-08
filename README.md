# Quickshell Config

Shell desktop berbasis [Quickshell](https://quickshell.outfoxxed.me) untuk Hyprland.
Mencakup bar, dashboard, panel, notifikasi, OSD, lockscreen, dan power menu — semua dalam satu config QML.

## Tampilan

- **Bar** — panel atas dengan workspace, clock, status network/bluetooth/volume/brightness/battery
- **Dashboard** — dropdown dari clock: media player, quick toggles, system stats, settings
- **Panel Wi-Fi & Bluetooth** — panel popup dengan daftar jaringan & perangkat
- **Volume Panel** — mixer per-aplikasi + device selector
- **Power Menu** — shutdown, reboot, suspend, logout, lock
- **Notifikasi** — popup notifikasi native + OSD untuk volume & brightness
- **Lock Screen** — via `hyprlock`
- **Tema** — 4 flavor Catppuccin (Latte, Frappé, Macchiato, Mocha), bisa ganti live dari dashboard

---

## Struktur

```
~/.config/quickshell/
├── shell.qml                    # Entry point — spawn Bar, LockScreen, NotificationPopup
├── qmldir                       # Registrasi singleton (Colors, CavaService)
├── theme                        # File teks: nama tema aktif saat ini
├── wallpaper.json               # Daftar wallpaper untuk randomizer
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
│       ├── MenuButton.qml       # Tombol app launcher (fuzzel)
│       ├── NetworkStatus.qml    # Toggle WiFi (klik kiri) + buka panel (klik kanan)
│       ├── PowerButton.qml      # Buka power menu
│       ├── Volume.qml           # Volume via Pipewire + OSD
│       ├── WallpaperRandom.qml  # Randomizer wallpaper
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
│   ├── SystemInfo.qml           # Info sistem (CPU, RAM, disk, uptime, profil)
│   ├── SystemStats.qml          # Bar stats ringkas di dashboard
│   ├── ThemeSelector.qml        # Selector 4 flavor Catppuccin
│   └── cava_feed.sh             # Script feed data cava ke named pipe
│
├── panels/
│   ├── ConnectPanel.qml         # Panel Wi-Fi + Bluetooth (dua tab)
│   ├── VolumePanel.qml          # Mixer volume per-aplikasi + device
│   ├── WallpaperButton.qml      # Tombol wallpaper di panel
│   └── WallpaperPanel.qml       # Panel pilih wallpaper
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
│   └── LockScreen.qml           # Lock screen via hyprlock
│
├── overview/                    # (placeholder)
│
└── scripts/
    ├── btagent.sh               # BlueZ agent — auto-accept pairing bluetooth
    ├── record.sh                # Toggle recording via wf-recorder
    └── screenshot.sh            # Helper screenshot
```

---

## Fitur Detail

### Bar

| Widget | Fungsi |
|---|---|
| Menu Button | Buka app launcher (`fuzzel`) |
| Workspaces | Indikator workspace aktif via Hyprland IPC |
| Clock | Klik = toggle dashboard |
| Network | Klik kiri = toggle WiFi on/off · Klik kanan = buka ConnectPanel |
| Bluetooth | Klik kiri = toggle BT on/off · Klik kanan = buka ConnectPanel |
| Volume | Scroll = ubah volume · Klik = buka VolumePanel · Klik kanan = mute |
| Brightness | Scroll = ubah brightness |
| Battery | Indikator baterai — notif saat ≤30% (warning) dan ≥90% charging (hampir penuh) |
| Power | Buka power menu |

### Dashboard

Buka dengan klik jam atau shortcut `$mod + D` (bind di hyprland.conf).

**Kolom kiri — Overview & Settings:**
- Foto profil (dari `~/.face`), tanggal, jam
- Quick toggles (lihat bawah)
- System stats (CPU, RAM, uptime)
- Settings: slider volume & brightness, theme selector

**Quick Toggles:**
| Tombol | Klik Kiri | Klik Kanan | Notifikasi |
|---|---|---|---|
| Idle | Toggle hypridle on/off | — | Ya |
| Screenshot Select | Capture area pilihan | — | Setelah tersimpan |
| Screenshot Full | Capture layar penuh | — | Setelah tersimpan |
| Recorder | Start/stop wf-recorder (desktop audio) | Start dengan mic | Setelah file tersimpan |
| DND | Toggle Do Not Disturb | — | Ya |
| Night Light | Toggle hyprsunset | — | Ya |

**Kolom tengah — Media:**
- Cover art, judul, artis, album
- Visualizer cava berbentuk cincin di belakang cover
- Seek bar, play/pause/next/prev, shuffle, loop
- Kontrol via MPRIS (otomatis detect player yang sedang aktif)

**Kolom kanan — System Info:**
- Statistik CPU, RAM, disk
- Informasi sistem

### Recording

`record.sh` menggunakan `wf-recorder`:
- **Klik kiri** → rekam layar + audio desktop saja
- **Klik kanan** → rekam layar + audio desktop + mic (via PipeWire null-sink mixer)
- Output disimpan ke `~/Videos/Recordings/` dalam format `.mp4`
- Klik tombol lagi untuk stop — notif muncul setelah file tersimpan

### Tema

4 flavor Catppuccin tersedia dan bisa diganti live dari dashboard (tanpa restart):

| Flavor | Jenis |
|---|---|
| Latte | Light |
| Frappé | Dark medium |
| Macchiato | Dark |
| Mocha | Dark (default) |

Ganti tema juga memicu `matugen` untuk sinkronkan warna ke GTK, Qt, foot, dan Hyprland (jika `matugen` terinstall).

---

## Dependencies

### Wajib
- [`quickshell`](https://quickshell.outfoxxed.me) — build terbaru dengan module:
  - `Quickshell.Wayland` / `Quickshell.Hyprland`
  - `Quickshell.Services.Pipewire`
  - `Quickshell.Services.UPower`
  - `Quickshell.Services.Mpris`
  - `Quickshell.Services.Notifications`
- `hyprland` — compositor
- `hyprlock` — lock screen
- Nerd Font — semua ikon pakai glyph Nerd Font (direkomendasikan: CaskaydiaCove Nerd Font)

### Fitur Tambahan
| Package | Dipakai untuk |
|---|---|
| `brightnessctl` | Kontrol brightness |
| `nmcli` (NetworkManager) | Toggle & daftar jaringan WiFi |
| `bluetoothctl` (bluez) | Toggle & daftar perangkat bluetooth |
| `wf-recorder` | Screen recording |
| `grimblast` | Screenshot |
| `pipewire` / `pactl` | Audio mixing untuk recorder |
| `cava` | Visualizer audio di media card |
| `hypridle` | Idle monitor management |
| `hyprsunset` | Night light / color temperature |
| `notif-quickshell` | Do Not Disturb toggle |
| `walker` | App launcher (bisa diganti) |
| `matugen` | Sinkronisasi tema ke app lain (opsional) |
| `zenity` | Picker foto profil di dashboard |

---

## Instalasi

```bash
git clone <repo> ~/.config/quickshell
qs
```

Tambahkan ke `hyprland.conf` untuk autostart:

```ini
exec-once = qs
```

Untuk shortcut dashboard:

```ini
bind = $mod, D, global, quickshell:dashboard
```

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
| Foto profil | `~/.face` (file gambar, bisa diubah dari tombol di dashboard) |
| Daftar wallpaper | `wallpaper.json` |
