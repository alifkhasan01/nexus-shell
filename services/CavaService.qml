pragma Singleton
import QtQuick
import Quickshell.Io

// Sumber data cava untuk visualizer (CavaRingDank.qml).
// Membaca /tmp/qs-cava.out via `tail -f` agar setiap baris baru langsung
// terparsing tanpa polling. File ini ditulis oleh cava_feed.sh.
// Nilai dinormalisasi ke 0-100 di `values`.
//
// Set `CavaService.active = true` saat ada consumer (mis. CavaRingDank visible),
// dan `false` saat tidak ada — ini menghentikan tail -f dan mengosongkan values
// sehingga tidak ada CPU/I/O sisa saat dashboard ditutup.
Item {
    id: cava
    visible: false

    // Dikontrol oleh consumer (CavaRingDank). Saat false, tail -f dimatikan.
    property bool active: false

    property var values: []

    onActiveChanged: {
        if (active) {
            tailer.running = true
        } else {
            restartTimer.stop()
            tailer.running = false
            values = []
        }
    }

    // tail -f mengalirkan setiap baris baru langsung saat ditulis ke file
    Process {
        id: tailer
        running: false
        command: ["tail", "-F", "/tmp/qs-cava.out"]
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
            if (cava.active) tailer.running = true
        }
    }

    function parse(line) {
        if (!line || line.trim() === "") return
        const parts = line.trim().split(/\s+/)
        const arr = []
        for (let i = 0; i < parts.length; i++) {
            const v = parseInt(parts[i])
            arr.push(isNaN(v) ? 0 : Math.round(Math.min(255, v) / 255 * 100))
        }
        if (arr.length > 0) values = arr
    }
}
