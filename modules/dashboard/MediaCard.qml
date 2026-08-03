import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../" as Root

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 90
    radius: 16
    color: Root.Colors.surface0

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Cover art
        Rectangle {
            width: 64
            height: 64
            radius: 12
            color: Root.Colors.surface1
            clip: true

            Image {
                anchors.fill: parent
                source: root.hasPlayer ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: source !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasPlayer || root.player.trackArtUrl === ""
                text: "󰝚"
                font.pixelSize: 24
                color: Root.Colors.subtext
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? (root.player.trackTitle || "Unknown Title") : "Tidak ada media diputar"
                color: Root.Colors.text
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : ""
                color: Root.Colors.subtext
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 14
                visible: root.hasPlayer

                Text {
                    text: "󰒮"
                    font.pixelSize: 16
                    color: Root.Colors.text
                    opacity: root.hasPlayer && root.player.canGoPrevious ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.hasPlayer && root.player.canGoPrevious) root.player.previous()
                    }
                }
                Text {
                    text: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    font.pixelSize: 18
                    color: Root.Colors.blue
                    opacity: root.hasPlayer && root.player.canControl ? 1 : 0.45
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.hasPlayer || !root.player.canControl) return
                            if (root.player.playbackState === MprisPlaybackState.Playing) {
                                root.player.pause()
                            } else {
                                root.player.play()
                            }
                        }
                    }
                }
                Text {
                    text: "󰒭"
                    font.pixelSize: 16
                    color: Root.Colors.text
                    opacity: root.hasPlayer && root.player.canGoNext ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.hasPlayer && root.player.canGoNext) root.player.next()
                    }
                }
            }
        }
    }
}
