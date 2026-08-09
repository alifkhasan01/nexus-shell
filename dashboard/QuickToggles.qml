import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

GridLayout {
    id: quickTogglesRoot
    columns: 3
    rowSpacing: 8
    columnSpacing: 8
    Layout.fillWidth: true

    property var dashboardRoot: null

    // ── Hypridle toggle ───────────────────────────────────────────────────
    QuickToggle {
        Layout.fillWidth: true
        label: "IDLE"
        icon: "󰒲"
        dashboardRoot: quickTogglesRoot.dashboardRoot
        checkCommand: "pgrep -x hypridle > /dev/null && echo yes || echo no"
        checkMatch: "yes"
        onCommand:  "nohup hypridle </dev/null >/dev/null 2>&1 &"
        offCommand: "pkill -x hypridle"
        managerCommand: ""
        notifIconOn:  "display"
        notifIconOff: "display"
        notifSummaryOn:  "Idle Monitor Aktif"
        notifSummaryOff: "Idle Monitor Nonaktif"
        notifBodyOn:  "Monitor akan otomatis mati saat idle."
        notifBodyOff: "Monitor tidak akan mati saat idle."
    }

    // ── Screenshot select ─────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14
        color: ssArea.containsPress ? Root.Colors.blue : Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: 150 } }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰄀"
                font.pixelSize: 18
                color: ssArea.containsPress ? Root.Colors.base : Root.Colors.text
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SS SELECT"
                font.pixelSize: 11
                color: ssArea.containsPress ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            id: ssArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!quickTogglesRoot.dashboardRoot) return
                quickTogglesRoot.dashboardRoot.screenshotRequested()
                quickTogglesRoot.dashboardRoot.closeRequested()
            }
        }
    }

    // ── Screenshot full ───────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14
        color: grimArea.containsPress ? Root.Colors.blue : Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: 150 } }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰹑"
                font.pixelSize: 18
                color: grimArea.containsPress ? Root.Colors.base : Root.Colors.text
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SS FULL"
                font.pixelSize: 11
                color: grimArea.containsPress ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            id: grimArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!quickTogglesRoot.dashboardRoot) return
                quickTogglesRoot.dashboardRoot.grimRequested()
                quickTogglesRoot.dashboardRoot.closeRequested()
            }
        }
    }

    // ── gpu-screen-recorder toggle ────────────────────────────────────────
    // Left click  = desktop audio saja (default)
    // Right click = desktop + mic
    Rectangle {
        id: recorderBtn
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14

        property bool recording: false
        property bool recordingWithMic: false

        color: recording
               ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.85)
               : (recArea.containsPress ? Root.Colors.blue : Root.Colors.surface0)
        Behavior on color { ColorAnimation { duration: 150 } }

        // Deteksi status recording via pidfile qs_gsr.pid.
        // Kalau sebelumnya recording=true tapi pidfile hilang = baru saja stop → notif.
        Process {
            id: recCheckProc
            command: ["sh", "-c",
                "PIDFILE=\"/run/user/$(id -u)/qs_gsr.pid\"; " +
                "PID=$(cat \"$PIDFILE\" 2>/dev/null); " +
                "if [ -n \"$PID\" ] && kill -0 \"$PID\" 2>/dev/null; then " +
                "  echo yes; " +
                "  grep -ql 'default_input' /proc/$PID/cmdline 2>/dev/null && echo mic || echo nomic; " +
                "else " +
                "  echo no; echo nomic; " +
                "fi"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n")
                    const wasRecording = recorderBtn.recording
                    const nowRecording = (lines[0] || "").trim() === "yes"
                    recorderBtn.recording        = nowRecording
                    recorderBtn.recordingWithMic = (lines[1] || "").trim() === "mic"
                    // Baru saja berhenti → kirim notifikasi
                    if (wasRecording && !nowRecording && quickTogglesRoot.dashboardRoot) {
                        quickTogglesRoot.dashboardRoot.notifyRequested(
                            "media-record", "Recording Tersimpan",
                            "File disimpan di ~/Videos/Recordings")
                    }
                }
            }
        }
        Timer {
            interval: 3000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: recCheckProc.running = true
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorderBtn.recording ? "󰹊" : "󰑋"
                font.pixelSize: 18
                color: recorderBtn.recording ? Root.Colors.base : (recArea.containsPress ? Root.Colors.base : Root.Colors.text)
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorderBtn.recording ? "STOP" : "RECORD"
                font.pixelSize: 11
                color: recorderBtn.recording ? Root.Colors.base : (recArea.containsPress ? Root.Colors.base : Root.Colors.subtext)
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        // Titik merah berkedip saat recording
        Rectangle {
            visible: recorderBtn.recording
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 7
            width: 7; height: 7; radius: 4
            color: Root.Colors.base
            SequentialAnimation on opacity {
                running: recorderBtn.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        // Indikator mic di pojok kiri bawah
        Text {
            visible: recorderBtn.recording
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 6
            text: recorderBtn.recordingWithMic ? "󰕾󰍬" : "󰕾"
            font.pixelSize: 9
            color: Root.Colors.base
        }

        MouseArea {
            id: recArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (!quickTogglesRoot.dashboardRoot) return
                if (recorderBtn.recording) {
                    quickTogglesRoot.dashboardRoot.recorderToggleRequested()
                } else if (mouse.button === Qt.RightButton) {
                    quickTogglesRoot.dashboardRoot.recorderMicToggleRequested()
                } else {
                    quickTogglesRoot.dashboardRoot.recorderToggleRequested()
                }
                quickTogglesRoot.dashboardRoot.closeRequested()
            }
        }
    }

    // ── DND toggle ────────────────────────────────────────────────────────
    // Baca state dari dashboardRoot.dndActive (shellState.dnd) — bukan swaync.
    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14

        readonly property bool dndOn: quickTogglesRoot.dashboardRoot
                                      ? quickTogglesRoot.dashboardRoot.dndActive
                                      : false

        color: dndOn ? Root.Colors.blue : Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: 150 } }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂛"
                font.pixelSize: 18
                color: parent.parent.dndOn ? Root.Colors.base : Root.Colors.text
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "DND"
                font.pixelSize: 11
                color: parent.parent.dndOn ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!quickTogglesRoot.dashboardRoot) return
                quickTogglesRoot.dashboardRoot.dndToggleRequested()
            }
        }
    }

    // ── Night toggle ──────────────────────────────────────────────────────
    QuickToggle {
        Layout.fillWidth: true
        label: "NIGHT"
        icon: "󰌵"
        dashboardRoot: quickTogglesRoot.dashboardRoot
        checkCommand: "pgrep -x hyprsunset > /dev/null && echo yes || echo no"
        checkMatch: "yes"
        onCommand: "nohup hyprsunset -t 4500 </dev/null >/dev/null 2>&1 &"
        offCommand: "pkill -x hyprsunset"
        managerCommand: ""
        notifIconOn:  "night-light"
        notifIconOff: "display-brightness"
        notifSummaryOn:  "Night Light Aktif"
        notifSummaryOff: "Night Light Nonaktif"
        notifBodyOn:  "Suhu warna diset ke 4500K."
        notifBodyOff: "Suhu warna dikembalikan normal."
    }
}
