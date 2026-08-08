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

    // ── wf-recorder toggle ────────────────────────────────────────────────
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

        Process {
            id: recCheckProc
            command: ["sh", "-c",
                "pgrep -x wf-recorder > /dev/null && echo yes || echo no; " +
                "cat /proc/$(pgrep -x wf-recorder)/cmdline 2>/dev/null | tr '\\0' ' ' | grep -q 'qs_rec_mix' && echo mic || echo nomic"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n")
                    recorderBtn.recording        = (lines[0] || "").trim() === "yes"
                    recorderBtn.recordingWithMic = (lines[1] || "").trim() === "mic"
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
