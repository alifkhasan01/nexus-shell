import QtQml
import QtQuick
import Quickshell.Hyprland._GlobalShortcuts

// Semua global shortcuts definitions
// Dipisah dari shell.qml untuk maintainability
QtObject {
    id: globalShortcuts

    // Injected properties
    property var shellState: null
    property var wpRandom: null
    property var osdRef: null
    property var lockFn: null
    property var volumeControl: null
    property var brightnessControl: null

    // ── Panel Toggles ──────────────────────────────────────────────────
    GlobalShortcut {
        appid: "quickshell"
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: {
            if (shellState) shellState.dashboardOpen = !shellState.dashboardOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "powermenu"
        description: "Toggle power menu"
        onPressed: {
            if (shellState) shellState.powerMenuOpen = !shellState.powerMenuOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "menu"
        description: "Toggle menu panel"
        onPressed: {
            if (shellState) shellState.menuOpen = !shellState.menuOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        description: "Lock screen"
        onPressed: {
            if (lockFn) lockFn()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-toggle"
        description: "Toggle wallpaper panel"
        onPressed: {
            if (shellState) shellState.wallpaperPanelOpen = !shellState.wallpaperPanelOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-random"
        description: "Ganti wallpaper acak"
        onPressed: {
            if (wpRandom) wpRandom.pickRandom()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "calendar"
        description: "Toggle calendar panel"
        onPressed: {
            if (shellState) shellState.calendarOpen = !shellState.calendarOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "connection"
        description: "Toggle connection panel (Network/Bluetooth)"
        onPressed: {
            if (shellState) shellState.connectionOpen = !shellState.connectionOpen
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        description: "Toggle clipboard panel"
        onPressed: {
            if (shellState) shellState.clipboardOpen = !shellState.clipboardOpen
        }
    }

    // ── Volume Controls ────────────────────────────────────────────────
    GlobalShortcut {
        appid: "quickshell"
        name: "volume:up"
        description: "Volume up"
        onPressed: {
            if (volumeControl) volumeControl.volumeUp()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volume:down"
        description: "Volume down"
        onPressed: {
            if (volumeControl) volumeControl.volumeDown()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volume:mute"
        description: "Toggle mute"
        onPressed: {
            if (volumeControl) volumeControl.toggleMute()
        }
    }

    // ── Brightness Controls ────────────────────────────────────────────
    GlobalShortcut {
        appid: "quickshell"
        name: "brightness:up"
        description: "Brightness up"
        onPressed: {
            if (brightnessControl) brightnessControl.brightnessUp()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "brightness:down"
        description: "Brightness down"
        onPressed: {
            if (brightnessControl) brightnessControl.brightnessDown()
        }
    }
}
