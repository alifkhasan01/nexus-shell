import QtQuick
import "../../" as Root

// Stopwatch widget mini di bar.
// Left click: start/pause
// Right click: reset
// Tampil hanya saat aktif (running atau paused dengan nilai > 0)
Item {
    id: root

    implicitWidth: visible ? swRow.implicitWidth + 18 : 0
    implicitHeight: 30

    property int elapsed: 0       // total detik
    property bool running: false

    // Tampilkan hanya saat ada nilai atau sedang jalan
    visible: running || elapsed > 0

    function _fmt(secs) {
        const h = Math.floor(secs / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const s = secs % 60
        const mm = String(m).padStart(2, "0")
        const ss = String(s).padStart(2, "0")
        return h > 0 ? (h + ":" + mm + ":" + ss) : (mm + ":" + ss)
    }

    Timer {
        id: ticker
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: root.elapsed++
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: swArea.containsMouse
               ? Root.Colors.surface1
               : (root.running ? Qt.rgba(Root.Colors.green.r, Root.Colors.green.g, Root.Colors.green.b, 0.15) : Root.Colors.surface0)
        Behavior on color { ColorAnimation { duration: 150 } }

        border.color: root.running ? Root.Colors.green : "transparent"
        border.width: root.running ? 1 : 0
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Row {
        id: swRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.running ? "󰏤" : "󰐊"
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 11
            color: root.running ? Root.Colors.green : Root.Colors.green
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root._fmt(root.elapsed)
            font.pixelSize: 12
            font.bold: true
            color: root.running ? Root.Colors.green : Root.Colors.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: swArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.running = false
                root.elapsed = 0
            } else {
                root.running = !root.running
            }
        }
    }
}
