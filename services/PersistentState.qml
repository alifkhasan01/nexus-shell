import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    
    // Path untuk save state
    property string stateDir: `${Directories.cache}/quickshell`
    property string stateFilePath: `${root.stateDir}/state.json`
    
    // Property untuk cache
    property var savedState: ({})
    
    // Create cache directory if not exists
    Component.onCompleted: {
        try {
            const dir = new File(root.stateDir)
            if (!dir.exists) {
                dir.mkpath()
                console.log("[PersistentState] Created cache directory:", root.stateDir)
            }
        } catch (e) {
            console.log("[PersistentState] Warning: Could not create cache directory:", e.toString())
        }
    }
    
    // Load state dari file
    function loadState() {
        try {
            const file = new TextFile(root.stateFilePath)
            const content = file.readAll()
            file.close()
            
            const parsed = JSON.parse(content)
            root.savedState = parsed
            
            console.log("[PersistentState] Loaded saved state:", JSON.stringify(parsed))
            return parsed
        } catch (e) {
            console.log("[PersistentState] No saved state found or invalid JSON:", e.toString())
            return {}
        }
    }
    
    // Save state ke file
    function saveState(state) {
        try {
            // Ensure directory exists
            const dir = new File(root.stateDir)
            if (!dir.exists) {
                dir.mkpath()
            }
            
            const json = JSON.stringify(state, null, 2)
            const file = new TextFile(root.stateFilePath)
            file.writeAll(json)
            file.close()
            
            console.log("[PersistentState] Saved state to:", root.stateFilePath)
        } catch (e) {
            console.log("[PersistentState] Failed to save state:", e.toString())
        }
    }
    
    // Get single value
    function get(key, defaultValue) {
        return root.savedState[key] ?? defaultValue
    }
    
    // Set single value dan save
    function set(key, value) {
        root.savedState[key] = value
        root.saveState(root.savedState)
    }
    
    // Debug info
    function getDebugInfo() {
        return {
            stateDir: root.stateDir,
            stateFilePath: root.stateFilePath,
            savedStateKeys: Object.keys(root.savedState),
            savedState: root.savedState
        }
    }
}
