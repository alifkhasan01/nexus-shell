import QtQml
import QtQuick

// Service untuk kontrol brightness dengan aggressive debouncing & error handling
// Menggunakan BrightnessService untuk hardware brightness control
// Optimized untuk minimal memory footprint & CPU usage
Item {
    id: brightnessControl
    visible: false

    property var osdRef: null // Injected dari shell.qml
    property real debounceInterval: 120 // Increased from 100ms untuk aggressive optimization
    property int updateCount: 0
    property int errorCount: 0
    property var lastError: null
    
    // Performance metrics
    property int debounceHits: 0
    property var lastUpdateTime: null
    property int _lastKnownBrightness: -1

    // Debounce timer
    Timer {
        id: debounceTimer
        interval: brightnessControl.debounceInterval
        repeat: false
    }

    Component.onCompleted: {
        console.log("[BrightnessControl] Service initialized (aggressive debounce: " + debounceInterval + "ms)")
        if (BrightnessService && BrightnessService.brightness >= 0) {
            _lastKnownBrightness = BrightnessService.brightness
        }
    }

    function brightnessUp() {
        try {
            if (!BrightnessService || BrightnessService.maxBrightness <= 0) {
                errorCount++
                lastError = "BrightnessService not available or invalid"
                console.error("[BrightnessControl]", lastError)
                return false
            }

            const step = Math.round(BrightnessService.maxBrightness * 0.05)
            const oldBrightness = BrightnessService.brightness
            const newValue = Math.min(BrightnessService.maxBrightness, 
                                     BrightnessService.brightness + step)
            
            // Check if actually changed (avoid unnecessary updates)
            if (Math.abs(newValue - _lastKnownBrightness) < 1) {
                debounceHits++
                return true
            }
            
            _lastKnownBrightness = newValue
            BrightnessService.setRaw(newValue)
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                const normalized = BrightnessService.brightness / BrightnessService.maxBrightness
                if (osdRef) osdRef.showBrightness(normalized)
            })
            debounceTimer.restart()

            updateCount++
            const oldPercent = (oldBrightness / BrightnessService.maxBrightness * 100).toFixed(0)
            const newPercent = (BrightnessService.brightness / BrightnessService.maxBrightness * 100).toFixed(0)
            console.log("[BrightnessControl] Brightness up: " + oldPercent + "% → " + newPercent + "%")
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[BrightnessControl] Error in brightnessUp:", e.message)
            return false
        }
    }

    function brightnessDown() {
        try {
            if (!BrightnessService || BrightnessService.maxBrightness <= 0) {
                errorCount++
                lastError = "BrightnessService not available or invalid"
                console.error("[BrightnessControl]", lastError)
                return false
            }

            const step = Math.round(BrightnessService.maxBrightness * 0.05)
            const oldBrightness = BrightnessService.brightness
            const newValue = Math.max(0, BrightnessService.brightness - step)
            
            // Check if actually changed (avoid unnecessary updates)
            if (Math.abs(newValue - _lastKnownBrightness) < 1) {
                debounceHits++
                return true
            }
            
            _lastKnownBrightness = newValue
            BrightnessService.setRaw(newValue)
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                const normalized = BrightnessService.brightness / BrightnessService.maxBrightness
                if (osdRef) osdRef.showBrightness(normalized)
            })
            debounceTimer.restart()

            updateCount++
            const oldPercent = (oldBrightness / BrightnessService.maxBrightness * 100).toFixed(0)
            const newPercent = (BrightnessService.brightness / BrightnessService.maxBrightness * 100).toFixed(0)
            console.log("[BrightnessControl] Brightness down: " + oldPercent + "% → " + newPercent + "%")
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[BrightnessControl] Error in brightnessDown:", e.message)
            return false
        }
    }

    function getBrightnessInfo(): string {
        try {
            if (!BrightnessService) return "BrightnessService unavailable"
            const percent = (BrightnessService.brightness / BrightnessService.maxBrightness * 100).toFixed(0)
            return `${percent}%`
        } catch (e) {
            return "Error: " + e.message
        }
    }

    function getDebugInfo(): object {
        return {
            "status": (BrightnessService && BrightnessService.maxBrightness > 0) ? "ready" : "unavailable",
            "brightness": BrightnessService ? BrightnessService.brightness : null,
            "max_brightness": BrightnessService ? BrightnessService.maxBrightness : null,
            "percentage": BrightnessService ? (BrightnessService.brightness / BrightnessService.maxBrightness * 100).toFixed(0) + "%" : null,
            "update_count": updateCount,
            "error_count": errorCount,
            "debounce_hits": debounceHits,
            "last_error": lastError,
            "last_update_ms_ago": lastUpdateTime ? (Date.now() - lastUpdateTime) + "ms" : "never",
            "performance": {
                "debounce_interval_ms": debounceTimer.interval,
                "brightness_cache": _lastKnownBrightness
            }
        }
    }
}
