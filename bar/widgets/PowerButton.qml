import QtQuick
import "../../" as Root

Item {
    id: root
    width: 26
    height: 26

    property bool menuOpen: false
    signal toggleMenu()

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: ma.containsMouse || menuOpen
            ? Root.Colors.surface1
            : (ma.pressed ? Root.Colors.surface2 : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.pixelSize: 20
            color: menuOpen ? Root.Colors.red : Root.Colors.subtext
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMenu()
    }
}
