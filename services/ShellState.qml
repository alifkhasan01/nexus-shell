import QtQml
import QtQuick

// Service untuk state global shell
// Sumber kebenaran untuk panel-panel yang bisa di-toggle dari shortcut Hyprland
// maupun dari klik di Bar — accessible dari mana saja di aplikasi.
QtObject {
    id: shellState

    // Panel states
    property bool dashboardOpen:      false
    property bool powerMenuOpen:      false
    property bool wallpaperPanelOpen: false
    property bool menuOpen:           false
    property bool calendarOpen:       false
    property bool connectionOpen:     false
    property bool clipboardOpen:      false

    // Settings
    property bool dnd:                false

    // References (akan di-inject dari shell.qml)
    property var wallpaperRandom: null
    property var lockFn: function() { console.warn("Lock function not initialized") }

    // Helper untuk toggle panel
    function togglePanel(panelName) {
        var panels = {
            "dashboard": function() { dashboardOpen = !dashboardOpen },
            "powerMenu": function() { powerMenuOpen = !powerMenuOpen },
            "wallpaperPanel": function() { wallpaperPanelOpen = !wallpaperPanelOpen },
            "menu": function() { menuOpen = !menuOpen },
            "calendar": function() { calendarOpen = !calendarOpen },
            "connection": function() { connectionOpen = !connectionOpen },
            "clipboard": function() { clipboardOpen = !clipboardOpen }
        }

        if (panels[panelName]) {
            panels[panelName]()
        } else {
            console.warn("Unknown panel:", panelName)
        }
    }

    // Helper untuk close semua panels
    function closeAllPanels() {
        dashboardOpen = false
        powerMenuOpen = false
        wallpaperPanelOpen = false
        menuOpen = false
        calendarOpen = false
        connectionOpen = false
        clipboardOpen = false
    }

    // Logging helper
    function log(message) {
        console.log("[ShellState]", message)
    }
}
