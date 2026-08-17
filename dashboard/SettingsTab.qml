import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

ColumnLayout {
    id: root
    spacing: 10

    // ── Network ───────────────────────────────────────────────────────────
    // Menampilkan kecepatan download/upload, sumber data dari SystemInfo
    // (baca /proc/net/dev tiap 2 detik) — bukan dari widget bar.
    property string netRx: "0 KB/s"
    property string netTx: "0 KB/s"
    property var _netPrev: null      // {rx, tx, time}

    Process {
        id: netSpeedProc
        command: ["sh", "-c",
            "awk '/^[[:space:]]*(e|w)/{gsub(/:/,\"\"); print $1,$2,$10}' /proc/net/dev | head -2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now()
                let totalRx = 0, totalTx = 0
                const lines = text.trim().split("\n").filter(l => l.trim() !== "")
                lines.forEach(l => {
                    const p = l.trim().split(/\s+/)
                    if (p.length >= 3) {
                        totalRx += parseInt(p[1]) || 0
                        totalTx += parseInt(p[2]) || 0
                    }
                })

                if (root._netPrev !== null) {
                    const dt = (now - root._netPrev.time) / 1000  // detik
                    if (dt > 0) {
                        const rx = (totalRx - root._netPrev.rx) / dt
                        const tx = (totalTx - root._netPrev.tx) / dt
                        root.netRx = root._fmtSpeed(rx)
                        root.netTx = root._fmtSpeed(tx)
                    }
                }
                root._netPrev = { rx: totalRx, tx: totalTx, time: now }
            }
        }
    }

    function _fmtSpeed(bps) {
        if (bps < 1024)        return Math.round(bps) + " B/s"
        if (bps < 1048576)     return (bps / 1024).toFixed(1) + " KB/s"
        return (bps / 1048576).toFixed(1) + " MB/s"
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netSpeedProc.running = true
    }

    SectionLabel { text: "Network" }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "󰤨"
            font.pixelSize: 16
            color: Root.Colors.blue
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "↓ " + root.netRx
            font.pixelSize: 11; font.weight: Font.SemiBold
            color: Root.Colors.green
        }

        Text {
            text: "  ↑ " + root.netTx
            font.pixelSize: 11; font.weight: Font.SemiBold
            color: Root.Colors.peach
        }
    }

    // ── Display ───────────────────────────────────────────────────────────
    SectionLabel { text: "Display" }

    SliderRow {
        id: brightSlider
        Layout.fillWidth: true
        icon: {
            const pct = value * 100
            return pct >= 67 ? "󰃠" : (pct >= 34 ? "󰃝" : "󰃞")
        }
        // Bind ke BrightnessService (satu sumber dengan Bar) — instan bereaksi
        // terhadap perubahan eksternal (hotkey/controll-center, dll).
        value: Root.BrightnessService.fraction

        onMoved: v => Root.BrightnessService.setPercent(v)
    }

    // ── Theme ─────────────────────────────────────────────────────────────
    SectionLabel { text: "Theme" }

    ThemeSelector { Layout.fillWidth: true }

    Item { height: 2 }

    // ── Section label helper ──────────────────────────────────────────────
    component SectionLabel: Text {
        Layout.fillWidth: true
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 0.6
        color: Root.Colors.subtext
        opacity: 0.75
        leftPadding: 2
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
    }
}
