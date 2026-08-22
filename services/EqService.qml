pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Service singleton untuk state EasyEffects EQ — pola sama seperti WallpaperService.
// Membaca preset aktif langsung dari config EasyEffects (lastLoadedOutputPreset)
// sehingga MediaPanel selalu tahu preset yang sedang berjalan tanpa perlu
// panel dibuka dulu, dan tetap sinkron walau preset diganti dari GUI/CLI EE.
QtObject {
    id: service

    // ── State sumber kebenaran ────────────────────────────────────────────
    property string activePreset: ""
    property var bands: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    // ── Konstanta ─────────────────────────────────────────────────────────
    // 10-band: 31 63 125 250 500 1k 2k 4k 8k 16k
    readonly property var eqLabels: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var presets: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]

    // Gain default per preset (index matches bands) — dipakai sebagai nilai
    // optimistik saat klik preset; nilai asli di-resync dari file preset EE.
    readonly property var presetValues: ({
        "Flat":    [ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
        "Bass":    [ 6,  5,  3,  1,  0,  0, -1, -1, -2, -2],
        "Treble":  [-2, -2, -1,  0,  0,  1,  3,  4,  5,  6],
        "Vocal":   [-2, -1,  0,  1,  3,  4,  4,  3,  1,  0],
        "Pop":     [-1,  2,  3,  2,  0, -1,  2,  3,  2,  1],
        "Rock":    [ 5,  4,  3, -1, -2,  0,  1,  3,  4,  3],
        "Jazz":    [ 3,  2,  1,  2,  0, -1,  0,  2,  3,  2],
        "Classic": [ 0,  0,  0,  0, -2, -2,  0,  3,  4,  4]
    })

    // ── Guard polling ─────────────────────────────────────────────────────
    // dragging      : user sedang menyeret slider → jangan timpa bands dari disk
    // pendingCustom : Custom EQ baru saja di-apply → tunggu EE menulis ulang
    //                 lastLoadedOutputPreset=Custom sebelum sync lagi
    property bool dragging: false
    property bool pendingCustom: false

    // ── Polling timer seperti WallpaperService ────────────────────────────
    property Timer pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.refresh()
    }

    // Baca nama preset terakhir yang di-load EasyEffects
    property Process readProc: Process {
        command: ["sh", "-c",
            "grep '^lastLoadedOutputPreset=' ~/.config/easyeffects/db/easyeffectsrc 2>/dev/null | cut -d= -f2 || echo Flat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name.length === 0) return
                if (name === service.activePreset) return
                if (service.dragging) return
                // Saat menunggu konfirmasi Custom, abaikan nilai lama dari EE
                if (service.pendingCustom && name !== "Custom") return
                service.pendingCustom = false
                service.activePreset = name
                service.syncBands(name)
            }
        }
    }

    // Baca gain per band dari file preset agar slider mencerminkan state asli
    property Process bandProc: Process {
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return
                try {
                    const json = JSON.parse(text)
                    const eq = json.output["equalizer#0"]
                    if (!eq) return
                    const ch = eq.left ?? {}
                    const arr = []
                    for (let i = 0; i < 10; i++) {
                        const b = ch["band" + i]
                        arr.push(b && b.gain !== undefined ? b.gain : 0)
                    }
                    service.bands = arr
                } catch (e) {
                    // File tidak ada / JSON invalid → pertahankan nilai saat ini
                }
            }
        }
    }

    function refresh() {
        if (!readProc.running) readProc.running = true
    }

    function syncBands(name) {
        bandProc.command = ["sh", "-c",
            `cat ~/.local/share/easyeffects/output/${name}.json 2>/dev/null`]
        bandProc.running = false
        bandProc.running = true
    }

    // Load preset — update UI optimistik lalu terapkan via CLI
    function loadPreset(name) {
        if (!presets.includes(name)) return
        dragging = false
        pendingCustom = false
        activePreset = name
        const vals = presetValues[name]
        if (vals) bands = vals.slice()
        Quickshell.execDetached(["easyeffects", "--load-preset", name])
    }

    // Set satu band saat slider digeser (update UI instan)
    function setBand(index, value) {
        const arr = bands.slice()
        arr[index] = value
        bands = arr
    }

    // Simpan custom EQ lalu load ke EasyEffects (dipindah dari MediaPanel).
    // Schema EasyEffects 7/8: band harus nested di "left"/"right",
    // preset disimpan di ~/.local/share/easyeffects/output/
    property Process saveProc: Process { command: [] }

    function applyCustomEq() {
        const b = bands
        const freq = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        let bandObj = ""
        for (let i = 0; i < 10; i++) {
            bandObj += `"band${i}": { "frequency": ${freq[i]}.0, "gain": ${b[i].toFixed(1)}, "mode": "RLC(BT)", "mute": false, "q": 1.5047, "slope": "x1", "solo": false, "type": "Bell" }`
            if (i < 9) bandObj += ",\n        "
        }
        const json = `{
  "output": {
    "blocklist": [],
    "equalizer#0": {
      "bypass": false,
      "input-gain": 0.0,
      "output-gain": 0.0,
      "mode": "IIR",
      "num-bands": 10,
      "split-channels": false,
      "left": {
        ${bandObj}
      },
      "right": {
        ${bandObj}
      }
    },
    "plugins_order": ["equalizer#0"]
  }
}`
        saveProc.command = ["sh", "-c",
            `mkdir -p ~/.local/share/easyeffects/output && printf '%s' '${json.replace(/'/g, `'\\''`)}' > ~/.local/share/easyeffects/output/Custom.json && easyeffects --load-preset Custom`
        ]
        saveProc.running = false
        saveProc.running = true

        activePreset = "Custom"
        pendingCustom = true
    }

    Component.onCompleted: refresh()
}
