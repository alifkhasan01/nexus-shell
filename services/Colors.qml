pragma Singleton
import QtQuick
import Quickshell.Io

// Palette dinamis — ubah `currentTheme` untuk ganti tema seluruh shell.
// Tersedia dua tema:
//   "light" – Ayu Light
//   "dark"  – Ayu Dark (default)
QtObject {
    id: root

    property string currentTheme: "dark"

    property bool _loaded: false
    onCurrentThemeChanged: {
        if (!_loaded) return

        // Simpan pilihan tema ke disk
        saveProc.command = ["sh", "-c",
            "echo '" + currentTheme + "' > ~/.config/quickshell/theme"
        ]
        saveProc.running = true
    }

    Component.onCompleted: loadProc.running = true

    property Process loadProc: Process {
        command: ["sh", "-c",
            "cat ~/.config/quickshell/theme 2>/dev/null || echo dark"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                // Mapping nilai lama → baru agar file theme yang sudah ada tetap bisa dibaca
                const legacy = {
                    "catppuccin-latte":     "light",
                    "catppuccin-frappe":    "dark",
                    "catppuccin-macchiato": "dark",
                    "catppuccin-mocha":     "dark"
                }
                const mapped = legacy[v] ?? (v === "light" ? "light" : "dark")
                root.currentTheme = mapped
                root._loaded = true
            }
        }
    }

    property Process saveProc: Process {
        onRunningChanged: if (!running) saveProc.running = false
    }

    // ── Palette Ayu Light ─────────────────────────────────────────────────
    readonly property var _latte: ({
        base:     "#fafafa",
        mantle:   "#f3f4f5",
        surface0: "#e7e8e9",
        surface1: "#d9dadb",
        surface2: "#abb0b6",
        text:     "#575f66",
        subtext:  "#8a9199",
        blue:     "#36a3d9",
        lavender: "#a37acc",
        green:    "#86b300",
        yellow:   "#f29718",
        peach:    "#fa8d3e",
        red:      "#f07171",
        mauve:    "#a37acc"
    })

    // ── Palette Ayu Dark ──────────────────────────────────────────────────
    readonly property var _mocha: ({
        base:     "#0d1017",
        mantle:   "#0a0e14",
        surface0: "#131721",
        surface1: "#1c2333",
        surface2: "#2d3347",
        text:     "#bfbdb6",
        subtext:  "#707a8c",
        blue:     "#59c2ff",
        lavender: "#d2a6ff",
        green:    "#aad94c",
        yellow:   "#e6b450",
        peach:    "#ff8f40",
        red:      "#f07178",
        mauve:    "#d2a6ff"
    })

    readonly property var _p: currentTheme === "light" ? _latte : _mocha

    // ── Warna yang diexpose ───────────────────────────────────────────────

    readonly property color base:     _p.base
    readonly property color mantle:   _p.mantle
    readonly property color surface0: _p.surface0
    readonly property color surface1: _p.surface1
    readonly property color surface2: _p.surface2
    readonly property color text:     _p.text
    readonly property color subtext:  _p.subtext
    readonly property color blue:     _p.blue
    readonly property color lavender: _p.lavender
    readonly property color green:    _p.green
    readonly property color yellow:   _p.yellow
    readonly property color peach:    _p.peach
    readonly property color red:      _p.red
    readonly property color mauve:    _p.mauve

    // ── Metadata ──────────────────────────────────────────────────────────

    readonly property bool isDark: currentTheme !== "light"
}
