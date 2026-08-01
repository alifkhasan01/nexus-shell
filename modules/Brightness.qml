import QtQuick
import Quickshell.Io
import "../" as Root

// Kontrol brightness via `brightnessctl` (pastikan sudah terinstall & user
// masuk grup `video`, atau atur udev rule supaya tidak perlu sudo).
Item {
    id: root
    width: label.width
    height: 20

    property int percent: 0

    Text {
        id: label
        anchors.centerIn: parent
        color: Root.Colors.text
        font.pixelSize: 14
        text: "󰃞   " + root.percent + "%"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            const step = 5
            stepProcess.command = [
                "brightnessctl", "set",
                (wheel.angleDelta.y > 0 ? step + "%+" : step + "%-")
            ]
            stepProcess.running = true
        }
    }

    Process {
        id: stepProcess
        onExited: getProcess.running = true
    }

    // Poll brightness saat ini setiap 3 detik + setelah scroll
    Process {
        id: getProcess
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                // Format brightnessctl -m: device,class,current,percent%,max
                const parts = data.trim().split(",")
                if (parts.length >= 4) {
                    root.percent = parseInt(parts[3])
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getProcess.running = true
    }
}
