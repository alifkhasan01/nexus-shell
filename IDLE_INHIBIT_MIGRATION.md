# Migrasi dari hypridle ke Quickshell IdleManager

## Ringkasan

Sistem idle management telah **sepenuhnya diganti** dengan **Quickshell IdleManager** native, menggantikan `hypridle` daemon eksternal. Kini Anda memiliki kontrol penuh atas idle timeout langsung dari dashboard UI.

## Perubahan File

### File Baru

1. **`services/IdleManager.qml`**
   - Service singleton dengan 3 IdleMonitor (screen off, lock, suspend)
   - API: `toggle()`, `enable()`, `disable()`, `setScreenOffTimeout()`, dll
   - Auto-trigger actions: dpms off → lock → suspend

2. **`services/IdleInhibitService.qml`**
   - Service untuk temporary prevent idle (video playback, dll)
   - API: `toggle()`, `enable()`, `disable()`

3. **`dashboard/SpinBox.qml`**
   - Custom spinbox component untuk input timeout

4. **`docs/idle-inhibit-guide.md`**
   - Dokumentasi lengkap → **RENAMED** ke `idle-management-guide.md`

### File Dimodifikasi

1. **`services/qmldir`**
   - Ditambahkan: `singleton IdleManager 1.0 IdleManager.qml`
   - Ditambahkan: `singleton IdleInhibitService 1.0 IdleInhibitService.qml`

2. **`shell.qml`**
   - Inject lock function ke IdleManager
   - Inject window reference ke IdleInhibitService

3. **`dashboard/QuickToggles.qml`**
   - Import: `import "../services" as Services`
   - Tombol IDLE sekarang toggle `IdleManager.monitoringEnabled`
   - Icon: 󰅶 (enabled) / 󰒲 (disabled)

4. **`dashboard/SettingsTab.qml`**
   - Section baru: **Idle Timeouts**
   - 3 SpinBox untuk set timeout: Screen Off, Lock, Suspend
   - Real-time apply (tidak perlu restart)

## Keuntungan

✅ **No external daemon** - Fully integrated dalam Quickshell  
✅ **UI Settings** - Atur timeout via spinbox, tidak perlu edit config  
✅ **Real-time apply** - Perubahan langsung aktif  
✅ **Lebih ringan** - Tidak ada process overhead  
✅ **Native Wayland** - Menggunakan protokol ext-idle-notify-v1  
✅ **Lebih responsif** - Toggle dan settings langsung via API  
✅ **Cascade actions** - Screen off → Lock → Suspend bertahap  
✅ **Inhibitor support** - Temporary prevent saat nonton video/presentasi  

## Cara Menggunakan

### Toggle Monitoring (Enable/Disable Idle Management)

1. Buka Dashboard (Super+D)
2. Klik tombol **IDLE** di Quick Toggles
3. **Biru** = Monitoring aktif (auto screen-off/lock/suspend enabled)
4. **Abu** = Monitoring nonaktif (tidak ada auto action)

### Atur Timeout

1. Klik **tombol Idle** (󰒲) di bar (kanan atas, sebelah clipboard)
2. Panel Idle Timeouts akan muncul
3. Gunakan spinbox (+/-) untuk set timeout:
   - **Screen Off**: 1-60 menit (default: 5 menit)
   - **Lock Screen**: 1-120 menit (default: 10 menit)
   - **Suspend**: 5-240 menit (default: 30 menit)
4. Toggle **Idle Monitoring** di bawah untuk enable/disable
5. Perubahan **langsung aktif** tanpa restart

### Default Timeouts

```
User Active ──┐
              │
   5 min ─────┼──→ Screen Off (layar mati)
              │
  10 min ─────┼──→ Lock Screen (butuh password)
              │
  30 min ─────┼──→ Suspend (hemat baterai)
              │
User Input ───┴──→ Reset semua + layar nyala
```

## Migrasi

Jika sebelumnya menggunakan hypridle:

1. **Tidak perlu uninstall hypridle** dari sistem (tetap bisa dipakai untuk use case lain)
2. Tombol IDLE di dashboard sekarang otomatis menggunakan IdleManager
3. Config hypridle di `~/.config/hypr/hypridle.conf` tidak terpengaruh
4. **Matikan hypridle autostart** jika ada:
   ```bash
   # Check apakah hypridle running
   pgrep -x hypridle
   
   # Kill jika running
   pkill -x hypridle
   
   # Disable autostart (jika ada di hyprland.conf)
   # Hapus atau comment line: exec-once = hypridle
   ```

5. **Migrate timeout settings**:
   - Lihat timeout di `hypridle.conf`
   - Set equivalent timeout di Dashboard → Settings → Idle Timeouts
   - IdleManager akan handle semua idle actions

## Testing

### Test Idle Monitoring

1. **Enable monitoring**: Klik tombol IDLE (jadi biru)
2. **Set timeout pendek** untuk test (misal screen off = 1 menit)
3. **Jangan sentuh keyboard/mouse** selama 1 menit
4. **Layar seharusnya mati** setelah 1 menit
5. **Gerakkan mouse** → layar langsung nyala
6. **Reset timeout** ke nilai normal (5 menit)

### Test Inhibitor (Prevent Idle)

Jika ingin temporary prevent idle (misal saat nonton video):

1. Aplikasi seperti mpv/vlc biasanya auto-enable inhibitor
2. Atau manual via code: `IdleInhibitService.enable()`
3. Idle monitoring akan **tidak trigger** selama inhibitor aktif
4. Setelah selesai, inhibitor auto-disabled

## Catatan Kompatibilitas

- **Compositor**: Memerlukan Wayland compositor dengan dukungan `ext-idle-notify-v1`
- **Hyprland**: ✅ Sudah support (versi terbaru)
- **Sway**: ✅ Sudah support
- **KDE Wayland**: ✅ Sudah support
- **GNOME Wayland**: ⚠️ Mungkin limited support

Check compositor version untuk memastikan protocol support.

## Troubleshooting

Lihat `docs/idle-inhibit-guide.md` untuk panduan troubleshooting lengkap.
