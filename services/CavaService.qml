pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sumber data spektrum untuk visualizer (CavaRingDank.qml).
// Menjalankan scripts/qs_visualizer (PipeWire + FFT, tanpa cava & tanpa
// cava_feed.sh) langsung di proses ini saat ada consumer (active = true),
// lalu mematikannya saat tidak ada — hemat CPU/I/O saat dashboard ditutup.
// Nilai dinormalisasi ke 0-100 di `values`.
//
// Set `CavaService.active = true` saat ada consumer (mis. CavaRingDank visible),
// dan `false` saat tidak ada — ini menghentikan proses feed dan mengosongkan
// values sehingga tidak ada sisa CPU/audio-capture saat tidak dipakai.
Item {
    id: cava
    visible: false

    // Dikontrol oleh consumer (CavaRingDank). Saat false, proses feed dimatikan.
    property bool active: false

    property var values: []

    // Sensitivitas gain (0-1). Turunkan kalau ombak terlalu "ramai",
    // naikkan kalau terlalu pelan.
    property real sensitivity: 0.8

    // Path absolut ke binary (quickshell tidak set cwd ke folder config,
    // jadi path relatif tidak resolve).
    property string visualizerPath: Quickshell.shellPath("scripts/qs_visualizer")

    onActiveChanged: {
        if (active) {
            feed.running = true
        } else {
            restartTimer.stop()
            feed.running = false
            values = []
        }
    }

    // qs_visualizer mengalirkan 1 baris per frame ke stdout
    Process {
        id: feed
        running: false
        command: [cava.visualizerPath]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => cava.parse(data)
        }
        onRunningChanged: {
            if (!running && cava.active) {
                restartTimer.restart()
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (cava.active) feed.running = true
        }
    }

    function parse(line) {
        if (!line || line.trim() === "") return
        const parts = line.trim().split(/\s+/)
        const arr = []
        for (let i = 0; i < parts.length; i++) {
            const v = parseInt(parts[i])
            arr.push(isNaN(v) ? 0 : Math.round(Math.min(255, v) / 255 * 100 * cava.sensitivity))
        }
        if (arr.length > 0) values = arr
    }
}