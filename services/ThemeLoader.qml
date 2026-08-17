pragma Singleton

import QtQuick
import Quickshell

// Theme Loader Service
// Detects system theme and synchronizes with Colors.qml for Material Design integration

QtObject {
    id: root
    
    // Available themes
    readonly property list<string> themes: ["light", "dark"]
    readonly property list<string> systemThemes: ["light", "dark", "auto"]
    
    // Current settings
    property string currentTheme: "dark"
    property string systemTheme: "auto"
    property bool autoSync: true
    property bool initialized: false
    
    // Detect system theme (DBus call to settings service)
    property Process themeDetector: Process {
        command: ["sh", "-c",
            "gsettings get org.gnome.desktop.interface gtk-application-prefer-dark-mode 2>/dev/null || " +
            "dconf read /org/gnome/desktop/interface/gtk-application-prefer-dark-mode 2>/dev/null || " +
            "echo 'null'"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                
                // Parse output: true = dark, false = light, null = use default
                let detected = root.currentTheme
                
                if (output === "true") {
                    detected = "dark"
                } else if (output === "false") {
                    detected = "light"
                } else if (output === "null" || output === "") {
                    // Fallback: check if dark theme is preferred
                    detected = "dark"  // Default preference
                }
                
                console.log(`[ThemeLoader] System theme detected: ${detected}`)
                
                // Only apply if auto-sync is enabled
                if (root.autoSync) {
                    root.syncTheme(detected)
                }
            }
        }
    }
    
    // File watcher for config changes
    property Process configWatcher: Timer {
        id: configWatchTimer
        interval: 5000  // Check every 5 seconds
        repeat: true
        running: root.initialized && root.autoSync
        
        onTriggered: {
            root.detectSystemTheme()
        }
    }
    
    // Initialize theme loader
    function initialize() {
        console.log("[ThemeLoader] Initializing theme loader...")
        
        // Load saved theme preference
        loadSavedTheme()
        
        // Detect system theme
        detectSystemTheme()
        
        root.initialized = true
        console.log(`[ThemeLoader] Initialized with theme: ${root.currentTheme}`)
    }
    
    // Load saved theme from file
    function loadSavedTheme() {
        // Theme is already saved by Colors.qml
        // This just reads the current Colors.currentTheme value
        console.log("[ThemeLoader] Loading saved theme preference...")
    }
    
    // Detect system theme preference
    function detectSystemTheme() {
        console.log("[ThemeLoader] Detecting system theme...")
        themeDetector.running = true
    }
    
    // Sync theme with system
    function syncTheme(theme) {
        if (!root.themes.includes(theme)) {
            console.warn(`[ThemeLoader] Invalid theme: ${theme}`)
            return
        }
        
        console.log(`[ThemeLoader] Syncing theme to: ${theme}`)
        root.currentTheme = theme
        
        // Update Colors singleton
        if (Colors) {
            Colors.currentTheme = theme
        }
    }
    
    // Toggle between light and dark
    function toggle() {
        const newTheme = root.currentTheme === "light" ? "dark" : "light"
        root.syncTheme(newTheme)
        console.log(`[ThemeLoader] Toggled theme to: ${newTheme}`)
    }
    
    // Set auto-sync
    function setAutoSync(enabled) {
        root.autoSync = enabled
        console.log(`[ThemeLoader] Auto-sync ${enabled ? "enabled" : "disabled"}`)
        
        if (enabled && root.initialized) {
            detectSystemTheme()
        }
    }
    
    // Get current theme info
    function getThemeInfo() {
        return {
            current: root.currentTheme,
            system: root.systemTheme,
            autoSync: root.autoSync,
            available: root.themes,
            isDark: root.currentTheme === "dark"
        }
    }
    
    // Get debug info
    function getDebugInfo() {
        return {
            initialized: root.initialized,
            currentTheme: root.currentTheme,
            systemTheme: root.systemTheme,
            autoSync: root.autoSync,
            themes: root.themes
        }
    }
    
    // Auto-initialize on load
    Component.onCompleted: {
        // Defer initialization to avoid circular imports
        Qt.callLater(function() {
            root.initialize()
        })
    }
}
