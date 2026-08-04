import Quickshell
import Quickshell.Io
import QtQml
import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import Quickshell.Services.Pipewire
import "./bar" as Bar
import "./lockscreen" as Lock

ShellRoot {
    id: root

    // ── State global (dibagikan antar Bar) ────────────────────────────────
    // Sumber kebenaran untuk panel-panel yang bisa di-toggle dari shortcut
    // Hyprland maupun dari klik di Bar.
    QtObject {
        id: shellStateObj
        property bool dashboardOpen:      false
        property bool powerMenuOpen:      false
        property bool wallpaperPanelOpen: false
        property int randomWallpaperToken: 0
        property bool randomWallpaperConsumed: false
    }

    // ── Global shortcut: Dashboard ─────────────────────────────────────────
    // Bind di hyprland.conf:  bind = $mod, D, global, quickshell:dashboard
    GlobalShortcut {
        appid: "quickshell"
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: shellStateObj.dashboardOpen = !shellStateObj.dashboardOpen
    }

    // ── IPC call: Power Menu ───────────────────────────────────────────────
    // Panggil dari hyprland.conf:
    //   bind = $mod, P, exec, quickshell ipc call powermenu toggle
    // Atau dari terminal / script:
    //   quickshell ipc call powermenu toggle
    IpcHandler {
        target: "powermenu"

        function toggle() {
            shellStateObj.powerMenuOpen = !shellStateObj.powerMenuOpen
        }
    }

    // ── IPC call: Wallpaper Panel ──────────────────────────────────────────
    // Dari hyprland.conf:
    //   bind = $mod, W,       exec, quickshell ipc call wallpaper toggle
    //   bind = $mod SHIFT, W, exec, quickshell ipc call wallpaper random
    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            shellStateObj.wallpaperPanelOpen = !shellStateObj.wallpaperPanelOpen
        }

        function open(): void {
            shellStateObj.wallpaperPanelOpen = true
        }

        function close(): void {
            shellStateObj.wallpaperPanelOpen = false
        }

        function random(): void {
            // Teruskan ke WallpaperPanel via token (bukan wallpicker).
            shellStateObj.randomWallpaperConsumed = false
            shellStateObj.randomWallpaperToken += 1
        }
    }

    // Satu Bar per monitor
    Variants {
        model: Quickshell.screens

        Bar.Bar {
            required property var modelData
            screen: modelData
            shellState: shellStateObj
        }
    }

    // ── Lock Screen ───────────────────────────────────────────────────────
    // WlSessionLock harus ada satu instance di root (bukan di dalam Bar),
    // karena ia menutup SEMUA monitor sekaligus via ext_session_lock_v1.
    // IpcHandler (target: "lockscreen") sudah ada di dalam LockScreen.qml.
    Lock.LockScreen {}

    // ── Auto-pairing BlueZ agent (berjalan di background) ─────────────────
    // Menjawab "yes" pada prompt pair/confirm bluetooth sehingga perangkat
    // bisa connect langsung dari panel tanpa input terminal.
    // Dijalankan sekali saat startup; jika crash, tidak direstart otomatis
    // (bluetoothd biasanya sudah handle re-registration sendiri).
    Process {
        id: btAgent
        command: ["bash", "scripts/btagent.sh"]
        running: true
        // Restart sekali jika crash, dengan jeda 5 detik
        onRunningChanged: {
            if (!running) btAgentRestartTimer.restart()
        }
    }

    Timer {
        id: btAgentRestartTimer
        interval: 5000
        repeat: false
        onTriggered: btAgent.running = true
    }

    // ── Cava audio visualizer feed ────────────────────────────────────────
    // Hanya berjalan saat dashboard terbuka (tab Media butuh data cava).
    // Hemat CPU & I/O saat dashboard tidak dipakai.
    Process {
        id: cavaFeed
        command: ["bash", "dashboard/cava_feed.sh"]
        running: shellStateObj.dashboardOpen
        onRunningChanged: {
            // Restart otomatis hanya saat dashboard sedang terbuka
            if (!running && shellStateObj.dashboardOpen) {
                cavaFeedRestartTimer.restart()
            }
        }
    }

    Timer {
        id: cavaFeedRestartTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (shellStateObj.dashboardOpen) cavaFeed.running = true
        }
    }

    // ── Biasakan sink bluetooth jadi default ─────────────────────────────
    // Saat perangkat bluetooth (headphone/dst) terhubung, sink audionya
    // dijadikan default agar slider volume di Bar & Dashboard ikut
    // mengontrol volume perangkat bluetooth tersebut.
    Item {
        visible: false

        Repeater {
            model: Pipewire.nodes

            delegate: Item {
                required property var modelData

                Component.onCompleted: promote()
                onModelDataChanged: promote()

                function promote() {
                    const sink = modelData
                    if (!sink || !sink.audio || !sink.isSink) return
                    const props = sink.properties || {}
                    if (props["device.bus"] !== "bluetooth") return

                    const cur = Pipewire.defaultAudioSink
                    if (!cur || cur.id !== sink.id)
                        Pipewire.preferredDefaultAudioSink = sink
                }
            }
        }
    }
}
