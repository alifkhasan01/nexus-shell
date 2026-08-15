# Idle Configuration Format

## File Location
`~/.config/quickshell/idle-config.json`

## Format
```json
{
  "screenOffTimeout": 300,
  "lockTimeout": 600,
  "suspendTimeout": 1800,
  "monitoringEnabled": true
}
```

## Fields

- **screenOffTimeout** (integer): Waktu dalam detik sebelum layar dimatikan saat idle
  - Default: 300 (5 menit)
  - Range: 60-3600 (1-60 menit)

- **lockTimeout** (integer): Waktu dalam detik sebelum lock screen aktif saat idle
  - Default: 600 (10 menit)
  - Range: 60-7200 (1-120 menit)

- **suspendTimeout** (integer): Waktu dalam detik sebelum sistem suspend saat idle
  - Default: 1800 (30 menit)
  - Range: 300-14400 (5-240 menit)

- **monitoringEnabled** (boolean): Master switch untuk enable/disable semua idle monitoring
  - Default: true
  - Values: true atau false

## Behavior

- File akan dibuat otomatis saat pertama kali Quickshell berjalan jika belum ada
- Setiap perubahan di IdlePanel akan otomatis disimpan ke file ini
- Konfigurasi akan di-load otomatis saat Quickshell restart
- Jika file corrupt atau tidak bisa di-parse, akan menggunakan nilai default

## Manual Editing

Anda bisa edit file JSON ini secara manual, tapi pastikan:
1. Format JSON valid (gunakan linter jika perlu)
2. Nilai timeout dalam detik (bukan menit)
3. Restart Quickshell setelah edit manual

## Example Configurations

### Conservative (untuk battery life)
```json
{
  "screenOffTimeout": 180,
  "lockTimeout": 300,
  "suspendTimeout": 600,
  "monitoringEnabled": true
}
```

### Relaxed (untuk desktop)
```json
{
  "screenOffTimeout": 600,
  "lockTimeout": 1200,
  "suspendTimeout": 3600,
  "monitoringEnabled": true
}
```

### Disabled (untuk presentation mode)
```json
{
  "screenOffTimeout": 300,
  "lockTimeout": 600,
  "suspendTimeout": 1800,
  "monitoringEnabled": false
}
```
