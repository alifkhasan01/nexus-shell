# Nexus Shell — CLI & IPC Integration

Dokumen ini adalah spesifikasi integrasi Nexus Shell dengan Nexus CLI.

> **Status: Planned**
>
> Implementasi dokumen ini dilakukan **setelah Nexus CLI dan IPC protocol stabil**.

## 1. Tujuan

Nexus Shell berfungsi sebagai runtime/UI untuk Nexus.

Nexus CLI berfungsi sebagai client.

```text
Nexus CLI
    │
    │ Unix Socket
    ▼
Nexus Shell
    │
    ▼
Nexus Actions
    │
    ├── Launcher
    ├── Dashboard
    ├── Notifications
    ├── Control Center
    ├── Wallpaper
    ├── Media
    └── Power
```

## 2. IPC Server

Shell menjalankan IPC server ketika Nexus dimulai.

Socket:

```text
$XDG_RUNTIME_DIR/nexus.sock
```

Shell harus:

1. Membuat socket.
2. Menerima connection.
3. Membaca request.
4. Memvalidasi protocol version.
5. Mencari module.
6. Menjalankan action.
7. Mengirim response.

## 3. Action Registry

Semua action Nexus harus terdaftar secara eksplisit.

Contoh:

```text
launcher.toggle
dashboard.toggle
notifications.toggle
control.toggle
wallpaper.next
wallpaper.previous
wallpaper.random
media.play_pause
power.open
```

Registry digunakan oleh:

- IPC
- Global Shortcut
- internal shell components

## 4. Global Shortcut

Global Shortcut tidak boleh memiliki business logic sendiri.

Contoh konsep:

```text
SUPER + SPACE
       │
       ▼
GlobalShortcut
       │
       ▼
launcher.toggle()
```

IPC:

```text
nexus ipc call launcher toggle
       │
       ▼
launcher.toggle()
```

Keduanya harus menghasilkan behavior yang sama.

## 5. Shortcut Configuration

Shortcut dapat dikonfigurasi melalui Nexus CLI.

CLI:

```bash
nexus shortcut list
```

Shell membaca konfigurasi tersebut dan mendaftarkan Global Shortcut.

Konsep:

```text
shortcut config
      │
      ▼
GlobalShortcut registration
      │
      ▼
Nexus Action
```

## 6. Tidak Mengikat Action ke Hyprland

Nexus Shell tidak boleh menganggap Hyprland sebagai satu-satunya compositor.

Action Nexus harus compositor-independent.

```text
Hyprland
Niri
Sway
Other Wayland WM
        │
        ▼
    Nexus Action
```

Integrasi khusus compositor berada pada integration layer.

## 7. Lifecycle

Ketika Nexus Shell dimulai:

```text
1. Load configuration
2. Initialize modules
3. Register actions
4. Start IPC server
5. Register global shortcuts
6. Start UI
```

Ketika berhenti:

```text
1. Unregister shortcuts
2. Stop IPC server
3. Cleanup socket
4. Stop services
```

## 8. Implementasi Bertahap

Jangan implementasikan seluruh sistem sekaligus.

Urutan:

```text
CLI
 ↓
IPC Protocol
 ↓
Mock Server
 ↓
Shell IPC Server
 ↓
Action Registry
 ↓
Global Shortcut
 ↓
Hyprland Integration
```

Global Shortcut **tidak menjadi dependency awal CLI**.

CLI harus dapat diuji tanpa menjalankan Quickshell.

## 9. Testing

IPC harus dapat dites tanpa UI.

Contoh:

```text
CLI
 ↓
Mock IPC Server
 ↓
Response
```

Test:

```text
launcher.toggle → success
unknown.module  → error
unknown.action  → error
invalid.version → error
timeout         → error
```

Setelah Shell IPC tersedia:

```text
CLI
 ↓
Real IPC
 ↓
Nexus Shell
 ↓
Action
```

## 10. Kontrak antara CLI dan Shell

CLI menentukan:

```text
protocol version
request format
response format
module name
action name
argument format
error format
```

Shell mengimplementasikan kontrak tersebut.

Jangan membalik dependency:

```text
Shell implementation
        ↓
CLI mengikuti implementation
```

Yang digunakan:

```text
Nexus IPC Contract
        │
   ┌────┴────┐
   ▼         ▼
  CLI       Shell
```

Dengan demikian CLI dan Shell dapat dikembangkan secara independen.

## 11. Status Implementasi

Tahapan:

```text
[ ] CLI architecture
[ ] CLI command parser
[ ] IPC protocol
[ ] IPC client
[ ] Mock IPC server
[ ] Shortcut manager
[ ] Shell IPC server
[ ] Nexus Action Registry
[ ] Global Shortcut
[ ] Hyprland integration
```

**Shell implementation tidak dimulai sebelum fondasi CLI + IPC selesai dan stabil.**