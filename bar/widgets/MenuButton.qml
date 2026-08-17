import QtQuick
import "../../" as Root

Rectangle {
    id: root

    property bool menuOpen: false

    signal toggleMenu()

    width: 34
    height: 26
    radius: 6
    color: mouseArea.containsMouse
        ? Root.Colors.surface1
        : (menuOpen ? Root.Colors.surface0 : "transparent")

    Behavior on color { ColorAnimation {
        duration: Root.Appearance.animation.elementMoveFast.duration
        easing.type: Root.Appearance.animation.elementMoveFast.type
        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
    }}

    Text {
        anchors.centerIn: parent
        text: "󰣇"        // nf-linux-archlinux
        font.pixelSize: 16
        color: menuOpen ? Root.Colors.blue : Root.Colors.blue
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMenu()
    }
}
