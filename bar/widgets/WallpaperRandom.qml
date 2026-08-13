import QtQuick
import Quickshell.Io
import "../../services" as Services

// Handler wallpaper acak yang SELALU aktif di background.
// Tidak bergantung pada WallpaperPanel (yang load-nya lazy), sehingga
// bisa dipanggil kapan saja lewat GlobalShortcut `quickshell:wallpaper-random`
// maupun klik kanan tombol wallpaper di Bar — tanpa perlu membuka panel.
Item {
    id: root

    property string wallpaperDir:        ""
    property string transitionType:      "wipe"
    property real   transitionDuration:  1.0
    property int    transitionFps:       60
    property var    wallpapers:          []
    property bool   pendingRandom:       false

    Component.onCompleted: loadConfigProc.running = true

    // ── Config ────────────────────────────────────────────────────────────
    Process {
        id: loadConfigProc
        command: ["sh", "-c", "cat " + Services.PathService.configDir + "/wallpaper.json 2>/dev/null || cat ~/.config/wallpicker/config.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text)
                    // Expand $HOME jika ada
                    let wallDir = c.wallpaper_dir || (Services.PathService.wallpapersDir)
                    wallDir = wallDir.replace("$HOME", Services.PathService.homeDir)
                    root.wallpaperDir       = wallDir
                    root.transitionType     = c.transition_type       || "wipe"
                    root.transitionDuration = c.transition_duration   || 1.0
                    root.transitionFps      = c.transition_fps        || 60
                } catch(e) {
                    root.wallpaperDir = Services.PathService.wallpapersDir
                }
                root.scanWallpapers()
            }
        }
    }

    // ── Scan folder wallpaper ─────────────────────────────────────────────
    function scanWallpapers() {
        if (root.wallpaperDir === "") return
        scanProc.command = ["sh", "-c",
            "find '" + root.wallpaperDir.replace(/'/g, "'\\''") + "'" +
            " -maxdepth 3 -type f" +
            " \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png'" +
            "    -o -iname '*.webp' -o -iname '*.bmp' \\)" +
            " | sort"]
        scanProc.running = true
    }

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                root.wallpapers = lines
                if (root.pendingRandom) {
                    root.pendingRandom = false
                    root.doRandom()
                }
            }
        }
    }

    // ── Random ────────────────────────────────────────────────────────────
    function pickRandom() {
        if (root.wallpapers.length === 0) {
            if (root.wallpaperDir === "") return
            // Belum di-scan → scan dulu, lalu set acak
            root.pendingRandom = true
            root.scanWallpapers()
            return
        }
        root.doRandom()
    }

    function doRandom() {
        if (root.wallpapers.length === 0) return
        const idx  = Math.floor(Math.random() * root.wallpapers.length)
        const path = root.wallpapers[idx]
        const esc  = path.replace(/'/g, "'\\''")
        setProc.command = ["sh", "-c",
            "(awww query >/dev/null 2>&1 || (awww-daemon >/dev/null 2>&1 & sleep 0.4)) && " +
            "awww img '" + esc + "'" +
            " --transition-type "     + root.transitionType +
            " --transition-duration " + root.transitionDuration +
            " --transition-fps "      + root.transitionFps]
        setProc.running = true
    }

    Process { id: setProc }
}