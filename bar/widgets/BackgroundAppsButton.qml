import QtQuick
import "../../" as Root

// Tombol untuk membuka panel Background Apps
Item {
    id: root
    width: 30
    height: 26

    property bool panelOpen: false
    signal togglePanel()

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: buttonArea.containsMouse
             ? Root.Colors.surface1
             : (root.panelOpen ? Root.Colors.surface0 : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "CaskaydiaCove Nerd Font"
        font.pixelSize: 15
        color: root.panelOpen ? Root.Colors.blue : Root.Colors.text
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }
}
