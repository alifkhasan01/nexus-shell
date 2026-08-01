import QtQuick
import Quickshell.Io
import "../" as Root

Rectangle {
    id: root

    // Ganti sesuai app launcher yang dipakai: fuzzel, wofi, rofi -show drun, dll.
    property string launcherCommand: "fuzzel"

    width: 34
    height: 26
    radius: 6
    color: mouseArea.containsMouse
        ? Root.Colors.surface1
        : (mouseArea.pressed ? Root.Colors.surface2 : "transparent")

    Text {
        anchors.centerIn: parent
        text: "󰣇"        // nf-linux-archlinux, ganti sesuai icon font yang dipakai
        font.pixelSize: 16
        color: Root.Colors.blue
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: launcherProcess.running = true
    }

    Process {
        id: launcherProcess
        command: ["sh", "-c", root.launcherCommand]
    }
}
