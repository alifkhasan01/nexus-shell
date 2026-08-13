import QtQml
import QtQuick
import Quickshell.Services.Pipewire

// Service untuk kontrol volume dengan aggressive debouncing & error handling
// Mengakses default audio sink dengan prioritas ke bluetooth device
// Optimized untuk minimal memory footprint & CPU usage
Item {
    id: volumeControl
    visible: false

    property var osdRef: null // Injected dari shell.qml
    property int updateCount: 0
    property int errorCount: 0
    property var lastError: null
    
    // Performance metrics
    property int debounceHits: 0  // Jumlah kali debounce menghindarkan update
    property var lastUpdateTime: null

    // Aggressive debounce: 75ms untuk mencegah multiple updates dalam sequence cepat
    Timer {
        id: debounceTimer
        interval: 75
        repeat: false
    }

    // Throttle untuk PipeWire tracking — hanya check max 4x per detik
    Timer {
        id: pwThrottleTimer
        interval: 250
        repeat: false
    }

    // Cache untuk menghindari repeated object lookups
    property var _cachedDefaultSink: null
    property var _cachedBtSink: null
    property bool _pwNeedsRescan: true

    property var _defaultSink: {
        if (!_pwNeedsRescan && _cachedDefaultSink) return _cachedDefaultSink
        _cachedDefaultSink = Pipewire.defaultAudioSink
        _pwNeedsRescan = false
        pwThrottleTimer.restart()
        return _cachedDefaultSink
    }

    property var _btSink: {
        if (!_pwNeedsRescan && _cachedBtSink !== undefined) return _cachedBtSink
        
        try {
            const nodes = Pipewire.nodes.values
            if (!nodes || nodes.length === 0) {
                _cachedBtSink = null
                return null
            }
            
            // Early exit untuk common case (no BT devices)
            const hasBluetoothDevice = nodes.some(n => {
                if (!n || !n.audio || !n.isSink || n.isStream) return false
                const props = n.properties || {}
                return props["device.api"] === "bluez5" || (n.name || "").startsWith("bluez_output.")
            })
            
            if (!hasBluetoothDevice) {
                _cachedBtSink = null
                return null
            }
            
            // Cari device jika ada
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (!n || !n.audio || !n.isSink || n.isStream) continue
                const props = n.properties || {}
                if (props["device.api"] === "bluez5" ||
                    (n.name || "").startsWith("bluez_output.")) {
                    _cachedBtSink = n
                    return n
                }
            }
            _cachedBtSink = null
            return null
        } catch (e) {
            console.error("[VolumeControl] Error scanning bluetooth sinks:", e.message)
            lastError = e.message
            errorCount++
            _cachedBtSink = null
            return null
        }
    }

    property var sink: {
        if (_btSink && _defaultSink && _btSink.id === _defaultSink.id)
            return _btSink
        return _defaultSink
    }

    // Track sink changes dengan throttling
    PwObjectTracker {
        objects: [volumeControl._defaultSink, volumeControl._btSink].filter(n => n != null)
        onObjectsChanged: {
            // Invalidate cache untuk next access
            volumeControl._pwNeedsRescan = true
            console.log("[VolumeControl] Audio sink changed, cache invalidated")
        }
    }

    Component.onCompleted: {
        console.log("[VolumeControl] Service initialized (aggressive debounce: 75ms)")
    }

    function volumeUp() {
        if (!sink) {
            errorCount++
            lastError = "No audio sink available"
            console.error("[VolumeControl] volumeUp failed:", lastError)
            return false
        }

        if (!sink.audio) {
            errorCount++
            lastError = "Sink has no audio property"
            console.error("[VolumeControl] volumeUp failed:", lastError)
            return false
        }

        try {
            const step = 0.05
            const oldVolume = sink.audio.volume
            sink.audio.volume = Math.min(1.0, sink.audio.volume + step)
            
            // Check if actually changed (avoid unnecessary OSD updates)
            if (Math.abs(sink.audio.volume - oldVolume) < 0.001) {
                debounceHits++
                return true
            }
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                if (osdRef) {
                    osdRef.showVolume(sink.audio.volume, sink.audio.muted)
                }
            })
            debounceTimer.restart()

            updateCount++
            console.log("[VolumeControl] Volume up: " + 
                       (oldVolume * 100).toFixed(0) + "% → " + 
                       (sink.audio.volume * 100).toFixed(0) + "%")
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[VolumeControl] Error in volumeUp:", e.message)
            return false
        }
    }

    function volumeDown() {
        if (!sink) {
            errorCount++
            lastError = "No audio sink available"
            console.error("[VolumeControl] volumeDown failed:", lastError)
            return false
        }

        if (!sink.audio) {
            errorCount++
            lastError = "Sink has no audio property"
            console.error("[VolumeControl] volumeDown failed:", lastError)
            return false
        }

        try {
            const step = 0.05
            const oldVolume = sink.audio.volume
            sink.audio.volume = Math.max(0.0, sink.audio.volume - step)
            
            // Check if actually changed (avoid unnecessary OSD updates)
            if (Math.abs(sink.audio.volume - oldVolume) < 0.001) {
                debounceHits++
                return true
            }
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                if (osdRef) {
                    osdRef.showVolume(sink.audio.volume, sink.audio.muted)
                }
            })
            debounceTimer.restart()

            updateCount++
            console.log("[VolumeControl] Volume down: " + 
                       (oldVolume * 100).toFixed(0) + "% → " + 
                       (sink.audio.volume * 100).toFixed(0) + "%")
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[VolumeControl] Error in volumeDown:", e.message)
            return false
        }
    }

    function toggleMute() {
        if (!sink) {
            errorCount++
            lastError = "No audio sink available"
            console.error("[VolumeControl] toggleMute failed:", lastError)
            return false
        }

        if (!sink.audio) {
            errorCount++
            lastError = "Sink has no audio property"
            console.error("[VolumeControl] toggleMute failed:", lastError)
            return false
        }

        try {
            const oldMuted = sink.audio.muted
            sink.audio.muted = !sink.audio.muted
            
            if (osdRef) {
                osdRef.showVolume(sink.audio.volume, sink.audio.muted)
            }
            
            lastUpdateTime = Date.now()
            updateCount++
            console.log("[VolumeControl] Mute toggled: " + 
                       (oldMuted ? "on" : "off") + " → " + 
                       (sink.audio.muted ? "on" : "off"))
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[VolumeControl] Error in toggleMute:", e.message)
            return false
        }
    }

    function getSinkInfo(): string {
        if (!sink) return "No sink available"
        const name = sink.name || "Unknown"
        const volume = sink.audio ? (sink.audio.volume * 100).toFixed(0) + "%" : "N/A"
        const muted = sink.audio ? (sink.audio.muted ? "Muted" : "Unmuted") : "N/A"
        return `${name} - ${volume} ${muted}`
    }

    function getDebugInfo(): object {
        return {
            "status": sink ? "ready" : "no sink",
            "sink_name": sink ? (sink.name || "unknown") : null,
            "volume": sink && sink.audio ? (sink.audio.volume * 100).toFixed(0) + "%" : null,
            "muted": sink && sink.audio ? sink.audio.muted : null,
            "update_count": updateCount,
            "error_count": errorCount,
            "debounce_hits": debounceHits,
            "last_error": lastError,
            "last_update_ms_ago": lastUpdateTime ? (Date.now() - lastUpdateTime) + "ms" : "never",
            "performance": {
                "debounce_interval_ms": debounceTimer.interval,
                "throttle_interval_ms": pwThrottleTimer.interval,
                "cache_status": _pwNeedsRescan ? "needs_rescan" : "cached"
            }
        }
    }
}
