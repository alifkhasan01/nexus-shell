# Idle Management Guide

## Overview

Konfigurasi ini menggunakan **Quickshell IdleMonitor** untuk menggantikan `hypridle` sepenuhnya, memberikan kontrol idle management native tanpa bergantung pada daemon eksternal.

## Fitur

- **Native Wayland Integration**: Menggunakan protokol `ext-idle-notify-v1`
- **Persistent Configuration**: Konfigurasi disimpan ke JSON, tidak reset saat restart
- **Configurable Timeouts**: Atur timeout untuk screen off, lock, dan suspend
- **IdlePanel UI**: Panel khusus untuk mengatur timeout dengan spinbox intuitif
- **Master Toggle**: Enable/disable semua idle monitoring dengan satu switch
- **Auto Actions**: Screen off → Lock → Suspend secara bertahap
- **Idle Inhibitor Support**: Respect aplikasi yang mencegah idle (video player, dll)

## Cara Kerja

### IdleManager Service

Service singleton yang mengelola 3 idle monitors dengan timeout berbeda:

1. **Screen Off** (default: 5 menit)
   - Matikan layar dengan `hyprctl dispatch dpms off`
   - Layar otomatis nyala saat ada aktivitas user

2. **Lock Screen** (default: 10 menit)
   - Trigger lock screen Quickshell
   - Memerlukan password untuk unlock

3. **Suspend** (default: 30 menit)
   - Suspend sistem dengan `systemctl suspend`
   - Hemat baterai maksimal

### Configuration Persistence

Semua pengaturan disimpan otomatis ke `~/.config/quickshell/data/idle-config.json`:

```json
{
  "screenOffTimeout": 300,
  "lockTimeout": 600,
  "suspendTimeout": 1800,
  "monitoringEnabled": true
}
```

- ✅ Konfigurasi di-load otomatis saat Quickshell start
- ✅ Perubahan di IdlePanel langsung disimpan
- ✅ Tidak ada reset ke default saat restart
- ✅ Bisa diedit manual (dalam detik, bukan menit)

Lihat [idle-config-format.md](./idle-config-format.md) untuk detail format dan contoh.

### API

```qml
// Toggle monitoring on/off
IdleManager.toggle()
IdleManager.enable()
IdleManager.disable()

// Check state
IdleManager.monitoringEnabled  // boolean

// Set timeouts (dalam menit) - auto save ke JSON
IdleManager.setScreenOffTimeout(5)
IdleManager.setLockTimeout(10)
IdleManager.setSuspendTimeout(30)

// Current timeouts (dalam detik)
IdleManager.screenOffTimeout
IdleManager.lockTimeout
IdleManager.suspendTimeout
```

### Implementasi

1. **IdleManager Service**: `services/IdleManager.qml`
   - Singleton service dengan 3 IdleMonitor (screen off, lock, suspend)
   - Configurable timeouts
   - Auto trigger actions saat idle

2. **IdleInhibitService**: `services/IdleInhibitService.qml`
   - Untuk temporary disable (misal saat nonton video)
   - Mencegah IdleMonitor trigger saat `respectInhibitors: true`

3. **Integration**: `shell.qml`
   - Menghubungkan IdleManager dengan lock function
   - Auto-start monitoring saat quickshell boot

4. **UI**: 
   - `dashboard/QuickToggles.qml` - Tombol IDLE untuk toggle monitoring
   - `dashboard/SettingsTab.qml` - SpinBox untuk set timeouts
   - `dashboard/SpinBox.qml` - Custom spinbox component

## Cara Menggunakan

### Toggle Monitoring

1. Buka Dashboard (Super+D)
2. Klik tombol **IDLE** di Quick Toggles
3. **Biru** = Monitoring aktif (auto screen-off/lock/suspend)
4. **Abu** = Monitoring nonaktif (tidak ada auto action)

### Atur Timeout

1. Buka Dashboard → Tab Settings
2. Scroll ke section **Idle Timeouts**
3. Atur timeout untuk:
   - **Screen Off**: 1-60 menit
   - **Lock Screen**: 1-120 menit  
   - **Suspend**: 5-240 menit
