import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../" as Root

// Hyprland workspace switcher.
RowLayout {
    id: wsRoot

    spacing: 6

    // Emoji label per workspace — ganti sesuai selera.
    readonly property var wsEmoji: ["󰧟", "󰈹", "", "󰎈", "󰋹", "󰙯", "󰎄", "󰑴", "󰅩", "󰒱"]
    //                               1      2     3    4     5     6     7     8     9     10

    function emojiFor(id: int): string {
        const idx = id - 1
        if (idx >= 0 && idx < wsRoot.wsEmoji.length)
            return wsRoot.wsEmoji[idx]
        return id.toString()
    }

    // Minimum number of workspaces to always display, even when empty. The list
    // still grows beyond this to reveal any higher-numbered workspace that
    // exists (e.g. switching to workspace 6 while this is 5 adds a 6th dot).
    property int minWorkspaces: 5

    // The workspace ids to render: 1..N, where N is at least minWorkspaces and
    // extends to cover the highest-numbered workspace that currently exists.
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

    // The live Hyprland workspace for an id, or null when it is empty.
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

            required property var modelData   // workspace id (int)

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

            // Dim empty unfocused workspaces
            opacity: (ws.isActive || ws.occupied || wsMouse.containsMouse) ? 1 : 0.4
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
            }

            color: ws.isActive
                ? Root.Colors.blue
                : (wsMouse.containsMouse ? Root.Colors.surface1 : "transparent")

            border.color: Root.Colors.blue
            border.width: ws.isActive ? 0 : 1

            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
            }
            Behavior on border.width {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
            }

            Text {
                anchors.centerIn: parent
                text: ws.isActive ? "󰮯" : "•"
                font.pixelSize: ws.isActive ? 14 : 18
                color: ws.isActive ? Root.Colors.base : Root.Colors.text

                Behavior on color {
                    ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
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
