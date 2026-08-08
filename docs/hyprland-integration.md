# Hyprland Integration

Panduan menghubungkan Quickshell ke keybinding Hyprland.

Quickshell berkomunikasi dengan Hyprland lewat dua mekanisme:

- **GlobalShortcut** — shortcut diregistrasi langsung ke compositor Hyprland. Hyprland yang handle keypress, lalu memanggil handler di Quickshell.
- **IPC call** — Hyprland menjalankan perintah `quickshell ipc call <target> <function>` via `exec`. Bisa juga dipanggil dari terminal atau script.

---

## Referensi Cepat

Tambahkan blok ini ke `~/.config/hypr/hyprland.conf` (atau file yang di-`source`):

```ini
# ── Quickshell ────────────────────────────────────────────────────────────

# Dashboard (GlobalShortcut — diregistrasi ke compositor)
bind = $mod, D, global, quickshell:dashboard

# Lock screen
bind = $mod, L, exec, quickshell ipc call lockscreen lock

# Power menu
bind = $mod, P, exec, quickshell ipc call powermenu toggle

# Wallpaper panel
bind = $mod, W,       exec, quickshell ipc call wallpaper toggle

# Wallpaper acak (tanpa membuka panel)
bind = $mod SHIFT, W, exec, quickshell ipc call wallpaper random
```

---

## Detail per Komponen

### Dashboard

Menggunakan **GlobalShortcut** — Hyprland langsung dispatch event ke Quickshell tanpa spawn proses baru.

```ini
bind = $mod, D, global, quickshell:dashboard
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

```ini
bind = $mod, L, exec, quickshell ipc call lockscreen lock
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

```ini
bind = $mod, P, exec, quickshell ipc call powermenu toggle
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

```ini
# Toggle panel wallpaper
bind = $mod, W, exec, quickshell ipc call wallpaper toggle

# Wallpaper acak langsung (tanpa buka panel)
bind = $mod SHIFT, W, exec, quickshell ipc call wallpaper random
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

```ini
exec-once = qs
```

Letakkan di bagian atas `hyprland.conf` agar shell langsung berjalan saat login.

---

## Contoh Config Lengkap

```ini
# Autostart
exec-once = qs

# ── Quickshell keybindings ────────────────────────────────────────────────
bind = $mod, D,       global, quickshell:dashboard
bind = $mod, L,       exec,   quickshell ipc call lockscreen lock
bind = $mod, P,       exec,   quickshell ipc call powermenu toggle
bind = $mod, W,       exec,   quickshell ipc call wallpaper toggle
bind = $mod SHIFT, W, exec,   quickshell ipc call wallpaper random
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
  ```ini
  bind = $mod, D, exec, quickshell ipc call dashboard toggle
  ```
  Tapi perlu ditambahkan IpcHandler `dashboard` di `shell.qml` terlebih dulu.

- Untuk cek apakah Quickshell sudah berjalan:
  ```bash
  pgrep -x qs
  ```
