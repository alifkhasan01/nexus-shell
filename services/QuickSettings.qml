pragma Singleton

import QtQuick

// Quick Settings Service  
// Manages quick access settings toggles

QtObject {
    id: root
    
    // Quick settings toggles
    property bool airplaneMode: false
    property bool dnd: false  // Do Not Disturb
    property bool darkMode: false
    property bool screenLock: false
    property bool blueLight: false
    property bool powerSaver: false
    property bool soundEnabled: true
    
    // Brightness and volume (shortcuts)
    property real brightness: 80
    property real volume: 70
    
    // Methods
    function toggleAirplaneMode() {
        root.airplaneMode = !root.airplaneMode
        console.log(`[QuickSettings] Airplane mode ${root.airplaneMode ? "on" : "off"}`)
    }
    
    function toggleDND() {
        root.dnd = !root.dnd
        console.log(`[QuickSettings] DND ${root.dnd ? "on" : "off"}`)
    }
    
    function toggleDarkMode() {
        root.darkMode = !root.darkMode
        console.log(`[QuickSettings] Dark mode ${root.darkMode ? "on" : "off"}`)
    }
    
    function setBrightness(value) {
        root.brightness = Math.max(0, Math.min(100, value))
        console.log(`[QuickSettings] Brightness set to ${root.brightness}%`)
    }
    
    function setVolume(value) {
        root.volume = Math.max(0, Math.min(100, value))
        console.log(`[QuickSettings] Volume set to ${root.volume}%`)
    }
    
    function getQuickSettings() {
        return {
            airplane: root.airplaneMode,
            dnd: root.dnd,
            darkMode: root.darkMode,
            brightness: root.brightness,
            volume: root.volume
        }
    }
    
    function getDebugInfo() {
        return root.getQuickSettings()
    }
    
    Component.onCompleted: {
        console.log("[QuickSettings] Quick settings service initialized")
    }
}
