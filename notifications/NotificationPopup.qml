import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../" as Root

// ── Popup notifikasi di atas bar ──────────────────────────────────────────
// Pakai NotificationServer bawaan Quickshell — tidak butuh swaync.
// Stack kartu tumbuh ke atas dari bar, notif terbaru paling bawah.
PanelWindow {
    id: root

    // DND: saat true, notif masuk tetap di-track tapi popup tidak ditampilkan
    property bool dnd: false

    anchors { top: true; left: true; right: true }
    // tepat di bawah bar (bar height 45 + margin top 8 + gap 6)
    margins.top: 10

    // Tinggi window = tinggi semua kartu aktif, atau minimal 1 px
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    visible: true

    WlrLayershell.layer:           WlrLayer.Overlay
    WlrLayershell.namespace:       "quickshell-notif"
    WlrLayershell.exclusiveZone:   0
    WlrLayershell.keyboardFocus:   WlrKeyboardFocus.None

    // ── Model untuk popup (notifikasi sementara) ──────────────────────────
    ListModel { id: notifModel }

    // ── Koneksi ke NotificationService ────────────────────────────────────
    Connections {
        target: Root.NotificationService
        function onNewNotification(notif) {
            // DND: blokir popup kecuali notif Critical
            if (root.dnd && notif.urgency !== NotificationUrgency.Critical) return
            notifModel.append({ "notif": notif })
        }
    }

    // ── Stack kartu (tumbuh ke atas) ──────────────────────────────────────
    Column {
        id: stack
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 420
        spacing: 6
    }

    // ── Delegate kartu ────────────────────────────────────────────────────
    Repeater {
        id: notifRepeater
        model: notifModel
        parent: stack

        delegate: NotifCard {
            required property var notif
            required property int index

            width: stack.width
            notification: notif

            onDismissed: {
                notifModel.remove(index)
            }
        }
    }

    // ── Komponen kartu ────────────────────────────────────────────────────
    component NotifCard: Item {
        id: card

        property var notification: null
        signal dismissed()

        implicitHeight: cardRect.height
        height: implicitHeight
        clip: false

        // ── Animasi masuk ─────────────────────────────────────────────────
        opacity: 0
        transform: Translate { id: slideT; y: 12 }

        ParallelAnimation {
            id: enterAnim
            running: false
            NumberAnimation { target: card;   property: "opacity"; from: 0; to: 1; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
            NumberAnimation { target: slideT; property: "y";       from: -12; to: 0; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
        }

        // ── Animasi keluar ────────────────────────────────────────────────
        ParallelAnimation {
            id: exitAnim
            running: false
            NumberAnimation { target: card;   property: "opacity"; to: 0; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
            NumberAnimation { target: slideT; property: "y";       to: -10; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
            onFinished: card.dismissed()
        }

        Component.onCompleted: enterAnim.start()

        // ── Auto-dismiss ──────────────────────────────────────────────────
        // Normal: 2.5 detik, Critical: 5 detik
        readonly property int timeoutMs: {
            if (!notification) return 2500
            const t = notification.expireTimeout
            if (t > 0) return Math.min(t * 1000, 5000)
            return notification.urgency === NotificationUrgency.Critical ? 5000 : 2500
        }

        Timer {
            id: dismissTimer
            interval: card.timeoutMs
            running:  card.timeoutMs > 0
            onTriggered: card.doClose()
        }

        function doClose() {
            if (exitAnim.running) return
            dismissTimer.stop()
            if (notification) notification.expire()
            exitAnim.start()
        }

        // ── Kartu visual ──────────────────────────────────────────────────
        Rectangle {
            id: cardRect
            width: parent.width
            implicitHeight: innerCol.implicitHeight + 22
            height: implicitHeight
            radius: 14
            color: Root.Colors.mantle
            border.width: 2
            border.color: {
                if (!notification) return Root.Colors.surface2
                switch (notification.urgency) {
                    case NotificationUrgency.Critical: return Root.Colors.red
                    case NotificationUrgency.Low:      return Root.Colors.surface1
                    default:                           return Root.Colors.surface2
                }
            }

            Behavior on color        { ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }}
            Behavior on border.color { ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }}

            // ── Konten ────────────────────────────────────────────────────
            ColumnLayout {
                id: innerCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 12
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 4

                // ── Header: nama app + badge + tutup ─────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Nama app
                    Text {
                        text: notification?.appName ?? ""
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Badge critical
                    Rectangle {
                        visible: notification?.urgency === NotificationUrgency.Critical
                        width: critTxt.implicitWidth + 10
                        height: 15
                        radius: 4
                        color: Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                        Text {
                            id: critTxt
                            anchors.centerIn: parent
                            text: "CRITICAL"
                            font.pixelSize: 9
                            font.bold: true
                            color: Root.Colors.red
                        }
                    }

                    // Tombol tutup
                    Rectangle {
                        width: 20; height: 20
                        radius: 6
                        color: xMa.containsMouse ? Root.Colors.surface1 : "transparent"
                        Behavior on color { ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }}
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                        }
                        MouseArea {
                            id: xMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.doClose()
                        }
                    }
                }

                // ── Summary ───────────────────────────────────────────────
                Text {
                    text: notification?.summary ?? ""
                    visible: text !== ""
                    font.pixelSize: 13
                    font.bold: true
                    color: Root.Colors.text
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Behavior on color { ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }}
                }

                // ── Body ──────────────────────────────────────────────────
                Text {
                    text: notification?.body ?? ""
                    visible: text !== ""
                    font.pixelSize: 12
                    color: Root.Colors.subtext
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    Layout.bottomMargin: actRow.visible ? 2 : 6
                    Behavior on color { ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }}
                }

                // ── Tombol aksi ───────────────────────────────────────────
                RowLayout {
                    id: actRow
                    visible: (notification?.actions?.length ?? 0) > 0
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    spacing: 6

                    Repeater {
                        model: notification?.actions ?? []
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 28
                            radius: 7
                            color: aMa.containsMouse ? Root.Colors.blue : Root.Colors.surface0
                            Behavior on color { ColorAnimation {
                                duration: Root.Appearance.animation.elementMoveFast.duration
                                easing.type: Root.Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                            }}
                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                font.pixelSize: 11
                                color: aMa.containsMouse ? Root.Colors.base : Root.Colors.text
                                Behavior on color { ColorAnimation {
                                    duration: Root.Appearance.animation.elementMoveFast.duration
                                    easing.type: Root.Appearance.animation.elementMoveFast.type
                                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                                }}
                            }
                            MouseArea {
                                id: aMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { modelData.invoke(); card.doClose() }
                            }
                        }
                    }
                }


            }

            // ── Hover → pause timer ───────────────────────────────────────
            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        dismissTimer.stop()
                    } else {
                        if (card.timeoutMs > 0) {
                            dismissTimer.interval = card.timeoutMs
                            dismissTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
