import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "../../" as Root

Item {
    id: root
    width: row.implicitWidth + 8
    height: 26

    // ── Panel toggle ──────────────────────────────────────────────────────
    property bool panelOpen: false
    signal togglePanel()

    property var device: UPower.displayDevice
    property int percent: device?.percentage ? Math.round(device.percentage * 100) : 0
    property bool charging: device?.state === UPowerDeviceState.Charging

    // ── Notifikasi threshold ──────────────────────────────────────────────
    // Gunakan flag agar notif hanya muncul sekali per crossing, tidak terus
    // berulang selama baterai tetap di threshold yang sama.
    property bool _notifLowSent:  false   // sudah kirim notif ≤30% (not charging)
    property bool _notifFullSent: false   // sudah kirim notif ≥90% (charging)

    onPercentChanged: checkNotif()
    onChargingChanged: checkNotif()

    function checkNotif() {
        // ── Baterai lemah ≤30%, tidak sedang charging ────────────────────
        if (!charging && percent > 0 && percent <= 30) {
            if (!_notifLowSent) {
                _notifLowSent = true
                notifProc.sendNotif(
                    "battery-low",
                    "Baterai Lemah",
                    "Baterai tersisa " + percent + "%. Segera sambungkan charger.",
                    "critical"
                )
            }
        } else {
            // Reset flag saat sudah dicharge atau naik lagi
            if (_notifLowSent && (charging || percent > 35))
                _notifLowSent = false
        }

        // ── Baterai hampir penuh ≥90%, sedang charging ───────────────────
        if (charging && percent >= 90) {
            if (!_notifFullSent) {
                _notifFullSent = true
                notifProc.sendNotif(
                    "battery-full",
                    "Baterai Hampir Penuh",
                    "Baterai sudah " + percent + "%. Bisa cabut charger.",
                    "normal"
                )
            }
        } else {
            // Reset flag saat baterai turun atau charger dicabut
            if (_notifFullSent && (!charging || percent < 85))
                _notifFullSent = false
        }
    }

    // Proses untuk kirim notifikasi via notify-send
    Process {
        id: notifProc

        function sendNotif(icon, summary, body, urgency) {
            notifProc.command = [
                "notify-send",
                "--app-name=Battery",
                "--urgency=" + urgency,
                "--icon=" + icon,
                "--expire-time=8000",
                summary,
                body
            ]
            notifProc.running = true
        }
    }

    // ── Ikon + label ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: batteryMa.containsMouse
               ? Root.Colors.surface1
               : (root.panelOpen ? Root.Colors.surface0 : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: label
            color: {
                if (root.panelOpen)           return Root.Colors.blue
                if (root.charging)            return Root.Colors.yellow
                if (root.percent <= 20)       return Root.Colors.red
                if (root.percent <= 30)       return Root.Colors.peach
                return Root.Colors.text
            }
            Behavior on color { ColorAnimation { duration: 150 } }
            font.pixelSize: 14
            text: {
                let icon
                if (root.charging) icon = "󰂄"
                else if (root.percent >= 90) icon = "󰁹"
                else if (root.percent >= 60) icon = "󰂀"
                else if (root.percent >= 35) icon = "󰁾"
                else if (root.percent >= 15) icon = "󰁻"
                else icon = "󰂃"
                return icon + " " + root.percent + "%"
            }
        }
    }

    MouseArea {
        id: batteryMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }
}
