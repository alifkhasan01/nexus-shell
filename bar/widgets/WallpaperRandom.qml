import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

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
        command: ["sh", "-c", "cat ~/.config/quickshell/data/wallpaper.json 2>/dev/null || cat ~/.config/wallpicker/config.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text)
                    // Expand $HOME jika ada
                    let wallDir = c.wallpaper_dir || (root._home() + "/Pictures/Wallpapers")
                    wallDir = wallDir.replace(/^\$HOME/, root._home())
                    root.wallpaperDir       = wallDir
                    root.transitionType     = c.transition_type       || "wipe"
                    root.transitionDuration = c.transition_duration   || 1.0
                    root.transitionFps      = c.transition_fps        || 60
                } catch(e) {
                    root.wallpaperDir = root._home() + "/Pictures/Wallpapers"
                }
                // Selalu scan setelah config load; kalau pendingRandom sudah
                // di-set sebelum config selesai, scanWallpapers() akan menjalankan
                // doRandom() via pendingRandom setelah scan selesai.
                root.scanWallpapers()
            }
        }
    }

    function _home() { return Quickshell.env("HOME") || "" }

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
    property string lastSetPath: ""  // untuk tracking wallpaper yang baru di-set
    
    function pickRandom() {
        if (root.wallpapers.length === 0) {
            // Config belum selesai load atau wallpaper belum di-scan
            if (root.wallpaperDir === "") {
                // Tandai pending — akan diproses setelah config selesai load
                root.pendingRandom = true
                if (!loadConfigProc.running)
                    loadConfigProc.running = true
                return
            }
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
        root.lastSetPath = path  // simpan untuk update service setelah sukses
        const esc  = path.replace(/'/g, "'\\''")
        setProc.command = ["sh", "-c",
            "(awww query >/dev/null 2>&1 || (awww-daemon >/dev/null 2>&1 & sleep 0.4)) && " +
            "awww img '" + esc + "'" +
            " --transition-type "     + root.transitionType +
            " --transition-duration " + root.transitionDuration +
            " --transition-fps "      + root.transitionFps +
            " && mkdir -p ~/.cache/wallpaper" +
            " && printf '%s' '" + esc + "' > ~/.cache/wallpaper/current" +
            " && ln -sf '"     + esc + "' ~/.cache/wallpaper/hyprlock-bg" +
            " && echo ok"]
        setProc.running = true
    }

    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "ok" && root.lastSetPath !== "") {
                    // Update WallpaperService agar komponen lain langsung sinkron
                    WallpaperService.setCurrent(root.lastSetPath)
                    // Force refresh untuk memastikan
                    WallpaperService.refresh()
                }
            }
        }
    }
}