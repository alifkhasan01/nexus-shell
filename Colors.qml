pragma Singleton
import QtQuick
import Quickshell.Io

// Palette dinamis — ubah `currentTheme` untuk ganti tema seluruh shell.
// Saat berubah, tema juga disinkronkan ke app lain (GTK, Qt, foot, hyprland,
// hyprlock, gsettings) lewat matugen — lihat ~/.config/matugen/config.toml.
// Nilai yang tersedia:
//   "catppuccin-mocha"   – Catppuccin Dark (default)
//   "catppuccin-latte"   – Catppuccin Light
QtObject {
    id: root

    property string currentTheme: "catppuccin-mocha"

    // Tulis ke file saat tema berubah (skip pada startup sebelum loaded)
    property bool _loaded: false
    onCurrentThemeChanged: {
        if (!_loaded) return
        saveProc.command = ["sh", "-c",
            "echo '" + currentTheme + "' > ~/.config/quickshell/theme"
        ]
        saveProc.running = true

        // Sinkronkan tema ke app lain lewat matugen.
        // Mocha = Catppuccin-Dark, Latte = Catppuccin-Light.
        applyProc.command = currentTheme === "catppuccin-mocha"
            ? ["matugen", "color", "hex", "1e1e2e", "-m", "dark"]
            : ["matugen", "color", "hex", "eff1f5", "-m", "light"]
        applyProc.running = true
    }

    Component.onCompleted: loadProc.running = true

    property Process loadProc: Process {
        command: ["sh", "-c",
            "cat ~/.config/quickshell/theme 2>/dev/null || echo catppuccin-mocha"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                if (["catppuccin-mocha", "catppuccin-latte"].includes(v))
                    root.currentTheme = v
                root._loaded = true
            }
        }
    }

    property Process saveProc:  Process {}
    property Process applyProc: Process {}

    // ── Lookup tables per tema ───────────────────────────────────────────

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

    readonly property var _p: currentTheme === "catppuccin-latte" ? _latte : _mocha

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

    // ── Metadata ─────────────────────────────────────────────────────────

    readonly property var themeLabels: ({
        "catppuccin-mocha": "Dark",
        "catppuccin-latte": "Light"
    })

    readonly property var themeAccents: ({
        "catppuccin-mocha": "#89b4fa",
        "catppuccin-latte": "#1e66f5"
    })
}
