import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

PanelWindow {
    id: root

    property bool open: false
    property int focusedIndex: -1

    // Jumlah item yang bisa dinavigasi (Lock, Suspend, Reboot, Logout, Shutdown)
    readonly property int itemCount: 5

    signal closeRequested()

    anchors { top: true; right: true }
    margins.top: 5
    margins.right: 10
    implicitWidth: card.width
    implicitHeight: card.height
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.exclusiveZone: 0

    // Reset fokus tiap kali menu dibuka/ditutup
    onOpenChanged: {
        if (open) {
            focusedIndex = 0
            keyHandler.forceActiveFocus()
        } else {
            focusedIndex = -1
        }
    }

    // ── Keyboard handler ───────────────────────────────────────────────────
    Item {
        id: keyHandler
        focus: true

        Keys.onPressed: event => {
            if (!root.open) return

            if (event.key === Qt.Key_Up) {
                root.focusedIndex = (root.focusedIndex - 1 + root.itemCount) % root.itemCount
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                root.focusedIndex = (root.focusedIndex + 1) % root.itemCount
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateItem(root.focusedIndex)
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                root.closeRequested()
                event.accepted = true
            }
        }
    }

    function activateItem(idx) {
        const items = [itemLock, itemSuspend, itemReboot, itemLogout, itemShutdown]
        if (idx >= 0 && idx < items.length)
            items[idx].activate()
    }

    // Klik di luar kartu → tutup
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── Kartu popup ────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        width: 180
        height: col.implicitHeight + 16
        radius: 14
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Klik di dalam kartu → jangan propagate ke overlay
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: col
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 2

            // ── Header ─────────────────────────────────────────────────────
            Text {
                text: "Power"
                font.pixelSize: 11
                color: Root.Colors.subtext
                Layout.leftMargin: 4
                Layout.topMargin: 2
                Layout.bottomMargin: 4
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // ── Items ──────────────────────────────────────────────────────
            PowerMenuItem {
                id: itemLock
                Layout.fillWidth: true
                icon: "󰍁"
                label: "Lock"
                iconColor: Root.Colors.blue
                command: ["loginctl", "lock-session"]
                highlighted: root.focusedIndex === 0
                onTriggered: root.closeRequested()
            }

            PowerMenuItem {
                id: itemSuspend
                Layout.fillWidth: true
                icon: "󰒲"
                label: "Suspend"
                iconColor: Root.Colors.lavender
                command: ["systemctl", "suspend"]
                highlighted: root.focusedIndex === 1
                onTriggered: root.closeRequested()
            }

            PowerMenuItem {
                id: itemReboot
                Layout.fillWidth: true
                icon: "󰑙"
                label: "Reboot"
                iconColor: Root.Colors.yellow
                command: ["reboot"]
                highlighted: root.focusedIndex === 2
                onTriggered: root.closeRequested()
            }

            // Pemisah
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                color: Root.Colors.surface0
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            PowerMenuItem {
                id: itemLogout
                Layout.fillWidth: true
                icon: "󰗼"
                label: "Logout"
                iconColor: Root.Colors.peach
                command: ["hyprctl", "dispatch", "exit"]
                highlighted: root.focusedIndex === 3
                onTriggered: root.closeRequested()
            }

            PowerMenuItem {
                id: itemShutdown
                Layout.fillWidth: true
                icon: "󰐥"
                label: "Shutdown"
                iconColor: Root.Colors.red
                command: ["shutdown", "-h", "now"]
                highlighted: root.focusedIndex === 4
                onTriggered: root.closeRequested()
            }
        }
    }
}
