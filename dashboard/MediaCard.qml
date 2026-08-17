import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../" as Root

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 90
    radius: 16
    color: Root.Colors.surface0
    Behavior on color {
        ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }
    }

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
            radius: 32
            color: Root.Colors.surface1
            clip: true
            Behavior on color {
                ColorAnimation {
                    duration: Root.Appearance.animation.elementMoveFast.duration
                    easing.type: Root.Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Image {
                anchors.fill: parent
                source: root.hasPlayer ? root.player.trackArtUrl : ""
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: false
                visible: source !== ""

                RotationAnimator on rotation {
                    running: root.hasPlayer &&
                             root.player.playbackState === MprisPlaybackState.Playing &&
                             visible
                    from: 0; to: 360
                    duration: 16000
                    loops: Animation.Infinite
                }
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasPlayer || root.player.trackArtUrl === ""
                text: "󰝚"
                font.pixelSize: 24
                color: Root.Colors.subtext
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
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
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : ""
                color: Root.Colors.subtext
                font.pixelSize: 12
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }

            RowLayout {
                spacing: 14
                visible: root.hasPlayer

                Text {
                    text: "󰒮"
                    font.pixelSize: 16
                    color: Root.Colors.text
                    opacity: root.hasPlayer && root.player.canGoPrevious ? 1 : 0.35
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
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
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
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
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
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
