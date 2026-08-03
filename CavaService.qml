pragma Singleton
import QtQuick
import Quickshell.Io

// Sumber data cava untuk visualizer (CavaRingDank.qml).
// Membaca /tmp/qs-cava.out via `tail -f` agar setiap baris baru langsung
// terparsing tanpa polling. File ini ditulis oleh cava_feed.sh.
// Nilai dinormalisasi ke 0-100 di `values`.
Item {
    id: cava
    visible: false

    property var values: []

    // tail -f mengalirkan setiap baris baru langsung saat ditulis ke file
    Process {
        id: tailer
        running: true
        command: ["tail", "-f", "/tmp/qs-cava.out"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => cava.parse(data)
        }
        // restart otomatis kalau berhenti (misal file belum ada saat startup)
        onRunningChanged: {
            if (!running) {
                restartTimer.restart()
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: tailer.running = true
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
