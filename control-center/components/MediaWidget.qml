pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Nunjukin player MPRIS yang lagi aktif (Spotify/mpv/browser/dll)
// Auto-pilih player yang statusnya Playing, fallback ke player pertama yg ada.
Rectangle {
    id: root

    readonly property var activePlayer: {
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const p = Mpris.players.values[i]
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    }

    visible: activePlayer !== null
    implicitHeight: visible ? 84 : 0
    radius: 16
    color: "#313244"

    Behavior on implicitHeight { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        visible: root.activePlayer !== null

        Rectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 12
            color: "#45475a"
            clip: true

            Image {
                anchors.fill: parent
                source: root.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: source.toString().length > 0
            }

            Text {
                anchors.centerIn: parent
                visible: !parent.children[0].visible
                text: "󰝚"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: "#cdd6f4"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.activePlayer?.trackTitle || "Nggak ada yang muter"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                color: "#cdd6f4"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.activePlayer?.trackArtist || ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: "#a6adc8"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 16
                Layout.topMargin: 4

                Text {
                    text: "󰒮"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: "#cdd6f4"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: root.activePlayer?.previous()
                    }
                }

                Text {
                    text: root.activePlayer?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: "#89b4fa"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: root.activePlayer?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: "#cdd6f4"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: root.activePlayer?.next()
                    }
                }
            }
        }
    }
}
