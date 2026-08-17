pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Config minimal untuk Appearance.qml (diadaptasi dari illogical-impulse).
// Project ini tidak memakai config.json terpusat, jadi nilai-nilai dipetakan
// ke konfigurasi yang sudah ada (wallpaper.json, font default, dll).
Singleton {
    id: root

    property QtObject options: QtObject {
        property QtObject appearance: QtObject {
            property bool extraBackgroundTint: true
            property QtObject fonts: QtObject {
                property string main: "CaskaydiaCove Nerd Font"
                property string numbers: "CaskaydiaCove Nerd Font"
                property string title: "CaskaydiaCove Nerd Font"
                property string iconNerd: "CaskaydiaCove Nerd Font"
                property string monospace: "CaskaydiaCove Nerd Font"
                property string reading: "CaskaydiaCove Nerd Font"
                property string expressive: "CaskaydiaCove Nerd Font"
            }
            property QtObject transparency: QtObject {
                property bool enable: true
                property bool automatic: true
                property real backgroundTransparency: 0.11
                property real contentTransparency: 0.57
            }
        }
        property QtObject background: QtObject {
            property string wallpaperPath: root.currentWallpaper
            property string thumbnailPath: root.currentWallpaper
        }
        property QtObject bar: QtObject {
            property int cornerStyle: 0
            property bool verbose: false
        }
    }

    // ── Resolusi wallpaper aktif ───────────────────────────────────────────
    property string currentWallpaper: ""

    function setWallpaper(path) {
        if (path && path.length > 0) root.currentWallpaper = path
    }

    Component.onCompleted: {
        queryProc.command = ["sh", "-c",
            "(awww query 2>/dev/null || swww query 2>/dev/null) | sed -n 's/.*currently displaying: image: *//p' | head -1"
        ]
        queryProc.running = true
    }

    Process {
        id: queryProc
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0) {
                    root.setWallpaper(p)
                } else {
                    fallbackProc.running = true
                }
            }
        }
    }

    // Fallback: ambil gambar pertama dari wallpaper_dir (wallpaper.json)
    Process {
        id: fallbackProc
        command: ["sh", "-c",
            "DIR=$(sed -n 's/.*\"wallpaper_dir\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' " +
            "~/.config/quickshell/data/wallpaper.json 2>/dev/null | head -1); " +
            "DIR=${DIR:-$HOME/Pictures/Wallpapers}; DIR=${DIR/\\$HOME/$HOME}; " +
            "find \"$DIR\" -maxdepth 2 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | head -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0) root.setWallpaper(p)
            }
        }
    }
}