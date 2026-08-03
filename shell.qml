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
        property bool dashboardOpen: false
        property bool powerMenuOpen: false
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

    // Satu Bar per monitor
    Variants {
        model: Quickshell.screens

        Modules.Bar {
            required property var modelData
            screen: modelData
            shellState: shellStateObj
        }
    }

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
