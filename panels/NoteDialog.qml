import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as Root

// Dialog untuk menulis catatan harian
Rectangle {
    id: dialog

    property int year
    property int month
    property int day
    property string noteText: ""
    property bool showing: false

    signal accepted()
    signal cancelled()

    anchors.fill: parent
    color: "#80000000"
    visible: showing
    z: 1000

    opacity: showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.cancelled()
    }

    // Dialog card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 380
        height: content.implicitHeight + 32
        radius: 16
        color: Root.Colors.base
        border.color: Root.Colors.surface2
        border.width: 2

        scale: dialog.showing ? 1 : 0.9
        Behavior on scale { NumberAnimation { duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve } }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Block clicks
        }

        ColumnLayout {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 12

            // Title
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰠮 Catatan Harian"
                    font.pixelSize: 16
                    font.bold: true
                    color: Root.Colors.text
                    font.family: "CaskaydiaCove Nerd Font"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: noteTextArea.text.length + " karakter"
                    font.pixelSize: 10
                    color: Root.Colors.overlay1
                }
            }

            // Date info
            Text {
                text: `${day} ${["Januari","Februari","Maret","April","Mei","Juni","Juli","Agustus","September","Oktober","November","Desember"][month]} ${year}`
                font.pixelSize: 12
                color: Root.Colors.subtext
            }

            // Note text area
            Rectangle {
                Layout.fillWidth: true
                height: 200
                radius: 8
                color: Root.Colors.surface0
                border.color: noteTextArea.activeFocus ? Root.Colors.blue : "transparent"
                border.width: 2

                Flickable {
                    id: noteFlickable
                    anchors {
                        fill: parent
                        margins: 10
                    }
                    contentWidth: width
                    contentHeight: noteTextArea.implicitHeight
                    clip: true

                    TextEdit {
                        id: noteTextArea
                        width: noteFlickable.width
                        text: dialog.noteText
                        font.pixelSize: 13
                        color: Root.Colors.text
                        wrapMode: TextEdit.Wrap
                        selectionColor: Root.Colors.blue
                        selectByMouse: true

                        Text {
                            visible: noteTextArea.text === ""
                            anchors.fill: parent
                            text: "Tulis catatan di sini...\n\nContoh:\n• Hari ini meeting dengan tim\n• Selesaikan laporan bulanan\n• Jangan lupa belanja"
                            font.pixelSize: 13
                            color: Root.Colors.overlay0
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // Scrollbar
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        margins: 4
                    }
                    width: 6
                    radius: 3
                    color: Root.Colors.surface1
                    visible: noteFlickable.contentHeight > noteFlickable.height

                    Rectangle {
                        width: parent.width
                        height: Math.max(20, (noteFlickable.height / noteFlickable.contentHeight) * parent.height)
                        y: (noteFlickable.contentY / noteFlickable.contentHeight) * parent.height
                        radius: 3
                        color: Root.Colors.overlay0
                    }
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: cancelMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    border.color: Root.Colors.surface2
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Batal"
                        font.pixelSize: 13
                        font.bold: true
                        color: Root.Colors.text
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            noteTextArea.text = ""
                            dialog.cancelled()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: saveMa.containsMouse ? Qt.darker(Root.Colors.blue, 1.1) : Root.Colors.blue

                    Text {
                        anchors.centerIn: parent
                        text: noteTextArea.text.trim() === "" ? "Hapus Catatan" : "Simpan"
                        font.pixelSize: 13
                        font.bold: true
                        color: Root.Colors.base
                    }

                    MouseArea {
                        id: saveMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dialog.noteText = noteTextArea.text
                            dialog.accepted()
                            noteTextArea.text = ""
                        }
                    }
                }
            }
        }
    }

    // Reset on show
    onShowingChanged: {
        if (showing) {
            noteTextArea.text = noteText
            noteTextArea.forceActiveFocus()
        }
    }
}
