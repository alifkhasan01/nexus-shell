pragma Singleton
import QtQuick
import Quickshell.Io

// Palette dinamis — ubah `currentTheme` untuk ganti tema seluruh shell.
// Tersedia dua tema:
//   "light" – Catppuccin Latte
//   "dark"  – Catppuccin Mocha (default)
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

    // ── Palette Latte (Light) ─────────────────────────────────────────────
    readonly property var _latte: ({
        base:     "#eff1f5",
        mantle:   "#e6e9ef",
        surface0: "#ccd0da",
        surface1: "#bcc0cc",
        surface2: "#acb0be",
        text:     "#4c4f69",
        subtext:  "#6c6f85",
        blue:     "#1e66f5",
        lavender: "#7287fd",
        green:    "#40a02b",
        yellow:   "#df8e1d",
        peach:    "#fe640b",
        red:      "#d20f39",
        mauve:    "#8839ef"
    })

    // ── Palette Mocha (Dark) ──────────────────────────────────────────────
    readonly property var _mocha: ({
        base:     "#1e1e2e",
        mantle:   "#181825",
        surface0: "#313244",
        surface1: "#45475a",
        surface2: "#585b70",
        text:     "#cdd6f4",
        subtext:  "#a6adc8",
        blue:     "#89b4fa",
        lavender: "#b4befe",
        green:    "#a6e3a1",
        yellow:   "#f9e2af",
        peach:    "#fab387",
        red:      "#f38ba8",
        mauve:    "#cba6f7"
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
