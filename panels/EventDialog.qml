import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as Root

// Dialog untuk menambah/edit event
Rectangle {
    id: dialog

    property int year
    property int month
    property int day
    property string eventTitle: ""
    property string eventTime: ""
    property string eventColor: "#89b4fa"
    property bool showing: false

    signal accepted()
    signal cancelled()

    anchors.fill: parent
    color: "#80000000"
    visible: showing
    z: 1000

    opacity: showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.cancelled()
    }

    // Dialog card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 340
        height: content.implicitHeight + 32
        radius: 16
        color: Root.Colors.base
        border.color: Root.Colors.surface2
        border.width: 2

        scale: dialog.showing ? 1 : 0.9
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

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
            Text {
                text: " Tambah Event"
                font.pixelSize: 16
                font.bold: true
                color: Root.Colors.text
                font.family: "CaskaydiaCove Nerd Font"
            }

            // Date info
            Text {
                text: `${day} ${["Jan","Feb","Mar","Apr","Mei","Jun","Jul","Ags","Sep","Okt","Nov","Des"][month]} ${year}`
                font.pixelSize: 12
                color: Root.Colors.subtext
            }

            // Event title input
            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Judul Event"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Root.Colors.surface0
                    border.color: titleInput.activeFocus ? Root.Colors.blue : "transparent"
                    border.width: 2

                    TextInput {
                        id: titleInput
                        anchors {
                            fill: parent
                            margins: 10
                        }
                        text: dialog.eventTitle
                        font.pixelSize: 13
                        color: Root.Colors.text
                        selectionColor: Root.Colors.blue
                        selectByMouse: true
                        clip: true

                        Text {
                            visible: titleInput.text === ""
                            anchors.fill: parent
                            text: "Contoh: Meeting dengan klien"
                            font.pixelSize: 13
                            color: Root.Colors.overlay0
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // Event time input
            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Waktu (opsional)"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Root.Colors.surface0
                    border.color: timeInput.activeFocus ? Root.Colors.blue : "transparent"
                    border.width: 2

                    TextInput {
                        id: timeInput
                        anchors {
                            fill: parent
                            margins: 10
                        }
                        text: dialog.eventTime
                        font.pixelSize: 13
                        color: Root.Colors.text
                        selectionColor: Root.Colors.blue
                        selectByMouse: true
                        clip: true

                        Text {
                            visible: timeInput.text === ""
                            anchors.fill: parent
                            text: "Contoh: 14:00 atau 2 PM"
                            font.pixelSize: 13
                            color: Root.Colors.overlay0
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // Color picker
            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Warna"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                }

                Row {
                    spacing: 8
                    readonly property var colors: [
                        "#89b4fa", "#f38ba8", "#a6e3a1", "#fab387",
                        "#f9e2af", "#cba6f7", "#89dceb", "#f5c2e7"
                    ]

                    Repeater {
                        model: parent.colors
                        delegate: Rectangle {
                            required property string modelData
                            width: 32
                            height: 32
                            radius: 16
                            color: modelData
                            border.color: dialog.eventColor === modelData ? Root.Colors.text : "transparent"
                            border.width: 2

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dialog.eventColor = modelData
                            }
                        }
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
                            titleInput.text = ""
                            timeInput.text = ""
                            dialog.cancelled()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: saveMa.containsMouse ? Qt.darker(Root.Colors.blue, 1.1) : Root.Colors.blue
                    enabled: titleInput.text.trim() !== ""
                    opacity: enabled ? 1 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: "Simpan"
                        font.pixelSize: 13
                        font.bold: true
                        color: Root.Colors.base
                    }

                    MouseArea {
                        id: saveMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: titleInput.text.trim() !== ""
                        onClicked: {
                            dialog.eventTitle = titleInput.text
                            dialog.eventTime = timeInput.text
                            dialog.accepted()
                            titleInput.text = ""
                            timeInput.text = ""
                        }
                    }
                }
            }
        }
    }

    // Reset on show
    onShowingChanged: {
        if (showing) {
            titleInput.text = eventTitle
            timeInput.text = eventTime
            titleInput.forceActiveFocus()
        }
    }
}
