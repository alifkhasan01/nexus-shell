import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower
import "../" as Root

// Panel baterai — menampilkan status baterai lengkap dan kontrol power profile.
//   • Persentase besar + arc visual
//   • Status charging / waktu tersisa
//   • Health / kapasitas baterai
//   • Selector power profile (Performance / Balanced / Power Saver)
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-battery"
    WlrLayershell.exclusiveZone: 0

    // ── UPower data ────────────────────────────────────────────────────────
    property var device: UPower.displayDevice
    property int percent: device?.percentage ? Math.round(device.percentage * 100) : 0
    property bool charging: device?.state === UPowerDeviceState.Charging
    property bool fullycharged: device?.state === UPowerDeviceState.FullyCharged
    // Kapasitas / health (0.0 – 1.0)
    property real capacity: device?.capacity ?? 1.0
    property int healthPct: Math.round(capacity * 100)
    // Waktu tersisa (detik) — UPower beri -1 kalau belum terhitung
    property real timeToEmpty:  device?.timeToEmpty  ?? 0
    property real timeToFull:   device?.timeToFull   ?? 0

    // ── Power profile state ────────────────────────────────────────────────
    // Nilai: "performance" | "balanced" | "power-saver"
    property string currentProfile: "balanced"

    property Process profileReadProc: Process {
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                if (v === "performance" || v === "balanced" || v === "power-saver")
                    root.currentProfile = v
            }
        }
    }

    property Process profileSetProc: Process {}

    // ── Satu handler onOpenChanged — showPanel + refresh profile ──────────
    onOpenChanged: {
        if (open) {
            showPanel = true
            profileReadProc.running = false
            profileReadProc.running = true
        }
    }

    function setProfile(profile) {
        root.currentProfile = profile
        profileSetProc.command = ["powerprofilesctl", "set", profile]
        profileSetProc.running = true
    }

    // ── Helpers ────────────────────────────────────────────────────────────
    function formatTime(seconds) {
        if (seconds <= 0) return "—"
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "j " + m + "m"
        return m + " menit"
    }

    function healthLabel(pct) {
        if (pct >= 90) return "Baik"
        if (pct >= 70) return "Normal"
        if (pct >= 50) return "Menurun"
        return "Buruk"
    }

    function healthColor(pct) {
        if (pct >= 90) return Root.Colors.green
        if (pct >= 70) return Root.Colors.yellow
        if (pct >= 50) return Root.Colors.peach
        return Root.Colors.red
    }

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 320
        height: mainCol.implicitHeight + 24

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi muncul / hilang ────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -50 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                NumberAnimation { target: cardTranslate; property: "y"; duration: 220; easing.type: Easing.OutCubic }
                OpacityAnimator { target: card; duration: 200; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: 160; easing.type: Easing.InCubic }
                        OpacityAnimator { target: card; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Blokir klik di dalam kartu
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            // ── Header ─────────────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text: "󰁹  Baterai"
                font.pixelSize: 15
                font.bold: true
                color: Root.Colors.text
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ── Arc + info utama ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Arc baterai — Canvas
                Item {
                    width: 96
                    height: 96

                    Canvas {
                        id: arcCanvas
                        anchors.fill: parent

                        property real arcValue: root.percent / 100
                        property color trackColor: Root.Colors.surface1
                        property color fillColor: {
                            if (root.charging || root.fullycharged) return Root.Colors.yellow
                            if (root.percent <= 20) return Root.Colors.red
                            if (root.percent <= 35) return Root.Colors.peach
                            return Root.Colors.green
                        }

                        onArcValueChanged: requestPaint()
                        onFillColorChanged: requestPaint()
                        onTrackColorChanged: requestPaint()

                        Behavior on arcValue {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const cx = width / 2
                            const cy = height / 2
                            const r  = (Math.min(width, height) / 2) - 8
                            const startAngle = -Math.PI / 2          // top
                            const fullAngle  = 2 * Math.PI

                            // Track (background arc)
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, fullAngle)
                            ctx.strokeStyle = trackColor
                            ctx.lineWidth = 8
                            ctx.lineCap = "round"
                            ctx.stroke()

                            // Fill arc
                            if (arcValue > 0) {
                                ctx.beginPath()
                                ctx.arc(cx, cy, r, startAngle,
                                        startAngle + fullAngle * arcValue)
                                ctx.strokeStyle = fillColor
                                ctx.lineWidth = 8
                                ctx.lineCap = "round"
                                ctx.stroke()
                            }
                        }

                        // Re-paint saat tema berubah
                        Connections {
                            target: Root.Colors
                            function onBaseChanged() { arcCanvas.requestPaint() }
                        }
                    }

                    // Persentase di tengah arc
                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.percent + "%"
                            font.pixelSize: 20
                            font.bold: true
                            color: arcCanvas.fillColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.fullycharged) return "Penuh"
                                if (root.charging)     return "Charging"
                                return "Discharging"
                            }
                            font.pixelSize: 9
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                // Info detail di sisi kanan arc
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    // Status charging / waktu
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.charging ? "Waktu ke penuh" : "Waktu tersisa"
                            font.pixelSize: 10
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: root.charging
                                  ? root.formatTime(root.timeToFull)
                                  : (root.fullycharged ? "—" : root.formatTime(root.timeToEmpty))
                            font.pixelSize: 15
                            font.bold: true
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Divider tipis
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Health
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Kesehatan Baterai"
                            font.pixelSize: 10
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        RowLayout {
                            spacing: 6
                            Text {
                                text: root.healthPct + "%"
                                font.pixelSize: 15
                                font.bold: true
                                color: root.healthColor(root.healthPct)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "· " + root.healthLabel(root.healthPct)
                                font.pixelSize: 11
                                color: Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        // Health bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: parent.width * (root.healthPct / 100)
                                height: parent.height
                                radius: 2
                                color: root.healthColor(root.healthPct)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            // ── Divider ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ── Power Profile Selector ─────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󱐋  Power Profile"
                    font.pixelSize: 13
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Tiga tombol profile — full-width, vertical stack
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "performance", icon: "󱐋", label: "Performance",  desc: "Performa maksimal, baterai cepat habis" },
                            { id: "balanced",    icon: "󰾅", label: "Balanced",     desc: "Seimbang antara performa dan daya" },
                            { id: "power-saver", icon: "󰌪", label: "Power Saver",  desc: "Hemat daya, memperpanjang umur baterai" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            height: 52
                            radius: 10

                            property bool isActive: root.currentProfile === modelData.id

                            color: isActive
                                   ? Qt.alpha(profileAccent, 0.18)
                                   : (pMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)

                            border.color: isActive ? profileAccent : "transparent"
                            border.width: isActive ? 2 : 0

                            property color profileAccent: {
                                switch (modelData.id) {
                                    case "performance": return Root.Colors.red
                                    case "balanced":    return Root.Colors.blue
                                    case "power-saver": return Root.Colors.green
                                    default:            return Root.Colors.blue
                                }
                            }

                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                // Ikon profil
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 20
                                    color: isActive ? profileAccent : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Label + deskripsi
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 13
                                        font.bold: isActive
                                        color: isActive ? Root.Colors.text : Root.Colors.subtext
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.desc
                                        font.pixelSize: 10
                                        color: Root.Colors.subtext
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                // Check indicator
                                Text {
                                    visible: isActive
                                    text: "󰄴"
                                    font.pixelSize: 14
                                    color: profileAccent
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            MouseArea {
                                id: pMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setProfile(modelData.id)
                            }
                        }
                    }
                }
            }

            // Padding bawah
            Item { height: 0 }
        }
    }
}
