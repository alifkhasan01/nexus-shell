import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// Manager untuk semua background processes dengan error handling & logging
// Handles: screenshot (select/full), bluetooth agent
Item {
    id: processManager
    visible: false

    // Properties untuk injeksi
    property var shellState: null
    property var osdRef: null

    // State tracking
    property int screenshotRetries: 0
    property int btAgentRetries: 0
    property int maxRetries: 3

    // ── Dependency availability flags ──────────────────────────────
    // Dicek sekali saat startup supaya fitur yang binary-nya nggak ada
    // langsung nonaktif dengan graceful (bukan retry loop / crash).
    property bool depsChecked: false
    property var missingDeps: []
    property bool hasGrimblast: false
    property bool hasVisualizer: false
    property bool hasBluetoothctl: false
    property bool hasNotifySend: false

    // ── Dependency Check ───────────────────────────────────────────
    Process {
        id: depsCheckProc
        command: ["sh", "-c",
            "for b in grimblast bluetoothctl notify-send; do " +
            "command -v \"$b\" >/dev/null 2>&1 && echo \"$b:1\" || echo \"$b:0\"; done; " +
            "test -x \"" + Quickshell.shellPath("scripts/qs_visualizer") + "\" && echo \"qs_visualizer:1\" || echo \"qs_visualizer:0\""]

        onExited: (exitCode, exitStatus) => {
            console.log("[Deps] Check finished (exit code: " + exitCode + ")")
        }

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const parts = line.trim().split(":")
                    if (parts.length !== 2) continue
                    const val = parts[1] === "1"
                    if (parts[0] === "grimblast") processManager.hasGrimblast = val
                    else if (parts[0] === "qs_visualizer") processManager.hasVisualizer = val
                    else if (parts[0] === "bluetoothctl") processManager.hasBluetoothctl = val
                    else if (parts[0] === "notify-send") processManager.hasNotifySend = val
                }
                processManager.depsChecked = true
                processManager.applyDependencies()
            }
        }
    }

    Process { id: depsNotifProc }

    Component.onCompleted: {
        depsCheckProc.running = true
    }

    // Dipanggil setelah install dependensi selesai (dari WelcomePanel)
    // supaya flags & auto-start mengikuti kondisi terbaru.
    function recheckDependencies() {
        console.log("[Deps] Re-checking dependencies after install")
        depsCheckProc.running = true
    }

    function applyDependencies() {
        const missing = []
        if (!hasGrimblast) missing.push("grimblast")
        if (!hasVisualizer) missing.push("qs_visualizer (jalankan scripts/build-visualizer.sh)")
        if (!hasBluetoothctl) missing.push("bluetoothctl")

        if (missing.length > 0) {
            console.warn("[Deps] Missing: " + missing.join(", ") + " — fitur terkait dinonaktifkan")
            if (hasNotifySend) {
                depsNotifProc.command = ["notify-send", "--app-name=Quickshell",
                    "--expire-time=6000", "--icon=dialog-warning",
                    "Dependensi Kurang",
                    "Install dulu: " + missing.join(", ")]
                depsNotifProc.running = true
            }
        } else {
            console.log("[Deps] Semua dependensi tersedia")
        }
        processManager.missingDeps = missing

        // Auto-start hanya jika dependensinya ada
        if (hasBluetoothctl && !btAgent.running) btAgent.running = true
    }

    // ── Screenshot Processes ───────────────────────────────────────
    Process {
        id: screenshotSelectProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\" 2>/dev/null || { echo 'Failed to create directory'; exit 1; }; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave area \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        
        onExited: (exitCode, exitStatus) => {
            console.log("[Screenshot:Select] Process finished (exit code: " + exitCode + ")")
            if (exitCode !== 0) {
                screenshotRetries++
                if (screenshotRetries <= maxRetries) {
                    console.warn("[Screenshot:Select] Retry " + screenshotRetries + "/" + maxRetries)
                    screenshotSelectRetryTimer.restart()
                } else {
                    console.error("[Screenshot:Select] Max retries exceeded")
                }
            } else {
                screenshotRetries = 0
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "") {
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                    console.log("[Screenshot:Select] Saved to:", file)
                } else {
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Dibatalkan",
                        "Area tidak dipilih atau grimblast tidak tersedia."]
                    console.warn("[Screenshot:Select] Area selection cancelled or grimblast unavailable")
                }
                screenshotNotifProc.running = true
            }
        }
    }

    Timer {
        id: screenshotSelectRetryTimer
        interval: 1000
        repeat: false
        onTriggered: {
            screenshotSelectProc.running = true
        }
    }

    Process {
        id: screenshotFullProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\" 2>/dev/null || { echo 'Failed to create directory'; exit 1; }; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave screen \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        
        onExited: (exitCode, exitStatus) => {
            console.log("[Screenshot:Full] Process finished (exit code: " + exitCode + ")")
            if (exitCode !== 0) {
                screenshotRetries++
                if (screenshotRetries <= maxRetries) {
                    console.warn("[Screenshot:Full] Retry " + screenshotRetries + "/" + maxRetries)
                    screenshotFullRetryTimer.restart()
                } else {
                    console.error("[Screenshot:Full] Max retries exceeded")
                }
            } else {
                screenshotRetries = 0
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "") {
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                    console.log("[Screenshot:Full] Saved to:", file)
                } else {
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Gagal",
                        "Grimblast tidak tersedia atau error."]
                    console.error("[Screenshot:Full] Failed - grimblast unavailable or error")
                }
                screenshotNotifProc.running = true
            }
        }
    }

    Timer {
        id: screenshotFullRetryTimer
        interval: 1000
        repeat: false
        onTriggered: {
            screenshotFullProc.running = true
        }
    }

    Process { id: screenshotNotifProc }

    // ── BlueZ Agent Process ────────────────────────────────────────
    // Auto-answer bluetooth pairing requests
    // Script: scripts/btagent.sh
    Process {
        id: btAgent
        command: ["bash", Quickshell.shellPath("scripts/btagent.sh")]
        // Auto-start via applyDependencies() jika bluetoothctl tersedia
        running: false
        
        Component.onCompleted: {
            console.log("[BTAgent] Initialized")
        }

        onRunningChanged: {
            if (running) {
                console.log("[BTAgent] Started successfully")
                btAgentRetries = 0
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[BTAgent] Process exited normally")
            } else {
                console.warn("[BTAgent] Process stopped (exit code: " + exitCode + "), will restart in 5 seconds")
                btAgentRetries++
                if (btAgentRetries <= maxRetries) {
                    btAgentRestartTimer.restart()
                } else {
                    console.error("[BTAgent] Max restart retries exceeded")
                }
            }
        }
    }

    Timer {
        id: btAgentRestartTimer
        interval: 5000
        repeat: false
        onTriggered: {
            btAgent.running = true
            console.log("[BTAgent] Attempting restart (" + btAgentRetries + "/" + maxRetries + ")...")
        }
    }

    // Public methods untuk trigger screenshot dari shortcuts
    function takeScreenshotSelect() {
        if (depsChecked && !hasGrimblast) {
            console.warn("[Screenshot:Select] grimblast tidak tersedia, dilewati")
            if (hasNotifySend) {
                screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                    "--expire-time=4000", "--icon=dialog-error",
                    "Screenshot Tidak Tersedia",
                    "Grimblast belum diinstall. Install dengan: yay -S grimblast-git"]
                screenshotNotifProc.running = true
            }
            return
        }
        console.log("[Screenshot:Select] Triggered from shortcut")
        screenshotRetries = 0
        screenshotSelectProc.running = true
    }

    function takeScreenshotFull() {
        if (depsChecked && !hasGrimblast) {
            console.warn("[Screenshot:Full] grimblast tidak tersedia, dilewati")
            if (hasNotifySend) {
                screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                    "--expire-time=4000", "--icon=dialog-error",
                    "Screenshot Tidak Tersedia",
                    "Grimblast belum diinstall. Install dengan: yay -S grimblast-git"]
                screenshotNotifProc.running = true
            }
            return
        }
        console.log("[Screenshot:Full] Triggered from shortcut")
        screenshotRetries = 0
        screenshotFullProc.running = true
    }

    // Debug helper
    function getProcessStatus(): string {
        const status = {
            "screenshot_select": screenshotSelectProc.running ? "running" : "idle",
            "screenshot_full": screenshotFullProc.running ? "running" : "idle",
            "btagent": btAgent.running ? "running" : "idle"
        }
        return JSON.stringify(status, null, 2)
    }
}
