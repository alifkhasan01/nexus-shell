pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton brightness pake brightnessctl. Install dulu: sudo pacman -S brightnessctl
// dan pastiin user lu masuk grup `video` biar bisa set tanpa sudo.
Singleton {
    id: root

    property real brightness: 0.5 // 0.0 - 1.0
    property int maxBrightness: 100
    property bool ready: false

    function setBrightness(value) {
        const clamped = Math.max(0.01, Math.min(1.0, value))
        root.brightness = clamped
        const pct = Math.round(clamped * 100)
        setProc.command = ["brightnessctl", "set", pct + "%"]
        setProc.running = true
    }

    function bump(delta) {
        setBrightness(root.brightness + delta)
    }

    Component.onCompleted: {
        maxProc.running = true
        currentProc.running = true
    }

    Process {
        id: maxProc
        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: root.maxBrightness = parseInt(text.trim()) || 100
        }
    }

    Process {
        id: currentProc
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = parseInt(text.trim()) || 0
                root.brightness = root.maxBrightness > 0 ? cur / root.maxBrightness : 0
                root.ready = true
            }
        }
    }

    Process {
        id: setProc
    }
}
