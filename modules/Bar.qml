import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root

PanelWindow {
    id: bar

    property bool dashboardOpen: false

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: implicitHeight
    WlrLayershell.namespace: "quickshell-bar"

    Rectangle {
        anchors.fill: parent
        color: Root.Colors.mantle

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            // ---------- LEFT SECTION ----------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    MenuButton {}
                    Workspaces {}
                }
            }

            // ---------- CENTER SECTION ----------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Clock {
                    anchors.centerIn: parent
                    onClicked: bar.dashboardOpen = !bar.dashboardOpen
                }
            }

            // ---------- RIGHT SECTION ----------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22

                    Volume {}
                    Brightness {}
                    Battery {}
                    PowerButton {}
                }
            }
        }
    }

    LazyLoader {
        active: bar.dashboardOpen

        Dashboard {
            open: bar.dashboardOpen
            onCloseRequested: bar.dashboardOpen = false
        }
    }
}
