import QtQuick
import Quickshell
import Quickshell.Wayland
import "../" as Root

Item {
    id: root
    width: 26
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse
            ? Root.Colors.surface1
            : (mouseArea.pressed ? Root.Colors.surface2 : "transparent")

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.pixelSize: 15
            color: Root.Colors.red
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerMenuLoader.active = !powerMenuLoader.active
    }

    LazyLoader {
        id: powerMenuLoader
        active: false

        PanelWindow {
            anchors {
                top: true
                right: true
            }
            margins {
                top: 40
                right: 8
            }
            implicitWidth: 160
            implicitHeight: menuCol.implicitHeight + 16
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.exclusiveZone: 0

            // klik di luar menu untuk menutup
            MouseArea {
                anchors.fill: parent
                onClicked: powerMenuLoader.active = false
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 10
                color: Root.Colors.mantle
                border.color: Root.Colors.surface1
                border.width: 1

                Column {
                    id: menuCol
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    PowerMenuItem { label: "Lock"; icon: "󰌾"; command: ["hyprlock"] }
                    PowerMenuItem { label: "Logout"; icon: "󰍃"; command: ["hyprctl", "dispatch", "exit"] }
                    PowerMenuItem { label: "Reboot"; icon: "󰜉"; command: ["systemctl", "reboot"] }
                    PowerMenuItem { label: "Shutdown"; icon: "󰐥"; command: ["systemctl", "poweroff"] }
                }
            }
        }
    }
}
