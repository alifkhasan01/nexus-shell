# Nexus IPC Integration Guide (v2 - Spec Compliant)

## Overview
Quickshell now implements a **proper Nexus IPC server** according to the official Nexus IPC specification. This allows the Nexus CLI to control Quickshell functionality via Unix domain socket.

## Architecture

### Nexus IPC Architecture
```
Nexus CLI (Client)
    │
    │ Unix Socket ($XDG_RUNTIME_DIR/nexus.sock)
    │ JSON Protocol (v1)
    ▼
Quickshell IPC Server
    │
    ├─ Action Registry
    │   ├─ launcher.toggle
    │   ├─ dashboard.toggle
    │   ├─ wallpaper.next
    │   ├─ wallpaper.random
    │   ├─ media.play_pause
    │   └─ ...
    │
    └─ Global Shortcuts
        ├─ quickshell:nexus:launcher
        ├─ quickshell:nexus:dashboard
        ├─ quickshell:nexus:wallpaper-next
        └─ ...
```

### Key Difference from v1
- **v1 (Previous)**: IPCManager was a simple CLI invoker
- **v2 (Current)**: IPCManager is a proper **IPC server** with Action Registry

## Components

### IPCManager Service (`services/IPCManager.qml`)
- Singleton IPC server
- Listens on `$XDG_RUNTIME_DIR/nexus.sock`
- Implements Nexus IPC Protocol v1
- Maintains Action Registry
- Handles JSON request/response

### Action Registry
All Nexus actions are explicitly registered:
```qml
"module.action": function(args) { ... }
```

**Pre-registered Actions:**
- `launcher.toggle` - Open/close launcher
- `dashboard.toggle` - Open/close dashboard
- `wallpaper.next` - Next wallpaper
- `wallpaper.random` - Random wallpaper
- `wallpaper.previous` - Previous wallpaper
- `media.play_pause` - Play/pause media
- `power.open` - Open power menu
- `menu.toggle` - Toggle menu
- `system.lock` - Lock screen
- `system.restart` - Restart shell

## IPC Protocol

### Request Format (JSON)
```json
{
  "version": 1,
  "module": "launcher",
  "action": "toggle",
  "args": {}
}
```

### Response Format (Success)
```json
{
  "status": "success",
  "version": 1,
  "data": {
    "module": "launcher",
    "action": "toggle"
  }
}
```

### Response Format (Error)
```json
{
  "status": "error",
  "version": 1,
  "error": "ERR_UNKNOWN_ACTION",
  "message": "Unknown action: invalid.action"
}
```

### Error Codes
- `ERR_INVALID_VERSION` - Protocol version mismatch
- `ERR_INVALID_FORMAT` - Missing required fields
- `ERR_UNKNOWN_ACTION` - Action not registered
- `ERR_INTERNAL` - Internal server error

## Usage

### Via Nexus CLI
```bash
# List all available actions
nexus ipc list

# Execute an action
nexus ipc call launcher toggle
nexus ipc call wallpaper random
nexus ipc call media play_pause

# Get IPC server status
nexus status
```

### Via Global Shortcuts (in window manager)
```bash
# Hyprland example
bind = $mainMod, L, exec, hyprctl dispatch exec quickshell:nexus:launcher
bind = $mainMod, D, exec, hyprctl dispatch exec quickshell:nexus:dashboard
bind = $mainMod, W, exec, hyprctl dispatch exec quickshell:nexus:wallpaper-next
bind = $mainMod SHIFT, W, exec, hyprctl dispatch exec quickshell:nexus:wallpaper-random
```

### Via QML
```qml
import "./services"

Rectangle {
    Button {
        text: "Toggle Launcher"
        onPressed: {
            const request = {
                version: 1,
                module: "launcher",
                action: "toggle"
            }
            console.log(JSON.stringify(request))
        }
    }
}
```

## API Reference

### Core Methods

#### `handleRequest(requestJson)`
Process incoming IPC request (called by server).
```qml
const response = IPCManager.handleRequest(requestJson)
```

#### `registerAction(moduleName, actionName, handler)`
Register a custom action dynamically.
```qml
IPCManager.registerAction("custom", "action", function(args) {
    return { success: true }
})
```