4. Perubahan langsung diterapkan

### Temporary Disable (Inhibit)

Jika ingin temporary prevent idle (misal saat presentasi/nonton video), gunakan IdleInhibitService:

```qml
// Dari QML code
IdleInhibitService.enable()   // Prevent idle
IdleInhibitService.disable()  // Allow idle again
```

## Perbedaan dengan hypridle

| Aspek | hypridle | IdleManager |
|-------|----------|--------------|
| **Proses** | Daemon terpisah | Built-in Quickshell |
| **Konfigurasi** | File config terpisah | QML properties + UI |
| **Resources** | Process tambahan | Tidak ada overhead |
| **Integration** | Command-based | API native |
| **UI Settings** | Edit config manual | SpinBox di dashboard |
| **Kompleksitas** | Perlu manage process | Simple toggle + settings |
| **Real-time** | Perlu restart daemon | Instant apply |

## Troubleshooting

### Idle monitoring tidak bekerja

1. Pastikan compositor mendukung `ext-idle-notify-v1`:
   ```bash
   # Untuk Hyprland, protokol ini sudah supported di versi terbaru
   hyprctl version
   ```

2. Check log Quickshell untuk error:
   ```bash
   journalctl --user -u quickshell -f
   # atau
   tail -f ~/.local/state/quickshell/log.qslog
   ```

3. Pastikan monitoring enabled:
   - Check tombol IDLE di dashboard (harus biru)
   - Atau via console: `IdleManager.monitoringEnabled`

### Layar tidak mati setelah timeout

1. **Check IdleInhibitor**: Pastikan tidak ada aplikasi yang aktif inhibit idle
2. **Check timeout value**: Pastikan timeout sudah sesuai (misal 5 menit = 300 detik)
3. **Test manual**: 
   ```bash
   hyprctl dispatch dpms off  # Test matikan layar
   hyprctl dispatch dpms on   # Test nyalakan layar
   ```

### Lock tidak trigger

1. Pastikan lock function ter-inject dengan benar
2. Check log saat timeout tercapai
3. Test manual lock: Super+L atau `quickshell:lock` shortcut

### Suspend tidak bekerja

1. Test manual suspend:
   ```bash
   systemctl suspend
   ```
2. Jika gagal, mungkin ada systemd inhibitor lock:
   ```bash
   systemd-inhibit --list
   ```

### Ingin disable salah satu action

Edit `services/IdleManager.qml` dan set `enabled: false` pada monitor yang tidak diinginkan:

```qml
property IdleMonitor suspendMonitor: IdleMonitor {
    enabled: false  // Disable suspend
    timeout: idleManager.suspendTimeout
    // ...
}
```

## Technical Details

### Wayland Protocols

1. **ext-idle-notify-v1** (IdleMonitor)
   - Notify aplikasi saat user idle
   - Berbasis timeout yang bisa dikonfigurasi
   - Respect idle inhibitors

2. **idle-inhibit-unstable-v1** (IdleInhibitor)  
   - Temporary prevent idle state
   - Useful untuk video playback, presentations, etc

### Monitor Cascade

IdleManager menggunakan 3 monitor independen dengan timeout berbeda:

```
User Active ──┐
              │
   5 min ─────┼──→ Screen Off (dpms off)
              │
  10 min ─────┼──→ Lock Screen
              │
  30 min ─────┼──→ Suspend
              │
User Input ───┴──→ Reset all timers + screen on
```

Setiap monitor bekerja independent, sehingga:
- Screen off bisa terjadi tanpa menunggu lock
- Lock bisa terjadi tanpa menunggu suspend
- User activity mereset SEMUA timer sekaligus

### respectInhibitors Behavior

Saat `respectInhibitors: true`, IdleMonitor akan:
- **Tidak** trigger idle jika ada IdleInhibitor aktif
- **Tetap** counting time jika tidak ada inhibitor
- Berguna untuk temporary prevent (video playback, dll)

Contoh: Saat nonton video dengan mpv (yang biasanya auto-inhibit idle), IdleMonitor tidak akan trigger screen off/lock/suspend.
