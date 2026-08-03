import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property var command: []
    property color iconColor: Root.Colors.subtext
    property bool highlighted: false
    // Teks notifikasi — isi dari luar untuk item yang perlu notif sebelum aksi
    property string notifyTitle: ""
    property string notifyBody:  ""

    signal triggered()

    width: parent ? parent.width : 160
    height: 36
    radius: 8
    color: highlighted
        ? Root.Colors.surface2
        : (ma.containsMouse ? Root.Colors.surface1 : "transparent")
    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            text: root.icon
            font.pixelSize: 15
            color: (highlighted || ma.containsMouse) ? Root.Colors.text : root.iconColor
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Text {
            text: root.label
            font.pixelSize: 13
            color: (highlighted || ma.containsMouse) ? Root.Colors.text : Root.Colors.subtext
            Behavior on color { ColorAnimation { duration: 100 } }
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root._doActivate()
    }

    Process { id: proc;        command: root.command }
    Process { id: notifyProc;  onExited: proc.running = true }

    function _doActivate() {
        root.triggered()
        if (root.command.length === 0) return
        if (root.notifyTitle !== "") {
            notifyProc.command = ["notify-send",
                "-a", "Power",
                "-i", "system-shutdown-symbolic",
                "-t", "3000",
                "-u", "normal",
                root.notifyTitle,
                root.notifyBody
            ]
            notifyProc.running = true
        } else {
            proc.running = true
        }
    }

    function activate() {
        root._doActivate()
    }
}