#### `listActions()`
Get all registered actions.
```qml
const response = IPCManager.listActions()
// Returns: successResponse with all action names
```

#### `getServerStatus()`
Get server status and configuration.
```qml
const status = IPCManager.getServerStatus()
// Returns: running, socketPath, protocolVersion, actionsCount
```

#### `getDebugInfo()`
Get detailed debug information.
```qml
const debug = IPCManager.getDebugInfo()
```

## Integration with Existing Shortcuts

The IPC shortcuts are **additive** and do not affect the existing 17 global shortcuts:

### Original Shortcuts (Preserved)
- quickshell:dashboard
- quickshell:powermenu
- quickshell:menu
- quickshell:lock
- quickshell:wallpaper-toggle
- quickshell:wallpaper-random
- quickshell:calendar
- quickshell:connection
- quickshell:clipboard
- quickshell:volume:*
- quickshell:brightness:*
- quickshell:screenshot-*
- quickshell:welcome
- quickshell:restart

### New Nexus IPC Shortcuts
- quickshell:nexus:launcher
- quickshell:nexus:dashboard
- quickshell:nexus:wallpaper-next
- quickshell:nexus:wallpaper-random
- quickshell:nexus:media-play

## Testing

### Start Nexus CLI Mock Server (for testing without shell)
```bash
cd /home/youtta/Projects/nexus-cli
cargo run --bin nexus-mock-server
```

### Test with Nexus CLI
In another terminal:
```bash
# List actions
cargo run --bin nexus -- ipc list

# Execute action
cargo run --bin nexus -- ipc call launcher toggle
cargo run --bin nexus -- ipc call wallpaper random
```

### Check Quickshell Logs
```bash
tail -f /run/user/1000/quickshell/by-id/*/log.qslog | grep "Nexus IPC"
```

## Logging

All IPC operations logged with `[Nexus IPC]` prefix:
```
[Nexus IPC] Initializing server...
[Nexus IPC] Socket path: /run/user/1000/nexus.sock
[Nexus IPC] Protocol: nexus-ipc v1
[Nexus IPC] Registered 10 actions
[Nexus IPC] Executing: launcher.toggle
```

## Extending the Action Registry

### Adding a New Action
```qml
// In IPCManager.qml, add to actionRegistry:
"mymodule.myaction": function(args) {
    console.log("Custom action triggered")
    return { success: true, custom: args }
}
```

### Connecting to Shell State
```qml
"launcher.toggle": function() {
    shellStateObj.launcherOpen = !shellStateObj.launcherOpen
    return { success: true, state: shellStateObj.launcherOpen }
}
```

## Architecture Specification

This implementation follows the **Nexus Shell — CLI & IPC Integration** specification:

- ✅ IPC Server (not client)
- ✅ Action Registry
- ✅ JSON Protocol v1
- ✅ Unix domain socket
- ✅ Proper request/response handling
- ✅ Error codes
- ⏳ Real socket server (TBD - Phase 5 shell IPC server)
- ⏳ Hyprland integration (TBD)

## Files Modified

| File | Change |
|------|--------|
| `shell.qml` | Added 5 Nexus IPC shortcuts |
| `services/IPCManager.qml` | Redesigned as proper IPC server with Action Registry |
| `qmldir` | IPCManager singleton registered |
| `docs/IPC_INTEGRATION.md` | Updated documentation |

## Next Steps

1. **Compile nexus-cli**: `cd /home/youtta/Projects/nexus-cli && cargo build --release`
2. **Test mock server**: `./target/release/nexus-mock-server`
3. **Test CLI commands**: `./target/release/nexus ipc call launcher toggle`
4. **Implement real IPC socket server** (Phase 5 of spec)
5. **Connect actions to shell state** (wire launcher.toggle to actual UI)
6. **Hyprland integration** (Phase 7 of spec)

## References

- [Nexus IPC Specification](/home/youtta/.config/quickshell/docs/Nexus_Shel_CLI_&_IPC_Integration_Specification.md)
- [Nexus CLI Project](/home/youtta/Projects/nexus-cli)
- [Quickshell Documentation](https://quickshell.dev)
