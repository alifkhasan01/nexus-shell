import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

PanelWindow {
    id: root

    property bool open: false
    property int focusedIndex: -1
    property var lockFn: function() {}
    readonly property int itemCount: 5

    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.exclusiveZone: 0

    onOpenChanged: {
        if (open) {
            focusedIndex = 0
            keyHandler.forceActiveFocus()
            card.scale = 0.9
            card.opacity = 0
            scaleAnim.start()
            fadeAnim.start()
        } else {
            focusedIndex = -1
        }
    }

    // Keyboard handler
    Item {
        id: keyHandler
        focus: true

        Keys.onPressed: event => {
            if (!root.open) return

            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.focusedIndex = (root.focusedIndex - 1 + root.itemCount) % root.itemCount
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
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

    // Background blur overlay
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    // Main card - centered
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 620
        height: content.implicitHeight + 80
        radius: 24
        color: Root.Colors.base
        border.color: Root.Colors.surface2
        border.width: 1
        
        opacity: 0
        scale: 0.9
        
        NumberAnimation on scale {
            id: scaleAnim
            to: 1.0
            duration: 300
            easing.type: Easing.OutBack
            running: false
        }
        
        NumberAnimation on opacity {
            id: fadeAnim
            to: 1.0
            duration: 250
            easing.type: Easing.OutCubic
            running: false
        }

        // Subtle gradient overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#10ffffff" }
                GradientStop { position: 1.0; color: "#05ffffff" }
            }
        }

        MouseArea { 
            anchors.fill: parent
            onClicked: {} 
        }

        ColumnLayout {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 40
            }
            spacing: 32

            // Header
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Text {
                    text: "⏻"
                    font.pixelSize: 48
                    color: Root.Colors.text
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.9
                }

                Text {
                    text: "Power Options"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    color: Root.Colors.text
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Choose an action"
                    font.pixelSize: 13
                    color: Root.Colors.subtext
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.8
                }
            }

            // Power options grid
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                rowSpacing: 16
                columnSpacing: 16

                PowerMenuItem {
                    id: itemLock
                    icon: "󰍁"
                    label: "Lock"
                    accentColor: Root.Colors.blue
                    command: []
                    notifyTitle: "Mengunci layar"
                    notifyBody: "Layar akan dikunci."
                    highlighted: root.focusedIndex === 0
                    onTriggered: {
                        root.closeRequested()
                        root.lockFn()
                    }
                }

                PowerMenuItem {
                    id: itemSuspend
                    icon: "󰒲"
                    label: "Suspend"
                    accentColor: Root.Colors.lavender
                    command: []
                    notifyTitle: "Masuk mode tidur"
                    notifyBody: "Layar dikunci lalu sistem di-suspend."
                    highlighted: root.focusedIndex === 1
                    onTriggered: {
                        root.closeRequested()
                        root.lockFn()
                        suspendProc.running = true
                    }
                }

                PowerMenuItem {
                    id: itemReboot
                    icon: "󰑙"
                    label: "Reboot"
                    accentColor: Root.Colors.yellow
                    command: ["systemctl", "reboot"]
                    notifyTitle: "Merestart sistem"
                    notifyBody: "Sistem akan di-restart sekarang."
                    highlighted: root.focusedIndex === 2
                    onTriggered: root.closeRequested()
                }

                PowerMenuItem {
                    id: itemLogout
                    icon: "󰗼"
                    label: "Logout"
                    accentColor: Root.Colors.peach
                    command: []
                    notifyTitle: "Keluar dari sesi"
                    notifyBody: "Sesi Hyprland akan diterminasi."
                    highlighted: root.focusedIndex === 3
                    onTriggered: {
                        root.closeRequested()
                        logoutProc.startDetached()
                    }
                }

                PowerMenuItem {
                    id: itemShutdown
                    icon: "󰐥"
                    label: "Shutdown"
                    accentColor: Root.Colors.red
                    command: ["systemctl", "poweroff"]
                    notifyTitle: "Mematikan sistem"
                    notifyBody: "Sistem akan dimatikan sekarang."
                    highlighted: root.focusedIndex === 4
                    onTriggered: root.closeRequested()
                }
            }

            // Hint text
            Text {
                text: "Use arrow keys to navigate • Enter to select • Esc to cancel"
                font.pixelSize: 11
                color: Root.Colors.subtext
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }
        }

        // Drop shadow simulation
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            radius: parent.radius + 8
            color: "transparent"
            border.color: "#20000000"
            border.width: 8
            z: -1
        }
    }

    Process {
        id: suspendProc
        command: ["sh", "-c", "loginctl suspend || systemctl suspend"]
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Suspend gagal dengan exit code:", exitCode)
                suspendFallback.running = true
            }
        }
    }

    Process {
        id: suspendFallback
        command: ["sh", "-c", "dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true || systemctl suspend"]
    }

    Process {
        id: logoutProc
        command: ["hyprctl", "dispatch", "exit"]
    }
}
