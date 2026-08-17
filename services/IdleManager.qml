pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Service untuk mengelola idle monitoring dan actions
// Menggantikan hypridle dengan fitur native Quickshell
QtObject {
    id: idleManager

    // ── Configuration (akan di-load dari JSON) ────────────────────────────
    property int screenOffTimeout: 300      // 5 menit (dalam detik)
    property int lockTimeout: 600           // 10 menit (dalam detik)
    property int suspendTimeout: 1800       // 30 menit (dalam detik)
    property bool monitoringEnabled: true   // Master switch untuk monitoring

    // ── State ──────────────────────────────────────────────────────────────
    property bool screenOff: false
    property bool systemLocked: false
    
    // ── Persistence ────────────────────────────────────────────────────────
    property string configPath: Quickshell.env("HOME") + "/.config/quickshell/data/idle-config.json"
    property bool configLoaded: false

    // References (akan di-inject dari shell.qml)
    property var lockFn: function() { 
        console.warn("[IdleManager] Lock function not initialized")
    }

    // ── Idle Monitors ──────────────────────────────────────────────────────

    // Monitor untuk screen off (5 menit)
    property IdleMonitor screenOffMonitor: IdleMonitor {
        enabled: idleManager.monitoringEnabled
        timeout: idleManager.screenOffTimeout
        respectInhibitors: true  // Respect idle inhibitor
        
        onIsIdleChanged: {
            if (isIdle) {
                idleManager._screenOff()
            } else if (!isIdle && idleManager.screenOff) {
                idleManager._screenOn()
            }
        }
    }

    // Monitor untuk lock screen (10 menit)
    property IdleMonitor lockMonitor: IdleMonitor {
        enabled: idleManager.monitoringEnabled
        timeout: idleManager.lockTimeout
        respectInhibitors: true
        
        onIsIdleChanged: {
            if (isIdle) {
                idleManager._lockScreen()
            }
        }
    }

    // Monitor untuk suspend (30 menit)
    property IdleMonitor suspendMonitor: IdleMonitor {
        enabled: idleManager.monitoringEnabled
        timeout: idleManager.suspendTimeout
        respectInhibitors: true
        
        onIsIdleChanged: {
            if (isIdle) {
                idleManager._suspend()
            }
        }
    }

    // ── Actions ────────────────────────────────────────────────────────────

    function _screenOff() {
        log("Screen off timeout reached")
        screenOff = true
        
        // Hyprctl dpms off untuk matikan layar
        screenOffProc.running = true
    }

    function _screenOn() {
        log("User activity detected, screen on")
        screenOff = false
        
        // Hyprctl dpms on untuk nyalakan layar
        screenOnProc.running = true
    }

    function _lockScreen() {
        if (systemLocked) {
            log("Already locked, skipping")
            return
        }
        
        log("Lock timeout reached")
        systemLocked = true
        
        if (lockFn) {
            lockFn()
        }
    }

    function _suspend() {
        log("Suspend timeout reached")
        
        // Systemctl suspend
        suspendProc.running = true
    }

    // ── Processes ──────────────────────────────────────────────────────────

    property Process screenOffProc: Process {
        command: ["hyprctl", "dispatch", "dpms", "off"]
    }

    property Process screenOnProc: Process {
        command: ["hyprctl", "dispatch", "dpms", "on"]
    }

    property Process suspendProc: Process {
        command: ["systemctl", "suspend"]
    }

    // ── Public API ─────────────────────────────────────────────────────────

    function enable() {
        monitoringEnabled = true
        _saveConfig()
        log("Idle monitoring enabled")
    }

    function disable() {
        monitoringEnabled = false
        _saveConfig()
        log("Idle monitoring disabled")
    }

    function toggle() {
        monitoringEnabled = !monitoringEnabled
        _saveConfig()
        log("Idle monitoring", monitoringEnabled ? "enabled" : "disabled")
    }

    // Reset state saat user unlock (dipanggil dari lockscreen)
    function onUnlock() {
        systemLocked = false
        log("System unlocked, idle state reset")
    }

    // Fungsi untuk set timeout secara dinamis (dalam menit)
    function setScreenOffTimeout(minutes) {
        screenOffTimeout = minutes * 60
        _saveConfig()
        log("Screen off timeout set to", minutes, "minutes")
    }

    function setLockTimeout(minutes) {
        lockTimeout = minutes * 60
        _saveConfig()
        log("Lock timeout set to", minutes, "minutes")
    }

    function setSuspendTimeout(minutes) {
        suspendTimeout = minutes * 60
        _saveConfig()
        log("Suspend timeout set to", minutes, "minutes")
    }

    // ── Persistence Functions ──────────────────────────────────────────────

    function _loadConfig() {
        loadProc.running = true
    }

    function _saveConfig() {
        if (!configLoaded) {
            log("Config not loaded yet, skipping save")
            return
        }
        
        const config = {
            screenOffTimeout: screenOffTimeout,
            lockTimeout: lockTimeout,
            suspendTimeout: suspendTimeout,
            monitoringEnabled: monitoringEnabled
        }
        
        const json = JSON.stringify(config)
        log("Saving config to", configPath)
        
        // Escape single quotes untuk shell
        const escaped = json.replace(/'/g, "'\\''")
        
        saveProc.command = ["sh", "-c", "echo '" + escaped + "' > '" + configPath + "'"]
        saveProc.running = true
    }

    property Process saveProc: Process {
        onRunningChanged: {
            if (!running) {
                log("Config save completed")
            }
        }
    }

    property Process loadProc: Process {
        command: ["cat", idleManager.configPath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const content = text.trim()
                
                if (!content || content === "") {
                    log("Config file empty, will create default")
                    idleManager.configLoaded = true
                    idleManager._saveConfig()
                    return
                }
                
                try {
                    const config = JSON.parse(content)
                    log("Parsing config successfully")
                    
                    if (config.screenOffTimeout !== undefined) {
                        idleManager.screenOffTimeout = config.screenOffTimeout
                        log("Loaded screenOffTimeout:", config.screenOffTimeout / 60, "min")
                    }
                    
                    if (config.lockTimeout !== undefined) {
                        idleManager.lockTimeout = config.lockTimeout
                        log("Loaded lockTimeout:", config.lockTimeout / 60, "min")
                    }
                    
                    if (config.suspendTimeout !== undefined) {
                        idleManager.suspendTimeout = config.suspendTimeout
                        log("Loaded suspendTimeout:", config.suspendTimeout / 60, "min")
                    }
                    
                    if (config.monitoringEnabled !== undefined) {
                        idleManager.monitoringEnabled = config.monitoringEnabled
                        log("Loaded monitoringEnabled:", config.monitoringEnabled)
                    }
                    
                    log("Config loaded successfully")
                } catch (e) {
                    log("Failed to parse config:", e.toString())
                    log("Will save defaults")
                    idleManager._saveConfig()
                }
                
                idleManager.configLoaded = true
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0 && text.includes("No such file")) {
                    log("Config file not found, will create")
                    idleManager.configLoaded = true
                    idleManager._saveConfig()
                }
            }
        }
    }

    // ── Logging ────────────────────────────────────────────────────────────

    function log(message, extra1, extra2) {
        var msg = "[IdleManager] " + message
        if (extra1 !== undefined) msg += " " + extra1
        if (extra2 !== undefined) msg += " " + extra2
        console.log(msg)
    }

    // ── Init ───────────────────────────────────────────────────────────────
    
    property Timer loadFallbackTimer: Timer {
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            if (!idleManager.configLoaded) {
                idleManager.log("Load timeout, using defaults")
                idleManager.configLoaded = true
                idleManager._saveConfig()
            }
        }
    }

    Component.onCompleted: {
        log("Initializing IdleManager...")
        log("Config path:", configPath)
        
        // Coba load config
        _loadConfig()
        
        // Start fallback timer
        loadFallbackTimer.start()
    }

    onConfigLoadedChanged: {
        if (configLoaded) {
            loadFallbackTimer.stop()
            log("=== Configuration Ready ===")
            log("Screen off:", screenOffTimeout / 60, "min")
            log("Lock screen:", lockTimeout / 60, "min")
            log("Suspend:", suspendTimeout / 60, "min")
            log("Monitoring:", monitoringEnabled ? "enabled" : "disabled")
        }
    }
}
