import QtQuick
import Quickshell.Io
import "../../" as Root

// Toggle pill generik: jalankan checkCommand secara berkala buat tau status
// on/off (dianggap ON kalau stdout mengandung checkMatch), lalu jalankan
// onCommand / offCommand pas diklik.
// Right-click (atau long-press) membuka managerCommand jika diisi.
Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string checkCommand: ""
    property string checkMatch: "yes"
    property string onCommand: ""
    property string offCommand: ""
    // Opsional: command untuk membuka connection manager (klik kanan)
    property string managerCommand: ""
    property bool active: false

    implicitWidth: 84
    implicitHeight: 60
    radius: 14
    color: active ? Root.Colors.blue : Root.Colors.surface0

    Behavior on color { ColorAnimation { duration: 150 } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: 18
            color: root.active ? Root.Colors.base : Root.Colors.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: 11
            color: root.active ? Root.Colors.base : Root.Colors.subtext
        }
    }

    // Indikator kecil di pojok kanan bawah kalau ada manager (petunjuk ada
    // aksi klik kanan)
    Rectangle {
        visible: root.managerCommand !== ""
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: 5
        height: 5
        radius: 3
        color: root.active ? Qt.rgba(1,1,1,0.5) : Root.Colors.subtext
        opacity: 0.7
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        pressAndHoldInterval: 600

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.managerCommand !== "") {
                    managerProc.command = ["sh", "-c", root.managerCommand]
                    managerProc.running = true
                }
                return
            }
            // klik kiri: toggle on/off
            toggleProc.command = ["sh", "-c", root.active ? root.offCommand : root.onCommand]
            toggleProc.running = true
            // update optimis — tunda poll selama 2 detik agar tidak
            // di-overwrite sebelum proses on/off sempat berjalan
            root.active = !root.active
            root._debouncing = true
            debounceTimer.restart()
        }

        onPressAndHold: {
            if (root.managerCommand !== "") {
                managerProc.command = ["sh", "-c", root.managerCommand]
                managerProc.running = true
            }
        }
    }

    Process { id: toggleProc }
    Process { id: managerProc }

    // Tunda poll setelah toggle agar optimistic update tidak langsung
    // di-overwrite sebelum proses on/off sempat berjalan
    property bool _debouncing: false

    Timer {
        id: debounceTimer
        interval: 2000
        onTriggered: root._debouncing = false
    }

    Process {
        id: checkProc
        command: ["sh", "-c", root.checkCommand]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.includes(root.checkMatch)
        }
    }

    Timer {
        interval: 4000
        running: root.checkCommand !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!root._debouncing) checkProc.running = true
    }
}
