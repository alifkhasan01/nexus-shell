import QtQuick
import Quickshell.Io
import "../" as Root

// Kontrol brightness via brightnessctl — baca dan set pakai tool yang sama
// supaya nilai selalu konsisten.
Item {
    id: root
    implicitWidth: label.implicitWidth
    width: implicitWidth
    height: 20

    property int percent: 0

    // ── Baca brightness saat ini via brightnessctl ────────────────────────
    Process {
        id: getProcess
        command: ["brightnessctl", "--device=amdgpu_bl1", "info"]
        stdout: SplitParser {
            onRead: data => {
                // Output brightnessctl: "Current brightness: 2 (0%)"
                const match = data.match(/\((\d+)%\)/)
                if (match) root.percent = parseInt(match[1])
            }
        }
    }

    // Poll setiap 2 detik — cukup responsif tanpa membebani CPU
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getProcess.running = true
    }

    // ── Label ─────────────────────────────────────────────────────────────
    Text {
        id: label
        anchors.centerIn: parent
        color: Root.Colors.text
        font.pixelSize: 14
        text: {
            const p = root.percent
            const icon = p >= 67 ? "󰃞" : (p >= 34 ? "󰃝" : "󰃜")
            return icon + "  " + p + "%"
        }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Scroll untuk ubah brightness ──────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            const step = 5
            const dir = wheel.angleDelta.y > 0 ? 1 : -1

            // Optimistic update
            root.percent = Math.max(0, Math.min(100, root.percent + dir * step))

            const arg = wheel.angleDelta.y > 0 ? (step + "%+") : (step + "%-")
            setProcess.command = ["brightnessctl", "--device=amdgpu_bl1", "set", arg]
            setProcess.running = true
        }
    }

    // Setelah set selesai, baca ulang nilai aktual
    Process {
        id: setProcess
        onExited: getProcess.running = true
    }
}
