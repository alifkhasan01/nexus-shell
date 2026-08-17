pragma Singleton
import QtQuick
import Quickshell.Io

// Service singleton untuk state wallpaper global — dibaca oleh WallpaperPanel,
// WallpaperButton, dan WallpaperRandom agar semua sinkron.
QtObject {
    id: service

    // Path wallpaper yang sedang aktif
    property string currentWallpaper: ""
    
    // Timer untuk polling file cache
    property Timer pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.refresh()
    }

    // Process untuk baca file cache
    property Process readProc: Process {
        command: ["sh", "-c", "cat ~/.cache/wallpaper/current 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0 && p !== service.currentWallpaper) {
                    service.currentWallpaper = p
                }
            }
        }
    }

    // Refresh state dari file cache
    function refresh() {
        if (!readProc.running)
            readProc.running = true
    }

    // Set wallpaper baru dan update cache
    function setCurrent(path) {
        service.currentWallpaper = path
    }

    Component.onCompleted: {
        refresh()
    }
}
