import QtQml
import QtQuick
import Quickshell.Io

// Manager untuk semua background processes dengan error handling & logging
// Handles: screenshot (select/full), bluetooth agent, cava audio visualizer
Item {
    id: processManager
    visible: false

    // Properties untuk injeksi
    property var shellState: null
    property var osdRef: null

    // State tracking
    property int screenshotRetries: 0
    property int btAgentRetries: 0
    property int cavaFeedRetries: 0
    property int maxRetries: 3

    // ── Screenshot Processes ───────────────────────────────────────
    Process {
        id: screenshotSelectProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\" 2>/dev/null || { echo 'Failed to create directory'; exit 1; }; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave area \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        
        onRunningChanged: {
            if (!running) {
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
        
        onRunningChanged: {
            if (!running) {
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
        command: ["bash", "scripts/btagent.sh"]
        running: true
        
        Component.onCompleted: {
            console.log("[BTAgent] Initialized")
        }

        onRunningChanged: {
            if (!running) {
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
            } else {
                console.log("[BTAgent] Started successfully")
                btAgentRetries = 0
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

    // ── Cava Audio Visualizer Feed ────────────────────────────────
    // Runs continuously to feed audio data to media visualizer
    // Auto-restarts if it crashes
    // Script: dashboard/cava_feed.sh
    Process {
        id: cavaFeed
        command: ["bash", "dashboard/cava_feed.sh"]
        running: true // Auto-start saat quickshell berjalan
        
        Component.onCompleted: {
            console.log("[CavaFeed] Initialized - auto-start enabled")
        }

        onRunningChanged: {
            if (running) {
                console.log("[CavaFeed] Started successfully")
                cavaFeedRetries = 0
            } else {
                if (exitCode === 0) {
                    console.log("[CavaFeed] Process exited normally")
                } else {
                    console.warn("[CavaFeed] Process stopped (exit code: " + exitCode + "), will restart in 2 seconds")
                    cavaFeedRetries++
                    if (cavaFeedRetries <= maxRetries) {
                        cavaFeedRestartTimer.restart()
                    } else {
                        console.error("[CavaFeed] Max restart retries exceeded")
                    }
                }
            }
        }
    }

    Timer {
        id: cavaFeedRestartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            cavaFeed.running = true
            console.log("[CavaFeed] Attempting restart (" + cavaFeedRetries + "/" + maxRetries + ")...")
        }
    }

    // Public methods untuk trigger screenshot dari shortcuts
    function takeScreenshotSelect() {
        console.log("[Screenshot:Select] Triggered from shortcut")
        screenshotRetries = 0
        screenshotSelectProc.running = true
    }

    function takeScreenshotFull() {
        console.log("[Screenshot:Full] Triggered from shortcut")
        screenshotRetries = 0
        screenshotFullProc.running = true
    }

    // Debug helper
    function getProcessStatus(): string {
        const status = {
            "screenshot_select": screenshotSelectProc.running ? "running" : "idle",
            "screenshot_full": screenshotFullProc.running ? "running" : "idle",
            "btagent": btAgent.running ? "running" : "idle",
            "cava_feed": cavaFeed.running ? "running" : "idle"
        }
        return JSON.stringify(status, null, 2)
    }
}
