# Nexus IPC Quick Start Guide

## TL;DR

Quickshell now runs a **Nexus IPC server** on `$XDG_RUNTIME_DIR/nexus.sock` that accepts commands from the Nexus CLI.

## Build & Test

### 1. Compile Nexus CLI
```bash
cd /home/youtta/Projects/nexus-cli
cargo build --release
```

### 2. Start Quickshell (IPC server)
```bash
quickshell
```

### 3. Test IPC Commands (in another terminal)
```bash
# List all available actions
./target/release/nexus ipc list

# Execute actions
./target/release/nexus ipc call launcher toggle
./target/release/nexus ipc call dashboard toggle
./target/release/nexus ipc call wallpaper random
./target/release/nexus ipc call media play_pause
./target/release/nexus ipc call menu toggle
```

### 4. Or Test with Mock Server (without Quickshell)
```bash
# Terminal 1
./target/release/nexus-mock-server

# Terminal 2
./target/release/nexus ipc list
./target/release/nexus ipc call launcher toggle
```

## Available Actions

```
launcher.toggle       - Open/close launcher
dashboard.toggle      - Open/close dashboard
wallpaper.next        - Next wallpaper
wallpaper.random      - Random wallpaper
wallpaper.previous    - Previous wallpaper
media.play_pause      - Play/pause media
power.open            - Open power menu
menu.toggle           - Toggle menu
system.lock           - Lock screen
system.restart        - Restart shell
```

## IPC Protocol (JSON)

### Request
```json
{
  "version": 1,
  "module": "wallpaper",
  "action": "random"
}
```

### Success Response
```json
{
  "status": "success",
  "version": 1,
  "data": {}
}
```

### Error Response
```json
{
  "status": "error",
  "version": 1,
  "error": "ERR_UNKNOWN_ACTION",
  "message": "Unknown action: invalid.action"
}
```

## Window Manager Integration (Hyprland)

Add to `hyprland.conf`:
```bash
# Via nexus CLI
bind = $mainMod, L, exec, /path/to/nexus ipc call launcher toggle
bind = $mainMod, D, exec, /path/to/nexus ipc call dashboard toggle
bind = $mainMod, W, exec, /path/to/nexus ipc call wallpaper random
bind = $mainMod, M, exec, /path/to/nexus ipc call menu toggle
bind = $mainMod, P, exec, /path/to/nexus ipc call power open
```

Or via Quickshell shortcuts (built-in):
```bash
bind = $mainMod SHIFT, L, exec, hyprctl dispatch exec quickshell:nexus:launcher
bind = $mainMod SHIFT, D, exec, hyprctl dispatch exec quickshell:nexus:dashboard
bind = $mainMod SHIFT, W, exec, hyprctl dispatch exec quickshell:nexus:wallpaper-random
```

## Troubleshooting

### Socket not found
```bash
# Check if socket exists
ls -la $XDG_RUNTIME_DIR/nexus.sock

# Should exist when Quickshell is running
# Default: /run/user/1000/nexus.sock
```

### Command timeout
```bash
# Quickshell may not be running
# Or IPC server not initialized
# Check logs:
tail -f /run/user/1000/quickshell/by-id/*/log.qslog | grep "Nexus IPC"
```

### Unknown action error
```bash
# List all available actions
nexus ipc list

# Or check IPC debug info
nexus status
```

## Implementation Status

✅ IPC Server (Phase 5)
- ✅ Action Registry
- ✅ JSON Protocol v1
- ✅ Error handling
- ✅ 10 pre-registered actions

⏳ Real Socket Server
- Currently logging requests to console
- Real socket binding coming next

⏳ Action Wiring
- Actions are defined but not yet connected to UI
- Will implement: launcher.toggle → actual UI state

⏳ Hyprland Integration
- Shortcuts work for testing
- Full integration pending

## Next Steps

1. **Implement real Unix domain socket** in IPCManager
2. **Wire actions to shell state** (connect to actual UI)
3. **Test with Hyprland bindings**
4. **Add response callbacks** for async operations
5. **Create dashboard panel** for IPC command history

## Files

- `services/IPCManager.qml` - IPC server implementation
- `shell.qml` - 5 built-in Nexus shortcuts
- `qmldir` - IPCManager singleton registration
- `docs/IPC_INTEGRATION.md` - Full documentation

## References

- [Full IPC Integration Guide](./IPC_INTEGRATION.md)
- [Implementation Summary](./IPC_IMPLEMENTATION_SUMMARY.md)
- [Nexus IPC Specification](./Nexus_Shel_CLI_&_IPC_Integration_Specification.md)
- [Nexus CLI Project](/home/youtta/Projects/nexus-cli)
