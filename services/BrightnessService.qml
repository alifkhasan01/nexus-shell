pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sumber kebenaran tunggal untuk brightness — dibaca oleh Bar dan Dashboard
// sehingga nilainya selalu sinkron.
//
// Update instan dengan kombinasi:
//   1. FileView watchChanges (inotify) → langsung saat sysfs berubah
//   2. Timer fallback 250ms → sysfs sering tidak memicu inotify di beberapa
//      driver (mis. amdgpu), jadi timer memastikan nilai tetap update.
Item {
    id: root
    visible: false

    readonly property string device: "amdgpu_bl1"
    readonly property string sysfsBase: "/sys/class/backlight/" + device

    property int brightness: 0
    property int maxBrightness: 1      // hindari division by zero sebelum terbaca

    readonly property real fraction: maxBrightness > 0 ? brightness / maxBrightness : 0
    readonly property real percent: Math.round(fraction * 100)

    // ── Watch via inotify (instan bila driver mendukung) ──────────────────
    FileView {
        id: brightFile
        path: root.sysfsBase + "/brightness"
        watchChanges: true
        onTextChanged: root.sync()
        onFileChanged: brightFile.reload()
    }

    FileView {
        id: maxFile
        path: root.sysfsBase + "/max_brightness"
        watchChanges: true
        onTextChanged: root.sync()
        onFileChanged: maxFile.reload()
    }

    // ── Fallback polling: sysfs tidak selalu memicu inotify ───────────────
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            brightFile.reload()
            maxFile.reload()
        }
    }

    function sync() {
        const t = brightFile.text()
        if (t !== "") {
            const v = parseInt(t.trim(), 10)
            if (!isNaN(v) && v !== root.brightness) root.brightness = v
        }

        const m = maxFile.text()
        if (m !== "") {
            const v = parseInt(m.trim(), 10)
            if (!isNaN(v) && v > 0 && v !== root.maxBrightness) root.maxBrightness = v
        }
    }

    // Set dengan nilai 0..1
    function setPercent(value: real) {
        const raw = Math.max(0, Math.min(maxBrightness, Math.round(value * maxBrightness)))
        // Optimistic update — UI langsung berubah tanpa menunggu sysfs
        root.brightness = raw
        Quickshell.execDetached(["brightnessctl", "--device=" + root.device, "set", raw + ""])
    }

    // Set dengan nilai mentah (0..maxBrightness)
    function setRaw(value: int) {
        const raw = Math.max(0, Math.min(maxBrightness, value))
        root.brightness = raw
        Quickshell.execDetached(["brightnessctl", "--device=" + root.device, "set", raw + ""])
    }
}