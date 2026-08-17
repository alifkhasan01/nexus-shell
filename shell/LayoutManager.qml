pragma Singleton

import QtQuick

// Layout Manager Service
// Manages alternative bar/panel layouts (Traditional, Waffle, Floating, etc)

QtObject {
    id: root
    
    // Available layouts
    enum LayoutType {
        Traditional,  // 0 - Current horizontal bar
        Waffle,       // 1 - Grid-based floating panels
        Floating,     // 2 - Floating widgets
        Compact,      // 3 - Minimal compact bar
        Vertical      // 4 - Vertical sidebar
    }
    
    // Current layout
    property int currentLayout: LayoutType.Traditional
    property string layoutName: "Traditional"
    
    // Layout properties
    property var layoutConfig: ({
        "Traditional": {
            position: "top",
            orientation: "horizontal",
            width: "100%",
            height: 45,
            opacity: 0.95,
            animationEnabled: true
        },
        "Waffle": {
            position: "top-right",
            orientation: "grid",
            width: 400,
            height: "auto",
            opacity: 0.9,
            columns: 4,
            animationEnabled: true
        },
        "Floating": {
            position: "custom",
            orientation: "floating",
            width: "auto",
            height: "auto",
            opacity: 0.85,
            animationEnabled: true
        },
        "Compact": {
            position: "top",
            orientation: "horizontal",
            width: "auto",
            height: 35,
            opacity: 0.95,
            animationEnabled: true
        },
        "Vertical": {
            position: "left",
            orientation: "vertical",
            width: 60,
            height: "100%",
            opacity: 0.95,
            animationEnabled: true
        }
    })
    
    // Layout preferences storage
    property string savedLayout: "Traditional"
    
    // Initialize layout manager
    function initialize() {
        console.log("[LayoutManager] Initializing layout manager...")
        loadSavedLayout()
    }
    
    // Get available layouts
    function getAvailableLayouts() {
        return [
            { name: "Traditional", value: LayoutType.Traditional, description: "Horizontal top bar" },
            { name: "Waffle", value: LayoutType.Waffle, description: "Grid-based floating" },
            { name: "Floating", value: LayoutType.Floating, description: "Floating widgets" },
            { name: "Compact", value: LayoutType.Compact, description: "Minimal compact" },
            { name: "Vertical", value: LayoutType.Vertical, description: "Vertical sidebar" }
        ]
    }
    
    // Switch layout
    function switchLayout(layoutType) {
        if (layoutType < 0 || layoutType > 4) {
            console.warn(`[LayoutManager] Invalid layout type: ${layoutType}`)
            return false
        }
        
        const layouts = ["Traditional", "Waffle", "Floating", "Compact", "Vertical"]
        const layoutName = layouts[layoutType]
        
        console.log(`[LayoutManager] Switching to layout: ${layoutName}`)
        
        root.currentLayout = layoutType
        root.layoutName = layoutName
        root.savedLayout = layoutName
        
        // Save preference
        saveLayoutPreference()
        
        return true
    }
    
    // Get layout config
    function getLayoutConfig(layoutName) {
        return root.layoutConfig[layoutName] ?? root.layoutConfig["Traditional"]
    }
    
    // Load saved layout preference
    function loadSavedLayout() {
        // TODO: Load from persistent storage
        console.log(`[LayoutManager] Loaded layout: ${root.savedLayout}`)
    }
    
    // Save layout preference
    function saveLayoutPreference() {
        // TODO: Save to persistent storage
        console.log(`[LayoutManager] Saved layout preference: ${root.layoutName}`)
    }
    
    // Get debug info
    function getDebugInfo() {
        return {
            currentLayout: root.layoutName,
            layouts: root.getAvailableLayouts(),
            config: root.getLayoutConfig(root.layoutName)
        }
    }
    
    // Auto-initialize
    Component.onCompleted: {
        Qt.callLater(function() {
            root.initialize()
        })
    }
}
