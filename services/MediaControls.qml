pragma Singleton

import QtQuick
import Quickshell

// Media Controls Service
// Handles media playback (play, pause, next, previous)

QtObject {
    id: root
    
    // Media state
    property bool isPlaying: false
    property string currentTrack: "No track"
    property string currentArtist: "Unknown"
    property string currentAlbum: "Unknown"
    property int duration: 0
    property int position: 0
    
    // Available players
    property list<string> availablePlayers: []
    property string activePlayer: ""
    
    // Methods
    function play() {
        root.isPlaying = true
        console.log(`[MediaControls] Playing: ${root.currentTrack}`)
    }
    
    function pause() {
        root.isPlaying = false
        console.log("[MediaControls] Paused")
    }
    
    function next() {
        console.log("[MediaControls] Next track")
    }
    
    function previous() {
        console.log("[MediaControls] Previous track")
    }
    
    function setPosition(ms) {
        root.position = ms
        console.log(`[MediaControls] Seeking to ${(ms / 1000).toFixed(1)}s`)
    }
    
    function getMediaInfo() {
        return {
            playing: root.isPlaying,
            track: root.currentTrack,
            artist: root.currentArtist,
            album: root.currentAlbum,
            position: root.position,
            duration: root.duration
        }
    }
    
    function getDebugInfo() {
        return root.getMediaInfo()
    }
    
    Component.onCompleted: {
        console.log("[MediaControls] Media controls service initialized")
    }
}
