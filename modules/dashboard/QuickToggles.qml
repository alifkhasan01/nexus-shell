import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../" as Root

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
        label: "IDLE MONITOR"
        icon: "󰒲"
        checkCommand: "pgrep -x hypridle > /dev/null && echo yes || echo no"
        checkMatch: "yes"
        onCommand:  "nohup hypridle </dev/null >/dev/null 2>&1 &"
        offCommand: "pkill -x hypridle"
        managerCommand: ""
    }

    // ── Screenshot button ─────────────────────────────────────────────────
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
                text: "SCRENSHOT SELECT"
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
                if (quickTogglesRoot.dashboardRoot) {
                    quickTogglesRoot.dashboardRoot.screenshotRequested()
                    quickTogglesRoot.dashboardRoot.closeRequested()
                }
            }
        }
    }

    // ── Grim full-screen screenshot ───────────────────────────────────────
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
                text: "SCRENSHOT FULL"
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
                if (quickTogglesRoot.dashboardRoot) {
                    quickTogglesRoot.dashboardRoot.grimRequested()
                    quickTogglesRoot.dashboardRoot.closeRequested()
                }
            }
        }
    }

    // ── wf-recorder toggle ────────────────────────────────────────────────
    Rectangle {
        id: recorderBtn
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14

        property bool recording: false
        // apakah recording ini dimulai dengan mic (deteksi via cmdline)
        property bool recordingWithMic: false

        color: recording
               ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.85)
               : (recArea.containsPress ? Root.Colors.blue : Root.Colors.surface0)
        Behavior on color { ColorAnimation { duration: 150 } }

        // Poll apakah wf-recorder sedang berjalan + apakah dengan mic
        Process {
            id: recCheckProc
            command: ["sh", "-c",
                "pgrep -x wf-recorder > /dev/null && echo yes || echo no; " +
                "cat /proc/$(pgrep -x wf-recorder)/cmdline 2>/dev/null | tr '\\0' ' ' | grep -qE '(--audio=|\\-a[^-])' && echo mic || echo nomic"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n")
                    recorderBtn.recording       = (lines[0] || "").trim() === "yes"
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
                text: recorderBtn.recording ? "STOP" : "START"
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
            width: 7
            height: 7
            radius: 4
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
            visible: !recorderBtn.recording  // tunjukkan hint saat idle
                     || recorderBtn.recordingWithMic
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 6
            text: "󰍬"
            font.pixelSize: 10
            color: recorderBtn.recording && recorderBtn.recordingWithMic
                   ? Root.Colors.base
                   : Root.Colors.subtext
            opacity: recorderBtn.recording && recorderBtn.recordingWithMic ? 1.0 : 0.5
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        MouseArea {
            id: recArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (!quickTogglesRoot.dashboardRoot) return
                if (recorderBtn.recording) {
                    // stop — tidak peduli mode, tetap close dashboard
                    quickTogglesRoot.dashboardRoot.recorderToggleRequested()
                } else if (mouse.button === Qt.RightButton) {
                    // start dengan mic
                    quickTogglesRoot.dashboardRoot.recorderMicToggleRequested()
                } else {
                    // start tanpa mic
                    quickTogglesRoot.dashboardRoot.recorderToggleRequested()
                }
                quickTogglesRoot.dashboardRoot.closeRequested()
            }
        }
    }

    // ── DND toggle ────────────────────────────────────────────────────────
    QuickToggle {
        Layout.fillWidth: true
        label: "DND"
        icon: "󰂛"
        checkCommand: "swaync-client -D"
        checkMatch: "true"
        onCommand: "swaync-client -dn"
        offCommand: "swaync-client -df"
        managerCommand: ""
    }

    // ── Night toggle ──────────────────────────────────────────────────────
    QuickToggle {
        Layout.fillWidth: true
        label: "NIGHT"
        icon: "󰌵"
        checkCommand: "pgrep -x hyprsunset > /dev/null && echo yes || echo no"
        checkMatch: "yes"
        onCommand: "nohup hyprsunset -t 4500 </dev/null >/dev/null 2>&1 &"
        offCommand: "pkill -x hyprsunset"
        managerCommand: ""

        // Pastikan hyprsunset mati saat quickshell pertama kali load,
        // supaya toggle selalu mulai dari OFF
        Component.onCompleted: {
            killOnStartProc.running = true
        }

        Process {
            id: killOnStartProc
            command: ["sh", "-c", "pkill -x hyprsunset; true"]
        }
    }
}
