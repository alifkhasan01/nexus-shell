import QtQuick
import Quickshell.Io
import "../../" as Root

Item {
    id: root
    width: 30
    height: 26

    property string updateCheck: "yay -Qu 2>/dev/null || paru -Qu 2>/dev/null"
    property int pending: -1
    property var packages: []   // [{name, version}]

    // State panel
    property bool panelOpen: false
    signal togglePanel()

    // -1 = belum dicek, 0 = up to date, >0 = ada update
    readonly property bool checking: checkProc.running
    readonly property bool upToDate: pending === 0

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse
            ? Root.Colors.surface1
            : (mouseArea.pressed ? Root.Colors.surface2 : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.checking ? "󰑓" : "󰚰"
        font.pixelSize: 16
        color: {
            if (root.panelOpen)   return Root.Colors.blue
            if (root.checking)    return Root.Colors.subtext
            if (root.pending > 0) return Root.Colors.yellow
            if (root.upToDate)    return Root.Colors.green
            return Root.Colors.text
        }
        Behavior on color { ColorAnimation { duration: 150 } }

        RotationAnimation on rotation {
            running: root.checking
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            direction: RotationAnimation.Counterclockwise
        }
    }

    // Badge jumlah paket
    Rectangle {
        visible: root.pending > 0
        anchors.top: parent.top
        anchors.right: parent.right
        implicitWidth: Math.max(16, badgeTxt.implicitWidth + 6)
        height: 14
        radius: 7
        color: Root.Colors.red

        Text {
            id: badgeTxt
            anchors.centerIn: parent
            text: root.pending
            font.pixelSize: 9
            font.bold: true
            color: Root.Colors.base
        }
    }

    // Tooltip saat hover
    Rectangle {
        visible: mouseArea.containsMouse
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        implicitWidth: tooltipText.implicitWidth + 16
        height: 22
        radius: 6
        color: Root.Colors.surface2
        border.color: Root.Colors.surface1
        border.width: 1

        Text {
            id: tooltipText
            anchors.centerIn: parent
            font.pixelSize: 11
            color: Root.Colors.text
            text: {
                if (root.checking)    return "Memeriksa update..."
                if (root.pending < 0) return "Klik untuk cek update"
                if (root.pending > 0) return root.pending + " update tersedia"
                return "Sistem sudah up to date"
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }

    // Proses cek update — parse tiap baris "pkgname old -> new"
    Process {
        id: checkProc
        command: ["sh", "-c", root.updateCheck]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const pkgs = []
                for (const line of lines) {
                    const m = line.match(/^(\S+)\s+\S+\s+->\s+(\S+)/)
                    if (m) {
                        pkgs.push({ name: m[1], version: m[2] })
                    } else if (line.trim()) {
                        pkgs.push({ name: line.trim(), version: "" })
                    }
                }
                root.packages = pkgs
                root.pending = pkgs.length
            }
        }
    }

    // Cek update tiap jam, dan saat startup
    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
