import QtQuick
import Quickshell.Io
import "../../" as Root

// Tray indicator sederhana — cek beberapa proses di background
// dan tampilkan ikon kecil kalau aktif.
// Mendukung: Syncthing, VPN (tun/wg), Tailscale
Row {
    id: root
    spacing: 6

    property bool syncthingOn: true
    property bool vpnOn:       true
    property bool tailscaleOn: true

    Process {
        id: checkProc
        command: ["sh", "-c",
            "pgrep -x syncthing >/dev/null 2>&1 && echo sync || true\n" +
            "ip link show 2>/dev/null | grep -qE 'tun[0-9]|vpn|wg[0-9]' && echo vpn || true\n" +
            "tailscale status >/dev/null 2>&1 && echo tscale || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.syncthingOn = text.includes("sync")
                root.vpnOn       = text.includes("vpn")
                root.tailscaleOn = text.includes("tscale")
            }
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: checkProc.running = true
    }

    // ── Indikator helper — reusable inline ────────────────────────────────
    component TrayIcon: Rectangle {
        property string icon:    ""
        property string label:   ""
        property color  iconColor: Root.Colors.blue

        width: 22; height: 22; radius: 6
        color: ma.hovered
               ? Root.Colors.surface1
               : Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.15)
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 13
            color: parent.iconColor
        }

        // Tooltip inline — popup kecil di atas ikon
        Rectangle {
            visible: ma.hovered
            anchors.bottom: parent.top
            anchors.bottomMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: tipTxt.implicitWidth + 12
            height: 22
            radius: 6
            color: Root.Colors.surface1
            border.color: Root.Colors.surface2
            border.width: 1
            z: 100

            Text {
                id: tipTxt
                anchors.centerIn: parent
                text: parent.parent.label
                font.pixelSize: 11
                color: Root.Colors.text
            }
        }

        HoverHandler { id: ma }
    }

    TrayIcon {
        visible: root.syncthingOn
        icon: "󰧉"; label: "Syncthing aktif"
        iconColor: Root.Colors.blue
    }

    TrayIcon {
        visible: root.vpnOn
        icon: "󰦝"; label: "VPN aktif"
        iconColor: Root.Colors.green
    }

    TrayIcon {
        visible: root.tailscaleOn
        icon: "󰒄"; label: "Tailscale aktif"
        iconColor: Root.Colors.mauve
    }
}
