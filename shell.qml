import Quickshell
import Quickshell.Io
import QtQml
import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import Quickshell.Services.Pipewire
import "./bar" as Bar
import "./bar/widgets" as Widgets
import "./lockscreen" as Lock
import "./notifications" as Notif

ShellRoot {
    id: root

    // Handler wallpaper acak yang selalu hidup; dipakai oleh IpcHandler dan
    // klik kanan tombol wallpaper di Bar, tanpa bergantung pada panel.
    Widgets.WallpaperRandom {
        id: wpRandom
    }

    // ── State global (dibagikan antar Bar) ────────────────────────────────
    // Sumber kebenaran untuk panel-panel yang bisa di-toggle dari shortcut
    // Hyprland maupun dari klik di Bar.
    QtObject {
        id: shellStateObj
        property bool dashboardOpen:      false
        property bool powerMenuOpen:      false
        property bool wallpaperPanelOpen: false
        property bool dnd:               false
        property var wallpaperRandom: wpRandom
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

    // ── Screenshot processes (root-level agar bisa dipanggil dari IPC) ───
    // Dipisah dari Bar.qml supaya keybind Hyprland tidak bergantung pada
    // instance Bar tertentu.
    Process {
        id: ipcScreenshotSelectProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave area \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    ipcNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                else
                    ipcNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Dibatalkan",
                        "Area tidak dipilih atau gagal menyimpan."]
                ipcNotifProc.running = true
            }
        }
    }

    Process {
        id: ipcScreenshotFullProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave screen \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    ipcNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                else
                    ipcNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Gagal",
                        "Tidak dapat mengambil screenshot."]
                ipcNotifProc.running = true
            }
        }
    }

    Process { id: ipcNotifProc }

    // ── IPC call: Screenshot ──────────────────────────────────────────────
    // Dari hyprland.conf:
    //   bind = , Print,       exec, quickshell ipc call screenshot full
    //   bind = SHIFT, Print,  exec, quickshell ipc call screenshot select
    IpcHandler {
        target: "screenshot"

        function full(): void {
            ipcScreenshotFullProc.running = true
        }

        function select(): void {
            ipcScreenshotSelectProc.running = true
        }
    }

    // ── IPC call: Wallpaper Panel & Random ────────────────────────────────
    // Dari hyprland.conf:
    //   bind = $mod, W,       exec, quickshell ipc call wallpaper toggle
    //   bind = $mod SHIFT, W, exec, quickshell ipc call wallpaper random
    // `random` selalu aktif via WallpaperRandom (background), jadi bisa
    // dipanggil tanpa membuka panel.
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
            wpRandom.pickRandom()
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

    // ── Notification Popup — root level agar selalu di atas semua ────────
    // Diletakkan di sini (bukan di dalam Bar) supaya render di atas
    // dashboard, panel, dan komponen overlay lainnya.
    Notif.NotificationPopup {
        dnd: shellStateObj.dnd
    }

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
