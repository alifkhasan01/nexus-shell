pragma Singleton
import QtQuick
import Quickshell.Io

// Palette dinamis — ubah `currentTheme` untuk ganti tema seluruh shell.
// Saat berubah, tema juga disinkronkan ke app lain (foot, walker, btop,
// GTK 3/4, hyprland) lewat matugen — lihat ~/.config/matugen/config.toml.
// Nilai yang tersedia:
//   "catppuccin-latte"     – Catppuccin Latte (Light)
//   "catppuccin-frappe"    – Catppuccin Frappé
//   "catppuccin-macchiato" – Catppuccin Macchiato
//   "catppuccin-mocha"     – Catppuccin Mocha (default)
QtObject {
    id: root

    property string currentTheme: "catppuccin-mocha"

    property bool _loaded: false
    onCurrentThemeChanged: {
        if (!_loaded) return

        // Simpan pilihan tema ke disk
        saveProc.command = ["sh", "-c",
            "echo '" + currentTheme + "' > ~/.config/quickshell/theme"
        ]
        saveProc.running = true

        // Peta hex source color + mode per flavor Catppuccin.
        // Hex diambil dari warna "base" masing-masing flavor — dipakai matugen
        // sebagai seed untuk generate seluruh palette Material You.
        const baseColors = {
            "catppuccin-latte":     { hex: "eff1f5", mode: "light" },
            "catppuccin-frappe":    { hex: "303446", mode: "dark"  },
            "catppuccin-macchiato": { hex: "24273a", mode: "dark"  },
            "catppuccin-mocha":     { hex: "1e1e2e", mode: "dark"  }
        }
        const c = baseColors[currentTheme] ?? baseColors["catppuccin-mocha"]

        // Jalankan matugen — akan generate semua output template sekaligus
        // dan menjalankan post_hook tiap app (SIGUSR2 foot, USR2 btop, dll).
        applyProc.command = ["matugen", "color", "hex", "#" + c.hex, "-m", c.mode]
        applyProc.running = true

        // Toggle GTK dark/light via gsettings — pakai theme system yang sudah ada,
        // tidak perlu generate warna custom. Latte = light, sisanya = dark.
        const isDark = (currentTheme !== "catppuccin-latte")
        gtkProc.command = ["sh", "-c",
            "gsettings set org.gnome.desktop.interface color-scheme '"
            + (isDark ? "prefer-dark" : "prefer-light") + "' ; "
            + "gsettings set org.gnome.desktop.interface gtk-theme '"
            + (isDark ? "adw-gtk3-dark" : "adw-gtk3") + "'"
        ]
        gtkProc.running = true
    }

    Component.onCompleted: loadProc.running = true

    property Process loadProc: Process {
        command: ["sh", "-c",
            "cat ~/.config/quickshell/theme 2>/dev/null || echo catppuccin-mocha"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                const valid = ["catppuccin-latte", "catppuccin-frappe",
                               "catppuccin-macchiato", "catppuccin-mocha"]
                if (valid.includes(v)) root.currentTheme = v
                root._loaded = true
            }
        }
    }

    property Process saveProc: Process {
        onRunningChanged: if (!running) saveProc.running = false
    }
    property Process applyProc: Process {
        // Log error jika matugen gagal
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("[Colors] matugen stderr:", text.trim())
            }
        }
    }
    property Process gtkProc: Process {}

    // ── Lookup tables per flavor ─────────────────────────────────────────
    // Referensi: https://github.com/catppuccin/catppuccin

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

    readonly property var _frappe: ({
        base:     "#303446",
        mantle:   "#292c3c",
        surface0: "#414559",
        surface1: "#51576d",
        surface2: "#626880",
        text:     "#c6d0f5",
        subtext:  "#a5adce",
        blue:     "#8caaee",
        lavender: "#babbf1",
        green:    "#a6d189",
        yellow:   "#e5c890",
        peach:    "#ef9f76",
        red:      "#e78284",
        mauve:    "#ca9ee6"
    })

    readonly property var _macchiato: ({
        base:     "#24273a",
        mantle:   "#1e2030",
        surface0: "#363a4f",
        surface1: "#494d64",
        surface2: "#5b6078",
        text:     "#cad3f5",
        subtext:  "#a5adcb",
        blue:     "#8aadf4",
        lavender: "#b7bdf8",
        green:    "#a6da95",
        yellow:   "#eed49f",
        peach:    "#f5a97f",
        red:      "#ed8796",
        mauve:    "#c6a0f6"
    })

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

    readonly property var _p: {
        switch (currentTheme) {
            case "catppuccin-latte":     return _latte
            case "catppuccin-frappe":    return _frappe
            case "catppuccin-macchiato": return _macchiato
            default:                     return _mocha
        }
    }

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
        "catppuccin-latte":     "Latte",
        "catppuccin-frappe":    "Frappé",
        "catppuccin-macchiato": "Macchiato",
        "catppuccin-mocha":     "Mocha"
    })

    readonly property var themeAccents: ({
        "catppuccin-latte":     "#1e66f5",
        "catppuccin-frappe":    "#8caaee",
        "catppuccin-macchiato": "#8aadf4",
        "catppuccin-mocha":     "#89b4fa"
    })
}
