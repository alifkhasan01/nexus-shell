import QtQml
import QtQuick
import Quickshell

// Service untuk state global shell
// Sumber kebenaran untuk panel-panel yang bisa di-toggle dari shortcut Hyprland
// maupun dari klik di Bar — accessible dari mana saja di aplikasi.
QtObject {
    id: shellState
    
    // Persistent state service
    PersistentState {
        id: persistentState
    }

    // Panel states
    property bool dashboardOpen:      false
    property bool powerMenuOpen:      false
    property bool wallpaperPanelOpen: false
    property bool menuOpen:           false
    property bool calendarOpen:       false
    property bool connectionOpen:     false
    property bool clipboardOpen:      false
    property bool idlePanelOpen:      false
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
            "idlePanel": function() { idlePanelOpen = !idlePanelOpen },
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
        idlePanelOpen = false
        welcomeOpen = false
    }

    // Logging helper
    function log(message) {
        console.log("[ShellState]", message)
    }

    // Load saved state on startup
    Component.onCompleted: {
        console.log("[ShellState] Loading persistent state...")
        const saved = persistentState.loadState()
        
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
    onDashboardOpenChanged: persistentState.set("dashboardOpen", dashboardOpen)
    onPowerMenuOpenChanged: persistentState.set("powerMenuOpen", powerMenuOpen)
    onWallpaperPanelOpenChanged: persistentState.set("wallpaperPanelOpen", wallpaperPanelOpen)
    onCalendarOpenChanged: persistentState.set("calendarOpen", calendarOpen)
    onConnectionOpenChanged: persistentState.set("connectionOpen", connectionOpen)
    onClipboardOpenChanged: persistentState.set("clipboardOpen", clipboardOpen)
    onMenuOpenChanged: persistentState.set("menuOpen", menuOpen)
    onWelcomeOpenChanged: persistentState.set("welcomeOpen", welcomeOpen)
}
