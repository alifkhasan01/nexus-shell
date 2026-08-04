import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../" as Root

ColumnLayout {
    id: root
    spacing: 10

    // ── Audio sink aktif ──────────────────────────────────────────────────
    property var defaultSink: Pipewire.defaultAudioSink
    property var btSink: {
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isSink || n.isStream) continue
            const pr = n.properties || {}
            if (pr["device.api"] === "bluez5" || (n.name || "").startsWith("bluez_output."))
                return n
        }
        void Pipewire.defaultAudioSink
        return null
    }
    property var activeSink: (btSink && defaultSink && btSink.id === defaultSink.id)
                             ? btSink : defaultSink

    // Daftar semua hardware sink (untuk selector)
    // (dipindahkan ke VolumePanel.qml)

    PwObjectTracker {
        objects: {
            const arr = []
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && n.isSink && !n.isStream && n.audio) arr.push(n)
            }
            if (root.defaultSink) arr.push(root.defaultSink)
            return arr
        }
    }

    // ── Sound ─────────────────────────────────────────────────────────────
    SectionLabel { text: "Sound" }

    SliderRow {
        Layout.fillWidth: true
        icon: {
            if (!root.activeSink?.audio || root.activeSink.audio.muted) return "󰸈"
            const pct = Math.round((root.activeSink.audio.volume ?? 0) * 100)
            return pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
        }
        value: root.activeSink?.audio ? (root.activeSink.audio.volume ?? 0) : 0
        onMoved: v => { if (root.activeSink?.audio) root.activeSink.audio.volume = v }
    }

    // Slider BT terpisah — hanya muncul kalau BT bukan default sink
    SliderRow {
        Layout.fillWidth: true
        visible: root.btSink != null && root.btSink.id !== (root.defaultSink?.id ?? -1)
        icon: "󰋋"
        value: root.btSink?.audio ? (root.btSink.audio.volume ?? 0) : 0
        onMoved: v => { if (root.btSink?.audio) root.btSink.audio.volume = v }
    }

    // ── Display ───────────────────────────────────────────────────────────
    SectionLabel { text: "Display" }

    SliderRow {
        Layout.fillWidth: true
        icon: "󰃞"
        onMoved: v => {
            setBright.command = ["brightnessctl", "set", Math.round(v * 100) + "%"]
            setBright.running = true
        }

        Process { id: setBright }
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
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
