import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services" as Services
import "../" as Root

GridLayout {
    id: quickTogglesRoot
    columns: 3
    rowSpacing: 8
    columnSpacing: 8
    Layout.fillWidth: true

    property var dashboardRoot: null

    // ── Idle Monitor toggle ───────────────────────────────────────────────
    // Toggle idle monitoring (screen off, lock, suspend)
    // Saat OFF: sistem tidak akan auto screen-off/lock/suspend
    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14

        readonly property bool monitorOn: Services.IdleManager.monitoringEnabled

        color: monitorOn ? Root.Colors.blue : Root.Colors.surface0
        Behavior on color {
            ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.parent.monitorOn ? "󰅶" : "󰒲"
                font.pixelSize: 18
                color: parent.parent.monitorOn ? Root.Colors.base : Root.Colors.text
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "IDLE"
                font.pixelSize: 11
                color: parent.parent.monitorOn ? Root.Colors.base : Root.Colors.subtext
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Services.IdleManager.toggle()
                if (!quickTogglesRoot.dashboardRoot) return
                
                const isActive = Services.IdleManager.monitoringEnabled
                quickTogglesRoot.dashboardRoot.notifyRequested(
                    isActive ? "display" : "display",
                    isActive ? "Idle Monitor Aktif" : "Idle Monitor Nonaktif",
                    isActive ? "Auto screen-off/lock/suspend diaktifkan." : "Auto screen-off/lock/suspend dinonaktifkan."
                )
            }
        }
    }

    // ── Screenshot select ─────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14
        color: ssArea.containsPress ? Root.Colors.blue : Root.Colors.surface0
        Behavior on color {
            ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰄀"
                font.pixelSize: 18
                color: ssArea.containsPress ? Root.Colors.base : Root.Colors.text
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SS SELECT"
                font.pixelSize: 11
                color: ssArea.containsPress ? Root.Colors.base : Root.Colors.subtext
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
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
        Behavior on color {
            ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰹑"
                font.pixelSize: 18
                color: grimArea.containsPress ? Root.Colors.base : Root.Colors.text
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SS FULL"
                font.pixelSize: 11
                color: grimArea.containsPress ? Root.Colors.base : Root.Colors.subtext
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
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
        Behavior on color {
            ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂛"
                font.pixelSize: 18
                color: parent.parent.dndOn ? Root.Colors.base : Root.Colors.text
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "DND"
                font.pixelSize: 11
                color: parent.parent.dndOn ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
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

    // ── Pomodoro timer ────────────────────────────────────────────────────
    // Siklus: 25 menit kerja → 5 menit istirahat, notif tiap selesai.
    // Klik untuk mulai/pause; tahan kanan untuk reset.
    Rectangle {
        id: pomodoroBtn
        Layout.fillWidth: true
        implicitWidth: 84
        implicitHeight: 60
        radius: 14

        // 0 = idle, 1 = work, 2 = break
        property int  phase:   0
        property bool running: false
        property int  secs:    0    // sisa detik fase aktif

        readonly property int workSecs:  25 * 60
        readonly property int breakSecs: 5  * 60

        Timer {
            id: pomTick
            interval: 1000
            repeat: true
            running: pomodoroBtn.running
            onTriggered: {
                if (pomodoroBtn.secs > 0) {
                    pomodoroBtn.secs--
                } else {
                    // Fase selesai
                    if (pomodoroBtn.phase === 1) {
                        // kerja selesai → istirahat
                        pomodoroBtn.phase = 2
                        pomodoroBtn.secs  = pomodoroBtn.breakSecs
                        if (quickTogglesRoot.dashboardRoot)
                            quickTogglesRoot.dashboardRoot.notifyRequested(
                                "appointment-soon", "Pomodoro: Istirahat!",
                                "Kerja 25 menit selesai. Istirahat 5 menit dimulai.")
                    } else {
                        // istirahat selesai → kerja
                        pomodoroBtn.phase = 1
                        pomodoroBtn.secs  = pomodoroBtn.workSecs
                        if (quickTogglesRoot.dashboardRoot)
                            quickTogglesRoot.dashboardRoot.notifyRequested(
                                "appointment-soon", "Pomodoro: Mulai kerja!",
                                "Istirahat selesai. Sesi kerja 25 menit dimulai.")
                    }
                }
            }
        }

        function _fmtTime(s) {
            const m = Math.floor(s / 60)
            const ss = s % 60
            return String(m).padStart(2, "0") + ":" + String(ss).padStart(2, "0")
        }

        color: {
            if (!pomodoroBtn.running && pomodoroBtn.phase === 0)
                return pomArea.containsPress ? Root.Colors.blue : Root.Colors.surface0
            if (pomodoroBtn.phase === 1)
                return Qt.rgba(Root.Colors.red.r,   Root.Colors.red.g,   Root.Colors.red.b,   0.80)
            return Qt.rgba(Root.Colors.green.r, Root.Colors.green.g, Root.Colors.green.b, 0.75)
        }
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

        Column {
            anchors.centerIn: parent
            spacing: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pomodoroBtn.phase === 0 ? "󱎫"
                    : (pomodoroBtn.phase === 1 ? "󰔟" : "󰒲")
                font.pixelSize: 16
                color: pomodoroBtn.phase === 0
                       ? (pomArea.containsPress ? Root.Colors.base : Root.Colors.text)
                       : Root.Colors.base
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pomodoroBtn.phase === 0
                      ? "POMO"
                      : pomodoroBtn._fmtTime(pomodoroBtn.secs)
                font.pixelSize: 11; font.bold: pomodoroBtn.phase > 0
                color: pomodoroBtn.phase === 0
                       ? (pomArea.containsPress ? Root.Colors.base : Root.Colors.subtext)
                       : Root.Colors.base
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: pomodoroBtn.phase > 0
                text: pomodoroBtn.phase === 1 ? "KERJA" : "ISTIRAHAT"
                font.pixelSize: 8
                color: Qt.rgba(1,1,1,0.75)
            }
        }

        // Titik kedip saat running
        Rectangle {
            visible: pomodoroBtn.running
            anchors.top: parent.top; anchors.right: parent.right
            anchors.margins: 7
            width: 7; height: 7; radius: 4
            color: Root.Colors.base
            SequentialAnimation on opacity {
                running: pomodoroBtn.running; loops: Animation.Infinite
                NumberAnimation {
                    to: 0.2
                    duration: Root.Appearance.animation.elementMoveFast.duration
                    easing.type: Root.Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                }
                NumberAnimation {
                    to: 1.0
                    duration: Root.Appearance.animation.elementMoveFast.duration
                    easing.type: Root.Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        MouseArea {
            id: pomArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    // Reset
                    pomodoroBtn.running = false
                    pomodoroBtn.phase   = 0
                    pomodoroBtn.secs    = 0
                } else {
                    if (pomodoroBtn.phase === 0) {
                        // Mulai sesi kerja
                        pomodoroBtn.phase   = 1
                        pomodoroBtn.secs    = pomodoroBtn.workSecs
                        pomodoroBtn.running = true
                    } else {
                        // Toggle pause/resume
                        pomodoroBtn.running = !pomodoroBtn.running
                    }
                }
            }
        }
    }
}
