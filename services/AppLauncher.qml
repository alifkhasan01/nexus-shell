pragma Singleton

import QtQuick
import Quickshell

// App Launcher Service
// Manages application launching and quick access

QtObject {
    id: root
    
    // App categories
    property list<string> categories: ["All", "Development", "Internet", "Multimedia", "Office", "System", "Utilities"]
    
    // Pinned apps
    property list<string> pinnedApps: ["firefox", "thunderbird", "vscode", "files", "terminal"]
    
    // Recent apps
    property list<string> recentApps: []
    
    // Available apps
    property list<string> availableApps: []
    
    // Methods
    function launchApp(appName) {
        console.log(`[AppLauncher] Launching app: ${appName}`)
        // TODO: Execute app
    }
    
    function pinApp(appName) {
        if (!root.pinnedApps.includes(appName)) {
            root.pinnedApps.push(appName)
            console.log(`[AppLauncher] Pinned app: ${appName}`)
        }
    }
    
    function unpinApp(appName) {
        const index = root.pinnedApps.indexOf(appName)
        if (index > -1) {
            root.pinnedApps.splice(index, 1)
            console.log(`[AppLauncher] Unpinned app: ${appName}`)
        }
    }
    
    function getPinnedApps() {
        return root.pinnedApps
    }
    
    function getAppsByCategory(category) {
        if (category === "All") return root.availableApps
        // TODO: Filter by category
        return []
    }
    
    function getDebugInfo() {
        return {
            pinned: root.pinnedApps,
            recent: root.recentApps,
            available: root.availableApps.length
        }
    }
    
    Component.onCompleted: {
        console.log("[AppLauncher] App launcher service initialized")
    }
}
