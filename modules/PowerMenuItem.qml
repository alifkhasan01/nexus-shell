import QtQuick
import Quickshell.Io
import "../" as Root

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property var command: []

    width: parent ? parent.width : 140
    height: 30
    radius: 6
    color: mouseArea.containsMouse ? Root.Colors.surface1 : "transparent"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        spacing: 8

        Text { text: root.icon; color: Root.Colors.subtext; font.pixelSize: 14 }
        Text { text: root.label; color: Root.Colors.text; font.pixelSize: 13 }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: proc.running = true
    }

    Process {
        id: proc
        command: root.command
    }
}
