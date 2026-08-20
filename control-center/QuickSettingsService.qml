pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton service buat state Wi-Fi / Bluetooth / DND / Night Light.
// Pake CLI tools (nmcli, bluetoothctl, swaync-client, hyprsunset/gammastep)
// biar nggak gantung ke library dbus tertentu — sesuaikan command kalau
// setup lu beda (misal lu udah punya hyprsunset-rs, tinggal ganti bagian
// nightlight ke socket IPC lu sendiri).
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool dndEnabled: false
    property bool nightLightEnabled: false
    property bool airplaneMode: false

    property bool wifiBusy: false
    property bool bluetoothBusy: false

    function refresh() {
        wifiCheck.running = true
        btCheck.running = true
        dndCheck.running = true
    }

    function toggleWifi() {
        wifiBusy = true
        wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
        wifiToggleProc.running = true
    }

    function toggleBluetooth() {
        bluetoothBusy = true
        btToggleProc.command = ["bluetoothctl", "power", bluetoothEnabled ? "off" : "on"]
        btToggleProc.running = true
    }

    function toggleDnd() {
        dndToggleProc.running = true
    }

    function toggleNightLight() {
        // Ganti dengan panggilan ke daemon hyprsunset-rs lu kalau ada,
        // ini cuma fallback pake hyprctl hyprsunset (kalau plugin dipakai)
        nightLightEnabled = !nightLightEnabled
        nightLightProc.command = nightLightEnabled
            ? ["hyprctl", "hyprsunset", "temperature", "4000"]
            : ["hyprctl", "hyprsunset", "identity"]
        nightLightProc.running = true
    }

    Component.onCompleted: refresh()

    // --- status pollers ---
    Process {
        id: wifiCheck
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: btCheck
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = text.includes("Powered: yes")
        }
    }

    Process {
        id: dndCheck
        command: ["swaync-client", "-D"]
        stdout: StdioCollector {
            onStreamFinished: root.dndEnabled = text.trim() === "true"
        }
    }

    // --- action runners ---
    Process {
        id: wifiToggleProc
        onExited: {
            root.wifiBusy = false
            wifiCheck.running = true
        }
    }

    Process {
        id: btToggleProc
        onExited: {
            root.bluetoothBusy = false
            btCheck.running = true
        }
    }

    Process {
        id: dndToggleProc
        command: ["swaync-client", "-d"]
        onExited: dndCheck.running = true
    }

    Process {
        id: nightLightProc
    }

    // Auto-refresh tiap 5 detik buat nangkep perubahan dari luar (mis. lu toggle lewat nmtui)
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
