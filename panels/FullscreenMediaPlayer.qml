import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell.Services.Mpris
import "../services" as Services
import "../dashboard" as Dashboard

/**
 * FullscreenMediaPlayer.qml
 * Fullscreen music player panel dengan rotating album cover
 * 
 * Like: Caelestia, GNOME Music, modern music players
 * 
 * Features:
 * - Large rotating album artwork
 * - Complete playback controls
 * - Track info display
 * - Timeline/progress bar
 * - Modern glassmorphism design
 * - Smooth animations
 */

Rectangle {
    id: root
    
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    
    color: "#0a0a0f"
    
    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0a0f" }
            GradientStop { position: 1.0; color: "#1a1a2e" }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 32
        
        // Header - close button
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "✕"
                font.pixelSize: 20
                background: Rectangle {
                    color: hovered ? "#2a2a3e" : "transparent"
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                onClicked: root.visible = false
            }
        }
        
        // Main content area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 40
            alignment: Qt.AlignHCenter
            
            // Rotating album cover - centered and large
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 320
                height: 320
                
                // Main rotating image with glow
                Rectangle {
                    anchors.fill: parent
                    radius: parent.width / 2
                    color: "#1a1a2e"
                    
                    // Multiple border rings untuk effect
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: "#9C6FDE"
                        border.width: 3
                        opacity: 0.5
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: "#9C6FDE"
                        border.width: 1
                        opacity: 0.3
                        anchors.margins: 8
                    }
                    
                    // Album art image
                    Image {
                        id: albumArt
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: parent.height - 12
                        sourceSize: Qt.size(width, height)
                        source: root.hasPlayer ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        
                        layer.enabled: true
                        layer.smooth: true
                        
                        // Rotation animation
                        transform: Rotation {
                            id: coverRotation
                            origin.x: albumArt.width / 2
                            origin.y: albumArt.height / 2
                            angle: 0
                        }
                        
                        RotationAnimation {
                            target: coverRotation
                            from: 0
                            to: 360
                            duration: 20000
                            running: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing
                            loops: Animation.Infinite
                        }
                        
                        // Fallback icon if no cover
                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            font.pixelSize: 64
                            color: "#666"
                            visible: albumArt.source === "" || albumArt.status === Image.Error
                        }
                    }
                    
                    // Glow effect
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: "#9C6FDE"
                        border.width: 8
                        opacity: 0.2
                    }
                }
                
                // Shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.leftMargin: 4
                    radius: parent.width / 2
                    color: "#9C6FDE"
                    opacity: 0.1
                    z: -1
                }
            }
            
            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                
                Text {
                    text: root.hasPlayer ? (root.player.trackTitle || "Unknown Track") : "No media"
                    color: "#ffffff"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                
                Text {
                    text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : ""
                    color: "#9C9CAC"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                
                Text {
                    text: root.hasPlayer ? (root.player.trackAlbum || "") : ""
                    color: "#6a6a80"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
            
            Item { Layout.fillHeight: true }
            
            // Progress bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.hasPlayer
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: "#2a2a3e"
                    
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: "#9C6FDE"
                        width: root.hasPlayer && root.player.length > 0 
                            ? parent.width * (root.player.position / root.player.length)
                            : 0
                        
                        Behavior on width {
                            NumberAnimation { duration: 100 }
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: formatTime(root.hasPlayer ? root.player.position : 0)
                        color: "#9C9CAC"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: formatTime(root.hasPlayer ? root.player.length : 0)
                        color: "#9C9CAC"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }
            
            // Control buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 24
                
                visible: root.hasPlayer
                
                // Shuffle
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: root.hasPlayer && root.player.shuffle ? "#9C6FDE" : "#2a2a3e"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰒗"
                        color: root.hasPlayer && root.player.shuffle ? "#ffffff" : "#6a6a80"
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.hasPlayer) root.player.shuffle = !root.player.shuffle
                    }
                }
                
                // Previous
                Rectangle {
                    width: 56
                    height: 56
                    radius: 28
                    color: "#2a2a3e"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: root.hasPlayer && root.player.canGoPrevious ? "#ffffff" : "#6a6a80"
                        font.pixelSize: 24
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.hasPlayer && root.player.canGoPrevious) root.player.previous()
                    }
                }
                
                // Play/Pause
                Rectangle {
                    width: 72
                    height: 72
                    radius: 36
                    color: "#9C6FDE"
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        color: "#ffffff"
                        font.pixelSize: 32
                    }
                    
                    MouseArea {
                        anchors.fill: parent
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
                
                // Next
                Rectangle {
                    width: 56
                    height: 56
                    radius: 28
                    color: "#2a2a3e"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: root.hasPlayer && root.player.canGoNext ? "#ffffff" : "#6a6a80"
                        font.pixelSize: 24
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.hasPlayer && root.player.canGoNext) root.player.next()
                    }
                }
                
                // Repeat
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: root.hasPlayer && root.player.loopStatus !== MprisLoopStatus.None ? "#9C6FDE" : "#2a2a3e"
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.hasPlayer && root.player.loopStatus === MprisLoopStatus.Track ? "󰑘" : "󰑖"
                        color: root.hasPlayer && root.player.loopStatus !== MprisLoopStatus.None ? "#ffffff" : "#6a6a80"
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.hasPlayer) return
                            let next = root.player.loopStatus === MprisLoopStatus.None 
                                ? MprisLoopStatus.Playlist
                                : root.player.loopStatus === MprisLoopStatus.Playlist
                                    ? MprisLoopStatus.Track
                                    : MprisLoopStatus.None
                            root.player.loopStatus = next
                        }
                    }
                }
            }
        }
    }
    
    // Utility function untuk format waktu
    function formatTime(ms) {
        const seconds = Math.floor(ms / 1000)
        const minutes = Math.floor(seconds / 60)
        const hours = Math.floor(minutes / 60)
        
        const s = (seconds % 60).toString().padStart(2, '0')
        const m = (minutes % 60).toString().padStart(2, '0')
        
        if (hours > 0) {
            const h = hours.toString().padStart(2, '0')
            return `${h}:${m}:${s}`
        } else {
            return `${m}:${s}`
        }
    }
}
