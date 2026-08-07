import QtQuick
import Quickshell.Io
import "../../" as Root

Item {
    id: root
    implicitWidth: 22
    width: implicitWidth
    height: 20

    // dikontrol dari Bar.qml
    property bool panelOpen: false
    signal togglePanel()   // right click — buka ConnectPanel
    signal toggleBt()      // left click  — on/off bluetooth

    onToggleBt: doToggleBt()

    property bool powered: false
    property bool connected: false

    function refresh() { pollProc.running = true }

    readonly property string iconText:
        !root.powered ? "󰂲"
        : root.connected ? "󰂱"
        : "󰂯"

    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: 16
        opacity: root.powered ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 150 } }
        color: root.panelOpen ? Root.Colors.blue
             : root.powered   ? Root.Colors.text
             : Root.Colors.subtext
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.togglePanel()
            else
                root.toggleBt()
        }
    }

    // Toggle bluetooth on/off langsung dari bar (left click)
    Process {
        id: btToggleProc
    }

    function doToggleBt() {
        const cmd = root.powered ? "bluetoothctl power off" : "bluetoothctl power on"
        btToggleProc.command = ["sh", "-c", cmd]
        btToggleProc.running = true
        Qt.callLater(() => pollProc.running = true)
    }

    Process {
        id: pollProc
        command: ["sh", "-c",
            "p=$(bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0); " +
            "c=$(bluetoothctl devices Connected | grep -q . && echo 1 || echo 0); " +
            "echo \"$p $c\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                root.powered   = parts[0] === "1"
                root.connected = parts[1] === "1"
            }
        }
    }

    Timer {
        interval: 6000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }
}
