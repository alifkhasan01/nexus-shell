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
    signal toggleWifi()    // left click  — on/off wifi

    onToggleWifi: doToggleWifi()

    property string connType: "none"
    property int wifiStrength: 0
    property string ssid: ""

    function refresh() { pollProc.running = true }

    readonly property string iconText: {
        if (connType === "ethernet") return "󰈀"
        if (!wifiEnabled) return "󰤮"
        if (connType === "wifi") {
            if (wifiStrength >= 75) return "󰤨"
            if (wifiStrength >= 50) return "󰤥"
            if (wifiStrength >= 25) return "󰤢"
            return "󰤟"
        }
        return "󰤭"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: netMa.containsMouse ? Root.Colors.surface1 : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: 16
        color: {
            if (root.panelOpen)           return Root.Colors.blue
            if (root.connType === "none") return Root.Colors.subtext
            return Root.Colors.text
        }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: netMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.toggleWifi()
            else
                root.togglePanel()
        }
    }

    // Toggle wifi on/off langsung dari bar (left click)
    property bool wifiEnabled: true   // state radio wifi — di-sync saat poll

    Process {
        id: wifiToggleProc
        // command diisi saat dipanggil
    }

    Process {
        id: radioCheckProc
        command: ["sh", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
            }
        }
    }

    function doToggleWifi() {
        const cmd = wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
        wifiToggleProc.command = ["sh", "-c", cmd]
        wifiToggleProc.running = true
        // tunggu sebentar lalu re-check radio state + koneksi
        radioCheckTimer.restart()
    }

    Process {
        id: pollProc
        command: ["sh", "-c",
            "t=$(nmcli -t -f TYPE,STATE,CONNECTION dev | grep ':connected:' | head -1); " +
            "[ -z \"$t\" ] && exit 0; " +
            "ty=$(printf '%s' \"$t\" | cut -d: -f1); " +
            "cn=$(printf '%s' \"$t\" | cut -d: -f3-); " +
            "sg=0; " +
            "if [ \"$ty\" = wifi ]; then " +
            "sg=$(nmcli -t -f IN-USE,SIGNAL dev wifi list | grep '^\\*' | head -1 | cut -d: -f2); " +
            "fi; " +
            "printf '%s:connected:%s:%s\\n' \"$ty\" \"$cn\" \"${sg:-0}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (raw === "") { root.connType = "none"; root.ssid = ""; return }
                const parts  = raw.split(":")
                const type   = parts[0] || ""
                const sig    = parseInt(parts[parts.length - 1]) || 0
                const conn   = parts.slice(2, parts.length - 1).join(":") || ""
                if (type === "ethernet" || type === "bond" || type === "vlan") {
                    root.connType = "ethernet"; root.ssid = conn
                } else if (type === "wifi") {
                    root.connType = "wifi"; root.wifiStrength = sig; root.ssid = conn
                } else {
                    root.connType = "none"; root.ssid = ""
                }
            }
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: { pollProc.running = true; radioCheckProc.running = true }
    }

    Timer {
        id: radioCheckTimer
        interval: 1200
        repeat: false
        onTriggered: { radioCheckProc.running = true; pollProc.running = true }
    }
}
