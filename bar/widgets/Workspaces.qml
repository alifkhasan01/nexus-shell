import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../" as Root

// Hyprland workspace switcher.
RowLayout {
    id: wsRoot

    spacing: 6

    readonly property var wsEmoji: ["󰧟", "󰈹", "", "󰎈", "󰋹", "󰙯", "󰎄", "󰑴", "󰅩", "󰒱"]

    function emojiFor(id: int): string {
        const idx = id - 1
        if (idx >= 0 && idx < wsRoot.wsEmoji.length)
            return wsRoot.wsEmoji[idx]
        return id.toString()
    }

    property int minWorkspaces: 8

    readonly property var workspaceIds: {
        let maxId = Math.max(1, wsRoot.minWorkspaces)
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id > maxId)
                maxId = list[i].id
        let ids = []
        for (let id = 1; id <= maxId; id++)
            ids.push(id)
        return ids
    }

    function workspaceById(id: int): var {
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i]
        return null
    }

    Repeater {
        id: rep
        model: wsRoot.workspaceIds

        delegate: Rectangle {
            id: ws

            required property var modelData

            readonly property bool isActive: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === ws.modelData

            readonly property bool occupied: wsRoot.workspaceById(ws.modelData) !== null

            function activate(): void {
                if (Hyprland.usingLua)
                    Hyprland.dispatch("hl.dsp.focus({workspace = '" + ws.modelData + "'})")
                else
                    Hyprland.dispatch("workspace " + ws.modelData)
            }

            implicitWidth: 30
            implicitHeight: 30
            radius: 8

            opacity: (ws.isActive || ws.occupied || wsMouse.containsMouse) ? 1 : 0.4
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.standard }
            }

            color: ws.isActive
                ? Root.Colors.blue
                : (wsMouse.containsMouse ? Root.Colors.surface1 : "transparent")

            border.color: Root.Colors.blue
            border.width: ws.isActive ? 0 : 1

            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.standard }
            }
            Behavior on border.width {
                NumberAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.standard }
            }

            Text {
                anchors.centerIn: parent
                text: ws.isActive ? "󰮯" : "•"
                font.pixelSize: ws.isActive ? 14 : 18
                color: ws.isActive ? Root.Colors.base : Root.Colors.text

                Behavior on color {
                    ColorAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.standard }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.activate()
            }
        }
    }
}
