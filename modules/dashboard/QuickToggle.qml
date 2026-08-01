import QtQuick
import Quickshell.Io
import "../../" as Root

// Toggle pill generik: jalankan checkCommand secara berkala buat tau status
// on/off (dianggap ON kalau stdout mengandung checkMatch), lalu jalankan
// onCommand / offCommand pas diklik.
Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string checkCommand: ""
    property string checkMatch: "yes"
    property string onCommand: ""
    property string offCommand: ""
    property bool active: false

    width: 84
    height: 60
    radius: 14
    color: active ? Root.Colors.blue : Root.Colors.surface0

    Behavior on color { ColorAnimation { duration: 150 } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: 18
            color: root.active ? Root.Colors.base : Root.Colors.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: 11
            color: root.active ? Root.Colors.base : Root.Colors.subtext
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleProc.command = ["sh", "-c", root.active ? root.offCommand : root.onCommand]
            toggleProc.running = true
            // asumsi optimis, dikoreksi lagi oleh poll berikutnya
            root.active = !root.active
        }
    }

    Process { id: toggleProc }

    Process {
        id: checkProc
        command: ["sh", "-c", root.checkCommand]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.includes(root.checkMatch)
        }
    }

    Timer {
        interval: 4000
        running: root.checkCommand !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
