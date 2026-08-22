import QtQml
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io

// Service untuk kontrol volume dengan aggressive debouncing & error handling
// Mengakses default audio sink dengan prioritas ke bluetooth device
// Updated untuk mendukung EasyEffects dengan wpctl
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

    // Microphone/input source properties
    property var _defaultSource: Pipewire.defaultAudioSource

    // Detect hardware sink aktif di balik EasyEffects.
    // EasyEffects simpan node.driver-id = ID hardware sink yang sedang di-drive.
    property string _hwSinkId: {
        if (!sink) return ""
        const eeName = (sink.name || "").toLowerCase()
        if (!eeName.includes("easyeffects")) return ""
        const driverId = (sink.properties || {})["node.driver-id"]
        return driverId != null ? String(driverId) : ""
    }

    // wpctl processes untuk EasyEffects support
    property Process wpctlVol: Process { running: false }
    property Process wpctlVolHw: Process { running: false }
    property Process wpctlMute: Process { running: false }
    property Process wpctlMuteHw: Process { running: false }
    
    // wpctl processes untuk microphone control
    property Process wpctlMicMute: Process { running: false }

    // Track sink changes dengan throttling
    PwObjectTracker {
        objects: [volumeControl._defaultSink, volumeControl._btSink].filter(n => n != null)
        onObjectsChanged: {
            // Invalidate cache untuk next access
            volumeControl._pwNeedsRescan = true
            console.log("[VolumeControl] Audio sink changed, cache invalidated")
        }
    }

    // Track mic source agar audio.muted reaktif setelah wpctl toggle
    PwObjectTracker {
        objects: volumeControl._defaultSource ? [volumeControl._defaultSource] : []
    }

    Component.onCompleted: {
        console.log("[VolumeControl] Service initialized (EasyEffects support, aggressive debounce: 75ms)")
    }

    function _setVolume(v) {
        // Set ke EasyEffects sink supaya display % di EasyEffects sinkron
        wpctlVol.command = ["wpctl", "set-volume", "@DEFAULT_SINK@", v.toFixed(3)]
        wpctlVol.running = true
        
        // Set juga ke hardware sink supaya volume benar-benar berubah
        if (_hwSinkId !== "") {
            wpctlVolHw.command = ["wpctl", "set-volume", _hwSinkId, v.toFixed(3)]
            wpctlVolHw.running = true
        }
    }

    function _toggleMute() {
        // Toggle mute untuk EasyEffects sink
        wpctlMute.command = ["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"]
        wpctlMute.running = true
        
        // Toggle juga hardware sink jika ada EasyEffects
        if (_hwSinkId !== "") {
            wpctlMuteHw.command = ["wpctl", "set-mute", _hwSinkId, "toggle"]
            wpctlMuteHw.running = true
        }
    }

    function _toggleMicMute() {
        // Toggle mute untuk default microphone/input source
        wpctlMicMute.command = ["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"]
        wpctlMicMute.running = true
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
            const newVolume = Math.min(1.0, oldVolume + step)
            
            // Check if actually changed (avoid unnecessary updates)
            if (Math.abs(newVolume - oldVolume) < 0.001) {
                debounceHits++
                return true
            }
            
            // Use wpctl for EasyEffects compatibility
            _setVolume(newVolume)
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                if (osdRef) {
                    // Get actual volume after wpctl command
                    const actualVolume = sink.audio ? sink.audio.volume : newVolume
                    osdRef.showVolume(actualVolume, sink.audio ? sink.audio.muted : false)
                }
            })
            debounceTimer.restart()

            updateCount++
            console.log("[VolumeControl] Volume up (wpctl): " + 
                       (oldVolume * 100).toFixed(0) + "% → " + 
                       (newVolume * 100).toFixed(0) + "%")
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
            const newVolume = Math.max(0.0, oldVolume - step)
            
            // Check if actually changed (avoid unnecessary updates)
            if (Math.abs(newVolume - oldVolume) < 0.001) {
                debounceHits++
                return true
            }
            
            // Use wpctl for EasyEffects compatibility
            _setVolume(newVolume)
            
            lastUpdateTime = Date.now()
            debounceTimer.stop()
            debounceTimer.triggered.connect(() => {
                if (osdRef) {
                    // Get actual volume after wpctl command
                    const actualVolume = sink.audio ? sink.audio.volume : newVolume
                    osdRef.showVolume(actualVolume, sink.audio ? sink.audio.muted : false)
                }
            })
            debounceTimer.restart()

            updateCount++
            console.log("[VolumeControl] Volume down (wpctl): " + 
                       (oldVolume * 100).toFixed(0) + "% → " + 
                       (newVolume * 100).toFixed(0) + "%")
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
            
            // Use wpctl for EasyEffects compatibility
            _toggleMute()
            
            // OSD update dengan delay kecil untuk menunggu wpctl selesai
            if (osdRef) {
                Qt.callLater(() => {
                    const actualMuted = sink.audio ? sink.audio.muted : !oldMuted
                    const actualVolume = sink.audio ? sink.audio.volume : 0
                    osdRef.showVolume(actualVolume, actualMuted)
                })
            }
            
            lastUpdateTime = Date.now()
            updateCount++
            console.log("[VolumeControl] Mute toggled (wpctl): " + 
                       (oldMuted ? "on" : "off") + " → " + 
                       (!oldMuted ? "on" : "off"))
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[VolumeControl] Error in toggleMute:", e.message)
            return false
        }
    }

    function toggleMicMute() {
        if (!_defaultSource) {
            errorCount++
            lastError = "No audio source available"
            console.error("[VolumeControl] toggleMicMute failed:", lastError)
            return false
        }

        if (!_defaultSource.audio) {
            errorCount++
            lastError = "Source has no audio property"
            console.error("[VolumeControl] toggleMicMute failed:", lastError)
            return false
        }

        try {
            const oldMuted = _defaultSource.audio.muted
            
            // Use wpctl for microphone mute
            _toggleMicMute()
            
            // OSD update — pakai Qt.callLater supaya Pipewire sempat update state
            // sebelum kita baca _defaultSource.audio.muted
            if (osdRef) {
                Qt.callLater(() => {
                    const actualMuted = _defaultSource && _defaultSource.audio
                        ? _defaultSource.audio.muted
                        : !oldMuted
                    osdRef.showMicMute(actualMuted)
                })
            }
            
            lastUpdateTime = Date.now()
            updateCount++
            console.log("[VolumeControl] Microphone mute toggled (wpctl): " + 
                       (oldMuted ? "on" : "off") + " → " + 
                       (!oldMuted ? "on" : "off"))
            return true
        } catch (e) {
            errorCount++
            lastError = e.message
            console.error("[VolumeControl] Error in toggleMicMute:", e.message)
            return false
        }
    }

    function getSinkInfo(): string {
        if (!sink) return "No sink available"
        const name = sink.name || "Unknown"
        const volume = sink.audio ? (sink.audio.volume * 100).toFixed(0) + "%" : "N/A"
        const muted = sink.audio ? (sink.audio.muted ? "Muted" : "Unmuted") : "N/A"
        const easyEffectsMode = _hwSinkId !== "" ? " (via EasyEffects)" : ""
        return `${name}${easyEffectsMode} - ${volume} ${muted}`
    }

    function getMicInfo(): string {
        if (!_defaultSource) return "No microphone available"
        const name = _defaultSource.name || "Unknown"
        const muted = _defaultSource.audio ? (_defaultSource.audio.muted ? "Muted" : "Unmuted") : "N/A"
        return `Mic: ${name} - ${muted}`
    }

    function getDebugInfo(): object {
        return {
            "status": sink ? "ready" : "no sink",
            "sink_name": sink ? (sink.name || "unknown") : null,
            "mic_name": _defaultSource ? (_defaultSource.name || "unknown") : null,
            "mic_muted": _defaultSource && _defaultSource.audio ? _defaultSource.audio.muted : null,
            "easyeffects_mode": _hwSinkId !== "",
            "hw_sink_id": _hwSinkId || null,
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
