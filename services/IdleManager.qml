pragma Singleton

import QtQuick
import Quickshell.Wayland
import Quickshell.Io

// Service untuk mengelola idle monitoring dan actions
// Menggantikan hypridle dengan fitur native Quickshell
QtObject {
    id: idleManager

    // ── Configuration ──────────────────────────────────────────────────────
    property int screenOffTimeout: 300      // 5 menit (dalam detik)
    property int lockTimeout: 600           // 10 menit (dalam detik)
    property int suspendTimeout: 1800       // 30 menit (dalam detik)

    // ── State ──────────────────────────────────────────────────────────────
    property bool monitoringEnabled: true   // Master switch untuk monitoring
    property bool screenOff: false
    property bool systemLocked: false

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
            if (isIdle && !idleManager.screenOff) {
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
            if (isIdle && !idleManager.systemLocked) {
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
        log("Idle monitoring enabled")
    }

    function disable() {
        monitoringEnabled = false
        log("Idle monitoring disabled")
    }

    function toggle() {
        monitoringEnabled = !monitoringEnabled
        log("Idle monitoring", monitoringEnabled ? "enabled" : "disabled")
    }

    // Fungsi untuk set timeout secara dinamis (dalam menit)
    function setScreenOffTimeout(minutes) {
        screenOffTimeout = minutes * 60
        log("Screen off timeout set to", minutes, "minutes")
    }

    function setLockTimeout(minutes) {
        lockTimeout = minutes * 60
        log("Lock timeout set to", minutes, "minutes")
    }

    function setSuspendTimeout(minutes) {
        suspendTimeout = minutes * 60
        log("Suspend timeout set to", minutes, "minutes")
    }

    // ── Logging ────────────────────────────────────────────────────────────

    function log(message, extra1, extra2) {
        var msg = "[IdleManager] " + message
        if (extra1 !== undefined) msg += " " + extra1
        if (extra2 !== undefined) msg += " " + extra2
        console.log(msg)
    }

    // ── Init ───────────────────────────────────────────────────────────────

    Component.onCompleted: {
        log("Initialized")
        log("Screen off:", screenOffTimeout / 60, "min")
        log("Lock screen:", lockTimeout / 60, "min")
        log("Suspend:", suspendTimeout / 60, "min")
    }
}
