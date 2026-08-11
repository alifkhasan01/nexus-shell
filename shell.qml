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

    // Handler wallpaper acak yang selalu hidup; dipakai oleh GlobalShortcut dan
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
        property bool menuOpen:          false
        property bool dnd:               false
        property var wallpaperRandom: wpRandom
        // Fungsi lock — dipanggil oleh PowerMenu.qml (itemLock & suspend)
        // tanpa perlu IPC; di-wire ke lockScreenRef.lock() setelah LockScreen load.
        property var lockFn: function() { lockScreenRef.lock() }
    }

    // ── Global shortcut: Dashboard ─────────────────────────────────────────
    // Bind di hyprland.conf:  bind = $mod, D, global, quickshell:dashboard
    GlobalShortcut {
        appid: "quickshell"
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: shellStateObj.dashboardOpen = !shellStateObj.dashboardOpen
    }

    // ── Global shortcut: Power Menu ────────────────────────────────────────
    // Bind di hyprland.conf:  bind = $mod, P, global, quickshell:powermenu
    GlobalShortcut {
        appid: "quickshell"
        name: "powermenu"
        description: "Toggle power menu"
        onPressed: shellStateObj.powerMenuOpen = !shellStateObj.powerMenuOpen
    }

    // ── Global shortcut: Menu Panel ────────────────────────────────────────
    // Bind di hyprland.conf:  bind = $mod, M, global, quickshell:menu
    GlobalShortcut {
        appid: "quickshell"
        name: "menu"
        description: "Toggle menu panel"
        onPressed: shellStateObj.menuOpen = !shellStateObj.menuOpen
    }

    // ── Global shortcut: Lock Screen ───────────────────────────────────────
    // Bind di hyprland.conf:  bind = $mod, L, global, quickshell:lock
    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        description: "Lock screen"
        onPressed: lockScreenRef.lock()
    }

    // ── Screenshot processes (root-level agar bisa dipanggil dari shortcut) ─
    // Dipisah dari Bar.qml supaya keybind Hyprland tidak bergantung pada
    // instance Bar tertentu.
    Process {
        id: screenshotSelectProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave area \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                else
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Dibatalkan",
                        "Area tidak dipilih atau gagal menyimpan."]
                screenshotNotifProc.running = true
            }
        }
    }

    Process {
        id: screenshotFullProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave screen \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=camera-photo",
                        "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard"]
                else
                    screenshotNotifProc.command = ["notify-send", "--app-name=Quickshell",
                        "--expire-time=4000", "--icon=dialog-error",
                        "Screenshot Gagal",
                        "Tidak dapat mengambil screenshot."]
                screenshotNotifProc.running = true
            }
        }
    }

    Process { id: screenshotNotifProc }

    // ── Global shortcut: Screenshot ────────────────────────────────────────
    // Bind di hyprland.conf:
    //   bind = , Print,       global, quickshell:screenshot-full
    //   bind = SHIFT, Print,  global, quickshell:screenshot-select
    GlobalShortcut {
        appid: "quickshell"
        name: "screenshot-full"
        description: "Screenshot seluruh layar"
        onPressed: screenshotFullProc.running = true
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "screenshot-select"
        description: "Screenshot area pilihan"
        onPressed: screenshotSelectProc.running = true
    }

    // ── Global shortcut: Wallpaper Panel & Random ──────────────────────────
    // Bind di hyprland.conf:
    //   bind = $mod, W,       global, quickshell:wallpaper-toggle
    //   bind = $mod SHIFT, W, global, quickshell:wallpaper-random
    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-toggle"
        description: "Toggle wallpaper panel"
        onPressed: shellStateObj.wallpaperPanelOpen = !shellStateObj.wallpaperPanelOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-random"
        description: "Ganti wallpaper acak"
        onPressed: wpRandom.pickRandom()
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
    // GlobalShortcut (quickshell:lock) memanggil lockScreenRef.lock().
    Lock.LockScreen {
        id: lockScreenRef
    }

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
