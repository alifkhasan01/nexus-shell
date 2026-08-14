pragma Singleton

import QtQuick
import Quickshell.Wayland

// Service untuk global idle inhibitor
// Mencegah compositor menganggap sesi idle (layar mati, lock screen, dll)
// ketika inhibitor diaktifkan.
QtObject {
    id: inhibitService

    // State aktif atau tidak
    property bool inhibitActive: false

    // Referensi ke window (akan di-inject dari shell.qml)
    property var targetWindow: null

    // IdleInhibitor yang actual
    property IdleInhibitor inhibitor: IdleInhibitor {
        window: inhibitService.targetWindow
        enabled: inhibitService.inhibitActive
    }

    function toggle() {
        inhibitActive = !inhibitActive
        log("Idle inhibit", inhibitActive ? "enabled" : "disabled")
    }

    function enable() {
        if (!inhibitActive) {
            inhibitActive = true
            log("Idle inhibit enabled")
        }
    }

    function disable() {
        if (inhibitActive) {
            inhibitActive = false
            log("Idle inhibit disabled")
        }
    }

    function log(message, extra) {
        if (extra !== undefined) {
            console.log("[IdleInhibitService]", message, extra)
        } else {
            console.log("[IdleInhibitService]", message)
        }
    }
}
