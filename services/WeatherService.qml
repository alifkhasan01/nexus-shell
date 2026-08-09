pragma Singleton
import QtQuick
import Quickshell.Io

// WeatherService — fetch wttr.in sekali tiap 15 menit, hidup terus di background.
// Data tersedia langsung saat dashboard dibuka tanpa fetch ulang.
// Gunakan dari QML mana saja:
//   import "../../" as Root
//   Root.WeatherService.temp  (dll)
QtObject {
    id: root

    // ── State yang diexpose ───────────────────────────────────────────────
    readonly property string temp:     _temp
    readonly property string feels:    _feels
    readonly property string desc:     _desc
    readonly property string icon:     _icon
    readonly property string humidity: _humidity
    readonly property string wind:     _wind
    readonly property string city:     _city
    readonly property string updated:  _updated
    readonly property bool   loading:  _loading
    readonly property bool   hasData:  _city !== ""

    // Forecast 3 hari: [{dayName, icon, maxC, minC, rain, desc}]
    readonly property var forecast: _forecast

    // ── State internal (writable) ─────────────────────────────────────────
    property string _temp:     ""
    property string _feels:    ""
    property string _desc:     ""
    property string _icon:     "󰖐"
    property string _humidity: ""
    property string _wind:     ""
    property string _city:     ""
    property string _updated:  ""
    property bool   _loading:  false
    property var    _forecast: []

    // ── Helper: map deskripsi cuaca → ikon Nerd Font ──────────────────────
    function weatherIcon(desc) {
        const d = desc.toLowerCase()
        if (d.includes("thunder"))                       return "\ue31d"
        if (d.includes("drizzle"))                       return "\ue31b"
        if (d.includes("heavy rain"))                    return "\ue318"
        if (d.includes("rain") || d.includes("shower"))  return "\ue319"
        if (d.includes("snow"))                          return "\ue31a"
        if (d.includes("fog")  || d.includes("mist"))    return "\ue313"
        if (d.includes("haze") || d.includes("smoky"))   return "\ue3ae"
        if (d.includes("overcast"))                      return "\ue312"
        if (d.includes("partly"))                        return "\ue30c"
        if (d.includes("cloudy"))                        return "\ue312"
        if (d.includes("sunny") || d.includes("clear"))  return "\ue30d"
        return "\ue312"
    }

    // ── Helper: nama hari singkat dari "YYYY-MM-DD" ───────────────────────
    function dayName(dateStr) {
        const days = ["Min","Sen","Sel","Rab","Kam","Jum","Sab"]
        return days[new Date(dateStr).getDay()]
    }

    // ── Fetch process ─────────────────────────────────────────────────────
    property Process _proc: Process {
        command: ["sh", "-c", "curl -s --max-time 10 'wttr.in/?format=j1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._loading = false
                try {
                    const d    = JSON.parse(text)
                    const cur  = d.current_condition[0]
                    const area = d.nearest_area[0]

                    root._temp     = cur.temp_C
                    root._feels    = cur.FeelsLikeC
                    root._desc     = cur.weatherDesc[0].value
                    root._icon     = root.weatherIcon(cur.weatherDesc[0].value)
                    root._humidity = cur.humidity
                    root._wind     = cur.windspeedKmph
                    root._city     = area.areaName[0].value
                    root._updated  = Qt.formatDateTime(new Date(), "HH:mm")

                    const fc = []
                    for (let i = 0; i < d.weather.length; i++) {
                        const w   = d.weather[i]
                        const mid = w.hourly[Math.floor(w.hourly.length / 2)]
                        fc.push({
                            dayName: i === 0 ? "Hari ini"
                                   : i === 1 ? "Besok"
                                   : root.dayName(w.date),
                            icon:    root.weatherIcon(mid.weatherDesc[0].value),
                            maxC:    w.maxtempC,
                            minC:    w.mintempC,
                            rain:    mid.chanceofrain,
                            desc:    mid.weatherDesc[0].value
                        })
                    }
                    root._forecast = fc
                } catch(e) {
                    // JSON invalid / network error — data lama tetap tersimpan
                }
            }
        }
    }

    // ── Timer: fetch tiap 15 menit, langsung saat startup ─────────────────
    property Timer _timer: Timer {
        interval: 900000   // 15 menit
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._proc.running) {
                root._loading = true
                root._proc.running = true
            }
        }
    }
}
