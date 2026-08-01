import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../" as Root

RowLayout {
    id: root
    spacing: 20

    property real cpuPercent: 0
    property real ramPercent: 0
    property string uptime: ""

    function statItem(icon, value) {
        return icon + "  " + value
    }

    RowLayout {
        spacing: 6
        Text { text: "󰻠"; color: Root.Colors.mauve; font.pixelSize: 14 }
        Text { text: Math.round(root.cpuPercent) + "%"; color: Root.Colors.text; font.pixelSize: 13 }
    }
    RowLayout {
        spacing: 6
        Text { text: "󰍛"; color: Root.Colors.green; font.pixelSize: 14 }
        Text { text: Math.round(root.ramPercent) + "%"; color: Root.Colors.text; font.pixelSize: 13 }
    }
    RowLayout {
        spacing: 6
        Text { text: "󰅐"; color: Root.Colors.peach; font.pixelSize: 14 }
        Text { text: root.uptime; color: Root.Colors.text; font.pixelSize: 13 }
    }

    // CPU: dihitung dari delta /proc/stat antar dua polling
    property var lastCpu: null

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).slice(1).map(Number)
                const idle = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)
                if (root.lastCpu) {
                    const dIdle = idle - root.lastCpu.idle
                    const dTotal = total - root.lastCpu.total
                    if (dTotal > 0) root.cpuPercent = 100 * (1 - dIdle / dTotal)
                }
                root.lastCpu = { idle, total }
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "free -b | awk '/^Mem:/ {printf \"%.4f\", ($2-$7)/$2*100}'"]
        stdout: StdioCollector {
            onStreamFinished: root.ramPercent = parseFloat(text) || 0
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: root.uptime = text.trim()
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }
}
