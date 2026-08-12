import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../" as Root

// Panel riwayat notifikasi — slide dari kanan atas, mirip pola panel lain.
// Data notifikasi dibagikan via model dari luar (NotificationPopup sudah punya
// NotificationServer). Panel ini pakai server sendiri dengan keepOnReload: true
// supaya history tetap ada walau reload.
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notif-panel"
    WlrLayershell.exclusiveZone: 0

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 380
        height: Math.min(
            panelCol.implicitHeight + 24,
            root.height - 20
        )

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi slide dari atas ────────────────────────────────────────
        // Initial state: card tersembunyi dan posisi di atas (y: -50)
        opacity: 0
        transform: Translate { id: cardTranslate; y: -50 }

        // State management untuk animasi open/close notification panel
        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        // Transisi animasi untuk notification panel
        transitions: [
            // Animasi OPEN: Slide down dari atas dengan fade in
            // Duration: 220ms untuk smooth entrance
            Transition {
                from: ""; to: "open"
                NumberAnimation { target: cardTranslate; property: "y"; duration: 220; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
                OpacityAnimator { target: card; duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
            },
            // Animasi CLOSE: Slide up ke atas dengan fade out
            // Duration: 160ms untuk responsive exit
            // ScriptAction menyembunyikan panel setelah animasi selesai
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: 160; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                        OpacityAnimator { target: card; duration: 150; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: panelCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 8

            // ── Header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰂞  Notifikasi"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Badge jumlah
                Rectangle {
                    visible: Root.NotificationService.historyModel.count > 0
                    width: Math.max(22, countTxt.implicitWidth + 10)
                    height: 20
                    radius: 10
                    color: Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.2)
                    Text {
                        id: countTxt
                        anchors.centerIn: parent
                        text: Root.NotificationService.historyModel.count
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.blue
                    }
                }

                // Tombol hapus semua
                Rectangle {
                    visible: Root.NotificationService.historyModel.count > 0
                    width: clearTxt.implicitWidth + 14
                    height: 24
                    radius: 8
                    color: clearMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: clearTxt
                        anchors.centerIn: parent
                        text: "Hapus semua"
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                    }

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.NotificationService.clearHistory()
                    }
                }
            }

            // ── Kosong state ────────────────────────────────────────────────
            Item {
                visible: Root.NotificationService.historyModel.count === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: 80

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂚"
                        font.pixelSize: 28
                        color: Root.Colors.surface2
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Tidak ada notifikasi"
                        font.pixelSize: 12
                        color: Root.Colors.subtext
                    }
                }
            }

            // ── List notifikasi ─────────────────────────────────────────────
            Flickable {
                id: listFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Root.NotificationService.historyModel.count > 0
                implicitHeight: Math.min(notifCol.implicitHeight, 480)
                contentWidth: width
                contentHeight: notifCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notifCol
                    width: listFlick.width
                    spacing: 6

                    Repeater {
                        model: Root.NotificationService.historyModel

                        delegate: Loader {
                            required property var notif
                            required property int index
                            
                            width: notifCol.width
                            asynchronous: true
                            
                            sourceComponent: Rectangle {
                                width: notifCol.width
                                implicitHeight: itemCol.implicitHeight + 18
                                radius: 10
                                color: itemHover.containsMouse ? Root.Colors.surface0 : Root.Colors.base
                                Behavior on color { ColorAnimation { duration: 100 } }

                                border.color: {
                                    try {
                                        if (!notif) return Root.Colors.surface1
                                        switch (notif.urgency) {
                                            case NotificationUrgency.Critical: return Root.Colors.red
                                            default: return Root.Colors.surface1
                                        }
                                    } catch(e) {
                                        return Root.Colors.surface1
                                    }
                                }
                                border.width: 1

                                ColumnLayout {
                                    id: itemCol
                                    anchors {
                                        top: parent.top; left: parent.left; right: parent.right
                                        margins: 10
                                    }
                                    spacing: 2

                                    // Header: app name + dismiss
                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: {
                                                try { return notif?.appName ?? "" }
                                                catch(e) { return "" }
                                            }
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Root.Colors.subtext
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            width: 18; height: 18; radius: 5
                                            color: xMa.containsMouse ? Root.Colors.surface1 : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅖"; font.pixelSize: 10
                                                color: Root.Colors.subtext
                                            }
                                            MouseArea {
                                                id: xMa; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: Root.NotificationService.removeFromHistory(index)
                                            }
                                        }
                                    }

                                    Text {
                                        text: {
                                            try { return notif?.summary ?? "" }
                                            catch(e) { return "" }
                                        }
                                        visible: text !== ""
                                        font.pixelSize: 12; font.bold: true
                                        color: Root.Colors.text
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: {
                                            try { return notif?.body ?? "" }
                                            catch(e) { return "" }
                                        }
                                        visible: text !== ""
                                        font.pixelSize: 11
                                        color: Root.Colors.subtext
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        Layout.fillWidth: true
                                    }
                                }

                                HoverHandler { id: itemHover }
                            }
                        }
                    }
                }
            }
        }
    }
}
