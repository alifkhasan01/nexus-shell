# Quickshell Bar

Bar minimal buat Hyprland: menu + workspace (kiri), clock (tengah), volume + brightness + battery + power (kanan).

## Struktur

```
quickshell-bar/
├── shell.qml              # entry point, spawn Bar di tiap monitor
├── Colors.qml              # singleton warna (Catppuccin Mocha)
├── qmldir                  # registrasi singleton Colors
└── modules/
    ├── Bar.qml              # PanelWindow + layout 3 kolom
    ├── MenuButton.qml        # tombol buka app launcher
    ├── Workspaces.qml        # indikator workspace via Hyprland IPC
    ├── Clock.qml              # klik = toggle Dashboard
    ├── Volume.qml            # via Pipewire (scroll = ubah volume, klik kanan = mute)
    ├── Brightness.qml        # via brightnessctl (scroll = ubah brightness)
    ├── Battery.qml           # via UPower
    ├── PowerButton.qml        # buka popup power menu
    ├── PowerMenuItem.qml
    ├── Dashboard.qml          # panel dashboard ala Caelestia, dibuka dari Clock
    └── dashboard/
        ├── MediaCard.qml       # media player via MPRIS + cava visualizer
        ├── QuickToggles.qml    # baris toggle WiFi/Bluetooth/DND/Night Light
        ├── QuickToggle.qml     # komponen pill toggle generik
        ├── SliderRow.qml       # slider generik (dipakai volume & brightness)
        ├── SystemStats.qml     # CPU / RAM / uptime
        └── cava_feed.sh        # feed data cava ke /tmp/qs-cava.out untuk visualizer
```

## Dashboard

Klik jam di tengah bar buat buka/tutup dashboard (dropdown dari atas, mirip dashboard Caelestia). Isinya:

- **Media player** — MPRIS (`Quickshell.Services.Mpris`): cover art, judul/artis, play/pause/next/prev; dilengkapi **cava visualizer** 16 bar animasi di bagian bawah card
- **Quick toggles** — WiFi (`nmcli`), Bluetooth (`bluetoothctl`), DND (`dunstctl`), Night Light (`hyprsunset`)
- **Slider** — volume (Pipewire) & brightness (`brightnessctl`), langsung drag
- **System stats** — CPU, RAM (dari `/proc/stat` & `free`), uptime

## Dependencies

- `quickshell` (git terbaru, dengan module `Quickshell.Hyprland`, `Quickshell.Services.Pipewire`, `Quickshell.Services.UPower`, `Quickshell.Services.Mpris`)
- `brightnessctl` (untuk brightness)
- `cava` — untuk audio visualizer di MediaCard. Jalankan `cava_feed.sh` di background sebelum/bersamaan dengan quickshell
- `nmcli`, `bluetoothctl`, `dunstctl`, `hyprsunset` untuk quick toggles di dashboard — **ganti command-nya** di `modules/dashboard/QuickToggles.qml` kalau tooling kamu beda (mis. `iwctl` untuk WiFi, `mako` bukan `dunst`, `wlsunset` bukan `hyprsunset`)
- Nerd Font (icon di Text pakai glyph nerd font, ganti kalau font kamu beda)
- App launcher pilihan kamu (default dipanggil: `fuzzel`, ganti di `MenuButton.qml`)

## Menjalankan

```bash
# taruh folder ini di ~/.config/quickshell/, lalu:
qs -c quickshell-bar
```

atau langsung:

```bash
qs -p /path/ke/quickshell-bar
```

Tambahkan ke `hyprland.conf` biar auto-start:

```
exec-once = qs -c quickshell-bar
```

Untuk mengaktifkan **cava visualizer** di MediaCard, jalankan juga `cava_feed.sh`:

```
exec-once = bash ~/.config/quickshell/modules/dashboard/cava_feed.sh
```

## Yang perlu disesuaikan

- **Jumlah workspace**: `Workspaces.qml` → `workspaceCount` (default 5).
- **Launcher command**: `MenuButton.qml` → `launcherCommand` (default `fuzzel`).
- **Icon font**: semua glyph di `Text.text` pakai Nerd Font Unicode private-use area — kalau icon muncul kotak, cek font family di Hyprland/GTK sudah Nerd Font.
- **Lock command**: `PowerButton.qml` → item "Lock" pakai `hyprlock`, ganti kalau pakai `swaylock` dll.
- **Warna**: `Colors.qml`, tinggal ganti hex value-nya kalau mau tema lain selain Catppuccin Mocha.
- **Tinggi bar / exclusive zone**: `Bar.qml` → `implicitHeight`.
