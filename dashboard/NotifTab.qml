pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../" as Root

// Tab Notifikasi di Dashboard — riwayat notifikasi dari NotificationService.
// Content dipindah dari panels/NotificationPanel.qml (PanelWindow → tab).

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

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

        // ── Divider ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            color: Root.Colors.surface1
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // ── Kosong state ────────────────────────────────────────────────
        Item {
            visible: Root.NotificationService.historyModel.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

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