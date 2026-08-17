import QtQml
import QtQuick
import Quickshell

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
    property bool welcomeOpen:        false

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
            "clipboard": function() { clipboardOpen = !clipboardOpen },
            "welcome": function() { welcomeOpen = !welcomeOpen }
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
        welcomeOpen = false
    }

    // Logging helper
    function log(message) {
        console.log("[ShellState]", message)
    }

    // Load saved state on startup
    Component.onCompleted: {
        console.log("[ShellState] Loading persistent state...")
        const saved = PersistentState.loadState()
        
        // Restore panel states
        shellState.dashboardOpen = saved.dashboardOpen ?? false
        shellState.powerMenuOpen = saved.powerMenuOpen ?? false
        shellState.wallpaperPanelOpen = saved.wallpaperPanelOpen ?? false
        shellState.calendarOpen = saved.calendarOpen ?? false
        shellState.connectionOpen = saved.connectionOpen ?? false
        shellState.clipboardOpen = saved.clipboardOpen ?? false
        shellState.menuOpen = saved.menuOpen ?? false
        shellState.welcomeOpen = saved.welcomeOpen ?? false
        
        console.log("[ShellState] State restored from persistent storage")
    }
    
    // Save state whenever any panel opens/closes
    onDashboardOpenChanged: PersistentState.set("dashboardOpen", dashboardOpen)
    onPowerMenuOpenChanged: PersistentState.set("powerMenuOpen", powerMenuOpen)
    onWallpaperPanelOpenChanged: PersistentState.set("wallpaperPanelOpen", wallpaperPanelOpen)
    onCalendarOpenChanged: PersistentState.set("calendarOpen", calendarOpen)
    onConnectionOpenChanged: PersistentState.set("connectionOpen", connectionOpen)
    onClipboardOpenChanged: PersistentState.set("clipboardOpen", clipboardOpen)
    onMenuOpenChanged: PersistentState.set("menuOpen", menuOpen)
    onWelcomeOpenChanged: PersistentState.set("welcomeOpen", welcomeOpen)
}
