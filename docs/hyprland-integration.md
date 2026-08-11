# Hyprland Integration

Panduan menghubungkan Quickshell ke keybinding Hyprland.

> **Catatan**: Panduan ini menggunakan sintaks Lua untuk konfigurasi Hyprland. Jika Anda masih menggunakan format `.conf` lama, lihat bagian legacy di akhir dokumen.

Quickshell berkomunikasi dengan Hyprland lewat dua mekanisme:

- **GlobalShortcut** — shortcut diregistrasi langsung ke compositor Hyprland. Hyprland yang handle keypress, lalu memanggil handler di Quickshell.
- **IPC call** — Hyprland menjalankan perintah `quickshell ipc call <target> <function>` via `exec`. Bisa juga dipanggil dari terminal atau script.

---

## Referensi Cepat

Tambahkan blok ini ke `~/.config/hypr/hyprland.lua` (atau file yang di-`source`):

```lua
-- ── Quickshell ────────────────────────────────────────────────────────────

-- Dashboard (GlobalShortcut — diregistrasi ke compositor)
hl.bind("$mod, D", "global", "quickshell:dashboard")

-- Lock screen
hl.bind("$mod, L", "exec", "quickshell ipc call lockscreen lock")

-- Power menu
hl.bind("$mod, P", "exec", "quickshell ipc call powermenu toggle")

-- Wallpaper panel
hl.bind("$mod, W", "exec", "quickshell ipc call wallpaper toggle")

-- Wallpaper acak (tanpa membuka panel)
hl.bind("$mod SHIFT, W", "exec", "quickshell ipc call wallpaper random")

-- ── Panel Shortcuts ───────────────────────────────────────────────────────

-- Calendar panel
hl.bind("$mod, C", "global", "quickshell:calendar")

-- Connection panel (Network/Bluetooth)
hl.bind("$mod, N", "global", "quickshell:connection")

-- Clipboard panel
hl.bind("$mod, V", "global", "quickshell:clipboard")

-- ── Media & System Controls ───────────────────────────────────────────────

-- Volume controls
hl.bind(", XF86AudioRaiseVolume", "global", "quickshell:volume:up")
hl.bind(", XF86AudioLowerVolume", "global", "quickshell:volume:down")
hl.bind(", XF86AudioMute",        "global", "quickshell:volume:mute")

-- Brightness controls
hl.bind(", XF86MonBrightnessUp",   "global", "quickshell:brightness:up")
hl.bind(", XF86MonBrightnessDown", "global", "quickshell:brightness:down")
```

---

## Detail per Komponen

### Dashboard

Menggunakan **GlobalShortcut** — Hyprland langsung dispatch event ke Quickshell tanpa spawn proses baru.

```lua
hl.bind("$mod, D", "global", "quickshell:dashboard")
```

### Panel Shortcuts

GlobalShortcut untuk berbagai panel:

```lua
-- Calendar panel
hl.bind("$mod, C", "global", "quickshell:calendar")

-- Connection panel (Network/Bluetooth)
hl.bind("$mod, N", "global", "quickshell:connection")

-- Clipboard panel
hl.bind("$mod, V", "global", "quickshell:clipboard")
```

### Volume Controls

GlobalShortcut untuk kontrol volume dengan media keys:

```lua
hl.bind(", XF86AudioRaiseVolume", "global", "quickshell:volume:up")
hl.bind(", XF86AudioLowerVolume", "global", "quickshell:volume:down")
hl.bind(", XF86AudioMute",        "global", "quickshell:volume:mute")
```

### Brightness Controls

GlobalShortcut untuk kontrol brightness dengan media keys:

```lua
hl.bind(", XF86MonBrightnessUp",   "global", "quickshell:brightness:up")
hl.bind(", XF86MonBrightnessDown", "global", "quickshell:brightness:down")
```

`appid` dan `name` didefinisikan di `shell.qml`:
```qml
GlobalShortcut {
    appid: "quickshell"
    name:  "dashboard"
    onPressed: shellStateObj.dashboardOpen = !shellStateObj.dashboardOpen
}
```

> GlobalShortcut hanya bekerja jika Hyprland mendukung protokol `hyprland-global-shortcuts-v1`.
> Pastikan Hyprland versi terbaru.

---

### Lock Screen

IPC handler didefinisikan di `lockscreen/LockScreen.qml`:

```lua
hl.bind("$mod, L", "exec", "quickshell ipc call lockscreen lock")
```

Fungsi `lock()` akan:
1. Reset buffer password
2. Set `WlSessionLock.locked = true` — mengunci semua monitor sekaligus via `ext_session_lock_v1`
3. Autentikasi lewat PAM (`system-auth`)

Bisa juga dipanggil dari power menu (item "Lock") atau dari terminal:
```bash
quickshell ipc call lockscreen lock
```

---

