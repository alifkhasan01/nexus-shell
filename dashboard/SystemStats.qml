import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

RowLayout {
    id: root
    spacing: 14

    property string ramText:  "—"
    property string diskText: "—"
    property string uptime:   "—"

    // RAM
    RowLayout {
        spacing: 5
        Text { text: "󰍛"; color: Root.Colors.green;  font.pixelSize: 13 }
        Text { text: root.ramText;  color: Root.Colors.text; font.pixelSize: 12 }
    }

    // Disk (root partition)
    RowLayout {
        spacing: 5
        Text { text: "󰋊"; color: Root.Colors.yellow; font.pixelSize: 13 }
        Text { text: root.diskText; color: Root.Colors.text; font.pixelSize: 12 }
    }

    // Uptime
    RowLayout {
        spacing: 5
        Text { text: "󰅐"; color: Root.Colors.peach;  font.pixelSize: 13 }
        Text { text: root.uptime;   color: Root.Colors.text; font.pixelSize: 12 }
    }

    // ── Proses ──────────────────────────────────────────────────────────

    Process {
        id: ramProc
        command: ["sh", "-c",
            "free -b | awk '/^Mem:/ {used=$2-$7; printf \"%s / %s\", int(used/1073741824*10)/10\"G\", int($2/1073741824*10)/10\"G\"}'"]
        stdout: StdioCollector {
            onStreamFinished: root.ramText = text.trim()
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c",
            "df -h / | awk 'NR==2 {print $3\"/\"$2\" (\"$5\")\"}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.diskText = text.trim()
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
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            ramProc.running  = true
            diskProc.running = true
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
