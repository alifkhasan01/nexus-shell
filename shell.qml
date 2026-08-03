import Quickshell
import Quickshell.Io
import QtQml
import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import Quickshell.Services.Pipewire
import "./modules" as Modules

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
            randomWallpaperProc.running = false
            randomWallpaperProc.running = true
        }
    }

    // Jalankan wallpicker --random untuk set wallpaper acak via IPC.
    Process {
        id: randomWallpaperProc
        command: ["wallpicker", "--random"]
    }

    // Satu Bar per monitor
    Variants {
        model: Quickshell.screens

        Modules.Bar {
            required property var modelData
            screen: modelData
            shellState: shellStateObj
        }
    }

    // ── Lock Screen ───────────────────────────────────────────────────────
    // WlSessionLock harus ada satu instance di root (bukan di dalam Bar),
    // karena ia menutup SEMUA monitor sekaligus via ext_session_lock_v1.
    // IpcHandler (target: "lockscreen") sudah ada di dalam LockScreen.qml.
    Modules.LockScreen {}

    // ── Auto-pairing BlueZ agent (berjalan di background) ─────────────────
    // Menjawab "yes" pada prompt pair/confirm bluetooth sehingga perangkat
    // bisa connect langsung dari panel tanpa input terminal.
    Process {
        id: btAgent
        command: ["bash", "modules/btagent.sh"]
        running: true
    }

    // ── Cava audio visualizer feed ────────────────────────────────────────
    // Menjalankan cava_feed.sh yang menulis bar data ke /tmp/qs-cava.out
    // untuk dipakai oleh CavaService → CavaRingDank di tab Media dashboard.
    Process {
        id: cavaFeed
        command: ["bash", "modules/dashboard/cava_feed.sh"]
        running: true
        // restart otomatis kalau crash
        onRunningChanged: if (!running) running = true
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