### Power Menu

IPC handler di `shell.qml`:

```lua
hl.bind("$mod, P", "exec", "quickshell ipc call powermenu toggle")
```

Item-item di power menu menjalankan perintah berikut:

| Item | Perintah |
|---|---|
| Lock | `quickshell ipc call lockscreen lock` |
| Suspend | `systemctl suspend` |
| Reboot | `systemctl reboot` |
| Logout | `hyprctl dispatch exit` |
| Shutdown | `systemctl poweroff` |

---

### Wallpaper Panel & Random

IPC handler di `shell.qml` dengan beberapa fungsi:

```lua
-- Toggle panel wallpaper
hl.bind("$mod, W", "exec", "quickshell ipc call wallpaper toggle")

-- Wallpaper acak langsung (tanpa buka panel)
hl.bind("$mod SHIFT, W", "exec", "quickshell ipc call wallpaper random")
```

Fungsi yang tersedia via IPC:

| Fungsi | Efek |
|---|---|
| `toggle` | Buka/tutup Wallpaper Panel |
| `open` | Buka Wallpaper Panel |
| `close` | Tutup Wallpaper Panel |
| `random` | Pilih wallpaper acak dari daftar di `wallpaper.json` |

`random` menggunakan `WallpaperRandom` yang selalu aktif di background — bisa dipanggil kapan saja meski panel belum pernah dibuka.

---

## Autostart

```lua
hl.exec_cmd("qs")
```

Letakkan di bagian atas `hyprland.lua` agar shell langsung berjalan saat login.

---

## Contoh Config Lengkap

```lua
-- Autostart
hl.exec_cmd("qs")

-- ── Quickshell Keybindings ────────────────────────────────────────────────

-- Main shortcuts
hl.bind("$mod, D",       "global", "quickshell:dashboard")
hl.bind("$mod, L",       "exec",   "quickshell ipc call lockscreen lock")
hl.bind("$mod, P",       "exec",   "quickshell ipc call powermenu toggle")
hl.bind("$mod, W",       "exec",   "quickshell ipc call wallpaper toggle")
hl.bind("$mod SHIFT, W", "exec",   "quickshell ipc call wallpaper random")

-- Panel shortcuts
hl.bind("$mod, C", "global", "quickshell:calendar")
hl.bind("$mod, N", "global", "quickshell:connection")
hl.bind("$mod, V", "global", "quickshell:clipboard")

-- Volume controls
hl.bind(", XF86AudioRaiseVolume", "global", "quickshell:volume:up")
hl.bind(", XF86AudioLowerVolume", "global", "quickshell:volume:down")
hl.bind(", XF86AudioMute",        "global", "quickshell:volume:mute")

-- Brightness controls
hl.bind(", XF86MonBrightnessUp",   "global", "quickshell:brightness:up")
hl.bind(", XF86MonBrightnessDown", "global", "quickshell:brightness:down")
```

---

## Tips

- Semua IPC call bisa dijalankan dari terminal untuk testing:
  ```bash
  quickshell ipc call lockscreen lock
  quickshell ipc call powermenu toggle
  quickshell ipc call wallpaper random
  ```

- Kalau GlobalShortcut untuk dashboard tidak bekerja, coba fallback ke IPC:
  ```lua
  hl.bind("$mod, D", "exec", "quickshell ipc call dashboard toggle")
  ```
  Tapi perlu ditambahkan IpcHandler `dashboard` di `shell.qml` terlebih dulu.

- Untuk cek apakah Quickshell sudah berjalan:
  ```bash
  pgrep -x qs
  ```

---

## Legacy Format (.conf)

Jika Anda masih menggunakan format `.conf` lama, berikut sintaksnya:

```ini
# Autostart
exec-once = qs

# Main shortcuts
bind = $mod, D,       global, quickshell:dashboard
bind = $mod, L,       exec,   quickshell ipc call lockscreen lock
bind = $mod, P,       exec,   quickshell ipc call powermenu toggle
bind = $mod, W,       exec,   quickshell ipc call wallpaper toggle
bind = $mod SHIFT, W, exec,   quickshell ipc call wallpaper random

# Panel shortcuts
bind = $mod, C, global, quickshell:calendar
bind = $mod, N, global, quickshell:connection
bind = $mod, V, global, quickshell:clipboard

# Volume controls
bind = , XF86AudioRaiseVolume, global, quickshell:volume:up
bind = , XF86AudioLowerVolume, global, quickshell:volume:down
bind = , XF86AudioMute,        global, quickshell:volume:mute

# Brightness controls
bind = , XF86MonBrightnessUp,   global, quickshell:brightness:up
bind = , XF86MonBrightnessDown, global, quickshell:brightness:down
```

> **Rekomendasi**: Migrasikan ke format Lua untuk fitur dan fleksibilitas yang lebih baik.
