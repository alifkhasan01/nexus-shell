import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../" as Root

RowLayout {
    id: root
    spacing: 6

    // Jumlah workspace yang selalu ditampilkan (1..N)
    property int workspaceCount: 10

    Repeater {
        model: root.workspaceCount

        Rectangle {
            id: wsDelegate
            property int wsId: index + 1
            property var wsObj: Hyprland.workspaces.values.find(w => w.id === wsId)
            property bool isActive: Hyprland.focusedWorkspace?.id === wsId
            property bool isOccupied: wsObj !== undefined

            width: isActive ? 14 : 14
            height: 14
            radius: 7
            color: isActive
                ? Root.Colors.blue
                : (isOccupied ? Root.Colors.surface2 : Root.Colors.surface0)

            Behavior on width {
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
            }
            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = ' + wsDelegate.wsId + ' })')
            }
        }
    }
}
