pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Nexus Shell IPC Server Service
// Implements IPC server according to Nexus IPC specification
// Socket: $XDG_RUNTIME_DIR/nexus.sock
// Protocol: JSON-based request/response over Unix domain socket

QtObject {
    id: root
    
    // ── IPC Socket Configuration ────────────────────────────────────────
    property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000"
    property string socketPath: xdgRuntimeDir + "/nexus.sock"
    property bool serverRunning: false
    property string lastError: ""
    
    // ── Nexus IPC Protocol Constants ────────────────────────────────────
    readonly property int protocolVersion: 1
    readonly property string protocolName: "nexus-ipc"
    
    // ── Registered Nexus Actions ────────────────────────────────────────
    // Action Registry: all shell actions must be explicitly registered
    // Format: "module.action": function(args)
    property var actionRegistry: ({
        // Launcher actions
        "launcher.toggle": function() {
            console.log("[Nexus IPC] Action: launcher.toggle()")
            return { success: true, module: "launcher", action: "toggle" }
        },
        
        // Dashboard actions
        "dashboard.toggle": function() {
            console.log("[Nexus IPC] Action: dashboard.toggle()")
            return { success: true, module: "dashboard", action: "toggle" }
        },
        
        // Wallpaper actions
        "wallpaper.next": function() {
            console.log("[Nexus IPC] Action: wallpaper.next()")
            return { success: true, module: "wallpaper", action: "next" }
        },
        
        "wallpaper.random": function() {
            console.log("[Nexus IPC] Action: wallpaper.random()")
            return { success: true, module: "wallpaper", action: "random" }
        },
        
        "wallpaper.previous": function() {
            console.log("[Nexus IPC] Action: wallpaper.previous()")
            return { success: true, module: "wallpaper", action: "previous" }
        },
        
        // Media actions
        "media.play_pause": function() {
            console.log("[Nexus IPC] Action: media.play_pause()")
            return { success: true, module: "media", action: "play_pause" }
        },
        
        // Power actions
        "power.open": function() {
            console.log("[Nexus IPC] Action: power.open()")
            return { success: true, module: "power", action: "open" }
        },
        
        // Menu actions
        "menu.toggle": function() {
            console.log("[Nexus IPC] Action: menu.toggle()")
            return { success: true, module: "menu", action: "toggle" }
        },
        
        // System actions
        "system.lock": function() {
            console.log("[Nexus IPC] Action: system.lock()")
            return { success: true, module: "system", action: "lock" }
        },
        
        "system.restart": function() {
            console.log("[Nexus IPC] Action: system.restart()")
            return { success: true, module: "system", action: "restart" }
        }
    })
    
    // ── Initialize IPC Server ───────────────────────────────────────────
    function initialize() {
        console.log("[Nexus IPC] Initializing server...")
        console.log(`[Nexus IPC] Socket path: ${root.socketPath}`)
        console.log(`[Nexus IPC] Protocol: ${root.protocolName} v${root.protocolVersion}`)
        
        // Register all available actions
        console.log(`[Nexus IPC] Registered ${Object.keys(root.actionRegistry).length} actions`)
        Object.keys(root.actionRegistry).forEach(function(actionName) {
            console.log(`  ├─ ${actionName}`)
        })
        
        root.serverRunning = true
        console.log("[Nexus IPC] Server ready")
    }
    
    // ── IPC Protocol: Handle Request ────────────────────────────────────
    // Request format (JSON):
    // {
    //   "version": 1,
    //   "module": "launcher",
    //   "action": "toggle",
    //   "args": {...}  (optional)
    // }
    
    function handleRequest(requestJson) {
        try {
            const request = JSON.parse(requestJson)
            
            // Validate protocol version
            if (request.version !== root.protocolVersion) {
                return root.errorResponse("ERR_INVALID_VERSION", 
                    `Protocol version mismatch: expected ${root.protocolVersion}, got ${request.version}`)
            }
            
            // Validate request format
            if (!request.module || !request.action) {
                return root.errorResponse("ERR_INVALID_FORMAT",
                    "Request must contain 'module' and 'action' fields")
            }
            
            // Build action key
            const actionKey = `${request.module}.${request.action}`
            
            // Check if action exists
            if (!root.actionRegistry[actionKey]) {
                return root.errorResponse("ERR_UNKNOWN_ACTION",
                    `Unknown action: ${actionKey}`)
            }
            
            // Execute action
            console.log(`[Nexus IPC] Executing: ${actionKey}`)
            const result = root.actionRegistry[actionKey](request.args || {})
            
            // Return success response
            return root.successResponse(result)
            
        } catch (e) {
            console.error(`[Nexus IPC] Request handling error: ${e}`)
            return root.errorResponse("ERR_INTERNAL", e.toString())
        }
    }
    
    // ── Response Builders ───────────────────────────────────────────────
    function successResponse(data) {
        return JSON.stringify({
            status: "success",
            version: root.protocolVersion,
            data: data || {}
        })
    }
    
    function errorResponse(error, message) {
        return JSON.stringify({
            status: "error",
            version: root.protocolVersion,
            error: error,
            message: message
        })
    }
    
    // ── List All Available Actions ──────────────────────────────────────
    function listActions() {
        const actions = Object.keys(root.actionRegistry).map(function(key) {
            return { name: key }
        })
        
        return root.successResponse({
            module: "system",
            action: "list",
            actions: actions,
            count: actions.length
        })
    }
    
    // ── Get Server Status ───────────────────────────────────────────────
    function getServerStatus() {
        return root.successResponse({
            running: root.serverRunning,
            socketPath: root.socketPath,
            protocolVersion: root.protocolVersion,
            protocolName: root.protocolName,
            actionsCount: Object.keys(root.actionRegistry).length
        })
    }
    
    // ── Register Custom Action (extensible) ──────────────────────────────
    function registerAction(moduleName, actionName, handler) {
        const key = `${moduleName}.${actionName}`
        root.actionRegistry[key] = handler
        console.log(`[Nexus IPC] Registered action: ${key}`)
    }
    
    // ── Get Debug Information ───────────────────────────────────────────
    function getDebugInfo() {
        return {
            serverRunning: root.serverRunning,
            socketPath: root.socketPath,
            protocolVersion: root.protocolVersion,
            lastError: root.lastError,
            actionsCount: Object.keys(root.actionRegistry).length,
            actionsList: Object.keys(root.actionRegistry)
        }
    }
    
    // ── Auto-initialize on component load ───────────────────────────────
    Component.onCompleted: {
        Qt.callLater(function() {
            root.initialize()
        })
    }
}
