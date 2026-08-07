pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import "../" as Root

// ── SystemInfo ────────────────────────────────────────────────────────────────
// Panel kanan dashboard: profile picture + face setter, suhu CPU/GPU,
// nama CPU/GPU, usage bar animated, RAM.

Item {
    id: root

    // ── Data state ────────────────────────────────────────────────────────
    property real  cpuUsage:  0      // 0–100
    property real  cpuTemp:   0      // °C
    property real  gpuTemp:   0      // °C
    property real  gpuUsage:  0      // 0–100 (AMDGPU)
    property string ramText:  "—"
    property string cpuName:  "AMD Ryzen 5 7530U"
    property string gpuName:  "AMD Radeon (iGPU)"
    property string faceSource: "file:///home/youtta/.face"

    // Diteruskan ke Bar: Bar menutup dashboard lalu menjalankan file picker
    // (agar window picker tidak tertutup dashboard), dan membuka dashboard
    // lagi setelah selesai.
    signal setFaceRequested()

    // Riwayat CPU usage untuk spark-line (20 titik)
    property var cpuHistory: []

    // ── Weather state ─────────────────────────────────────────────────────
    property string weatherTemp:     ""
    property string weatherFeels:    ""
    property string weatherDesc:     ""
    property string weatherIcon:     "󰖐"
    property string weatherHumidity: ""
    property string weatherWind:     ""
    property string weatherCity:     ""
    property string weatherUpdated:  ""

    // Forecast 3 hari: [{date, dayName, icon, maxC, minC, rain}]
    property var weatherForecast: []

    // Map kondisi cuaca ke ikon Nerd Font weather (glyphnames.json, range U+E3xx)
    function _weatherIcon(desc) {
        const d = desc.toLowerCase()
        if (d.includes("thunder"))                      return "\ue31d"   // weather-thunderstorm
        if (d.includes("drizzle"))                      return "\ue31b"   // weather-sprinkle
        if (d.includes("heavy rain"))                   return "\ue318"   // weather-rain
        if (d.includes("rain") || d.includes("shower")) return "\ue319"   // weather-showers
        if (d.includes("snow"))                         return "\ue31a"   // weather-snow
        if (d.includes("fog") || d.includes("mist"))    return "\ue313"   // weather-fog
        if (d.includes("haze") || d.includes("smoky"))  return "\ue3ae"   // weather-day_haze
        if (d.includes("overcast"))                     return "\ue312"   // weather-cloudy
        if (d.includes("partly"))                       return "\ue30c"   // weather-day_sunny_overcast
        if (d.includes("cloudy"))                       return "\ue312"   // weather-cloudy
        if (d.includes("sunny") || d.includes("clear")) return "\ue30d"   // weather-day_sunny
        return "\ue312"
    }

    // Nama hari singkat dari date string "YYYY-MM-DD"
    function _dayName(dateStr) {
        const days = ["Min","Sen","Sel","Rab","Kam","Jum","Sab"]
        const d = new Date(dateStr)
        return days[d.getDay()]
    }

    // ── Pollers ───────────────────────────────────────────────────────────

    // CPU usage — delta /proc/stat
    property var _cpuPrev: null
    Process {
        id: cpuStatProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).slice(1).map(Number)
                const idle = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)
                if (root._cpuPrev) {
                    const dTotal = total - root._cpuPrev.total
                    const dIdle  = idle  - root._cpuPrev.idle
                    root.cpuUsage = dTotal > 0 ? Math.round((1 - dIdle / dTotal) * 100) : 0
                    // append ke history
                    const h = root.cpuHistory.slice()
                    h.push(root.cpuUsage)
                    if (h.length > 20) h.shift()
                    root.cpuHistory = h
                }
                root._cpuPrev = { total, idle }
            }
        }
    }

    // CPU temp (k10temp Tctl) — hwmon5/temp1_input dalam milli-celsius
    Process {
        id: cpuTempProc
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon5/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTemp = Math.round(parseInt(text.trim()) / 1000)
        }
    }

    // GPU temp (amdgpu edge) — hwmon4/temp1_input
    Process {
        id: gpuTempProc
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon4/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: root.gpuTemp = Math.round(parseInt(text.trim()) / 1000)
        }
    }

    // GPU usage — /sys/class/drm/card*/device/gpu_busy_percent
    Process {
        id: gpuUsageProc
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                root.gpuUsage = isNaN(v) ? 0 : v
            }
        }
    }

    // RAM
    Process {
        id: ramProc
        command: ["sh", "-c",
            "free -b | awk '/^Mem:/ {used=$2-$7; printf \"%s / %s\", int(used/1073741824*10)/10\"G\", int($2/1073741824*10)/10\"G\"}'"]
        stdout: StdioCollector {
            onStreamFinished: root.ramText = text.trim()
        }
    }

    // ── Weather poller (wttr.in, update tiap 15 menit) ───────────────────
    Process {
        id: weatherProc
        command: ["sh", "-c", "curl -s --max-time 8 'wttr.in/?format=j1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    const cur  = d.current_condition[0]
                    const area = d.nearest_area[0]
                    root.weatherTemp     = cur.temp_C
                    root.weatherFeels    = cur.FeelsLikeC
                    root.weatherDesc     = cur.weatherDesc[0].value
                    root.weatherIcon     = root._weatherIcon(cur.weatherDesc[0].value)
                    root.weatherHumidity = cur.humidity
                    root.weatherWind     = cur.windspeedKmph
                    root.weatherCity     = area.areaName[0].value
                    const now = new Date()
                    root.weatherUpdated  = Qt.formatDateTime(now, "HH:mm")

                    // Parse 3-hari forecast
                    const forecast = []
                    for (let i = 0; i < d.weather.length; i++) {
                        const w = d.weather[i]
                        // Ambil deskripsi dari tengah hari (index 4 = jam 12:00)
                        const mid = w.hourly[Math.floor(w.hourly.length / 2)]
                        forecast.push({
                            dayName: i === 0 ? "Hari ini" : i === 1 ? "Besok" : root._dayName(w.date),
                            icon:    root._weatherIcon(mid.weatherDesc[0].value),
                            maxC:    w.maxtempC,
                            minC:    w.mintempC,
                            rain:    mid.chanceofrain,
                            desc:    mid.weatherDesc[0].value
                        })
                    }
                    root.weatherForecast = forecast
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 900000   // 15 menit
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // Tick tiap 2 detik
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            cpuStatProc.running = true
            cpuTempProc.running = true
            gpuTempProc.running = true
            gpuUsageProc.running = true
            ramProc.running     = true
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ── Profile card ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100   // fixed — avatar butuh ruang tetap
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Avatar + klik untuk ganti
                Item {
                    width: 72; height: 72

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Root.Colors.surface0
                        border.color: Root.Colors.lavender
                        border.width: 2
                    }

                    // Isi avatar bulat via MultiEffect mask (Rectangle.clip tak ikut radius)
                    Rectangle {
                        id: faceBg
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: Root.Colors.surface0
                    }

                    Image {
                        id: faceImg
                        anchors.fill: parent
                        anchors.margins: 3
                        source: root.faceSource
                        sourceSize.width: 200
                        sourceSize.height: 200
                        fillMode: Image.PreserveAspectCrop
                        smooth: true; mipmap: true
                        cache: false
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: faceImg.width
                                    height: faceImg.height
                                    radius: width / 2
                                    color: "white"
                                    visible: false
                                }
                            }
                        }
                    }

                    // Fallback
                    Text {
                        anchors.centerIn: parent
                        visible: faceImg.status !== Image.Ready
                        text: "󰀄"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 36
                        color: Root.Colors.subtext
                    }

                    // Hover overlay — klik buka file picker
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.45)
                        opacity: editHover.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰷌"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 22
                            color: "white"
                        }

                        MouseArea {
                            id: editHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setFaceRequested()
                        }
                    }
                }

                // Info user
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "youtta"
                        font.pixelSize: 15
                        font.weight: Font.SemiBold
                        color: Root.Colors.text
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        text: "󰄛  " + root.cpuName.replace(/AMD Ryzen /, "Ryzen ").replace(/ with.*/, "")
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "󰾲  " + root.gpuName
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // RAM inline
                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰍛"
                            font.pixelSize: 11
                            color: Root.Colors.green
                        }
                        Text {
                            text: root.ramText
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                        }
                    }
                }
            }
        }

        // ── CPU card ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                id: cpuCardCol
                anchors {
                    top: parent.top; left: parent.left
                    right: parent.right; margins: 10
                }
                spacing: 4

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰻠  CPU"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Root.Colors.blue
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.cpuTemp + "°C"
                        font.pixelSize: 11
                        color: root.cpuTemp > 85 ? Root.Colors.red
                             : root.cpuTemp > 70 ? Root.Colors.yellow
                             : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    Text {
                        text: "  " + root.cpuUsage + "%"
                        font.pixelSize: 11
                        font.weight: Font.SemiBold
                        color: Root.Colors.blue
                    }
                }

                // Usage bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 2.5
                    color: Root.Colors.surface1

                    Rectangle {
                        width: parent.width * root.cpuUsage / 100
                        height: parent.height
                        radius: parent.radius
                        color: root.cpuUsage > 85 ? Root.Colors.red
                             : root.cpuUsage > 60 ? Root.Colors.yellow
                             : Root.Colors.blue
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                // Spark-line CPU history
                Canvas {
                    id: sparkCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    Layout.minimumHeight: 12

                    property var data: root.cpuHistory

                    onDataChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        const pts = data
                        if (pts.length < 2) return

                        // Fill area
                        ctx.beginPath()
                        ctx.moveTo(0, height)
                        for (let i = 0; i < pts.length; i++) {
                            const x = (i / (pts.length - 1)) * width
                            const y = height - (pts[i] / 100) * height
                            i === 0 ? ctx.lineTo(x, y) : ctx.lineTo(x, y)
                        }
                        ctx.lineTo(width, height)
                        ctx.closePath()

                        const grad = ctx.createLinearGradient(0, 0, 0, height)
                        grad.addColorStop(0,   Qt.rgba(
                            Qt.color(Root.Colors.blue).r,
                            Qt.color(Root.Colors.blue).g,
                            Qt.color(Root.Colors.blue).b, 0.35))
                        grad.addColorStop(1,   Qt.rgba(
                            Qt.color(Root.Colors.blue).r,
                            Qt.color(Root.Colors.blue).g,
                            Qt.color(Root.Colors.blue).b, 0.03))
                        ctx.fillStyle = grad
                        ctx.fill()

                        // Line
                        ctx.beginPath()
                        for (let i = 0; i < pts.length; i++) {
                            const x = (i / (pts.length - 1)) * width
                            const y = height - (pts[i] / 100) * height
                            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
                        }
                        ctx.strokeStyle = Root.Colors.blue.toString()
                        ctx.lineWidth = 1.5
                        ctx.stroke()
                    }

                    Connections {
                        target: Root.Colors
                        function onBaseChanged() { sparkCanvas.requestPaint() }
                    }
                }
            }
        }

        // ── GPU card ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 76   // GPU tidak punya spark-line, cukup fixed kecil
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰾲  GPU"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Root.Colors.mauve
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.gpuTemp + "°C"
                        font.pixelSize: 12
                        color: root.gpuTemp > 90 ? Root.Colors.red
                             : root.gpuTemp > 75 ? Root.Colors.yellow
                             : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    Text {
                        text: "  " + root.gpuUsage + "%"
                        font.pixelSize: 12
                        font.weight: Font.SemiBold
                        color: Root.Colors.mauve
                    }
                }

                // Usage bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Root.Colors.surface1

                    Rectangle {
                        width: parent.width * root.gpuUsage / 100
                        height: parent.height
                        radius: parent.radius
                        color: root.gpuUsage > 85 ? Root.Colors.red
                             : root.gpuUsage > 60 ? Root.Colors.yellow
                             : Root.Colors.mauve
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                // GPU name kecil
                Text {
                    text: root.gpuName
                    font.pixelSize: 10
                    color: Root.Colors.surface2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // ── Weather card ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true          // ambil sisa ruang di bawah GPU
            Layout.minimumHeight: 130        // cukup kecil agar tak melebihi dashboard
            radius: 14
            color: Root.Colors.base
            clip: true
            Behavior on color { ColorAnimation { duration: 200 } }

            // Isi bisa discroll kalau kartu lebih pendek dari konten cuaca,
            // sehingga tidak pernah meluber melewati batas dashboard.
            Flickable {
                id: weatherFlick
                anchors.fill: parent
                anchors.margins: 14
                contentWidth: weatherFlick.width
                contentHeight: Math.max(weatherCol.implicitHeight, weatherFlick.height)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    id: weatherCol
                    width: weatherFlick.width
                    spacing: 10

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰖐  Cuaca"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Root.Colors.peach
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.weatherCity
                        font.pixelSize: 12
                        color: Root.Colors.subtext
                        elide: Text.ElideRight
                    }
                }

                // Suhu besar + ikon kondisi
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: root.weatherIcon
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 36
                        color: Root.Colors.peach
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: root.weatherTemp !== "" ? root.weatherTemp + "°C" : "—"
                            font.pixelSize: 30
                            font.weight: Font.Bold
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: root.weatherDesc
                            font.pixelSize: 13
                            color: Root.Colors.subtext
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Feels like + humidity + wind
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Terasa " + (root.weatherFeels !== "" ? root.weatherFeels + "°C" : "—")
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                        }
                        Text {
                            text: "󰖌 " + (root.weatherHumidity !== "" ? root.weatherHumidity + "%" : "—")
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                        }
                        Text {
                            text: "󰞄 " + (root.weatherWind !== "" ? root.weatherWind + " km/h" : "—")
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                // Last updated
                Text {
                    text: root.weatherUpdated !== "" ? "Diperbarui: " + root.weatherUpdated : ""
                    font.pixelSize: 10
                    color: Root.Colors.surface2
                    visible: root.weatherUpdated !== ""
                }

                // Spacer agar forecast duduk di bawah kartu
                Item { Layout.fillHeight: true }

                // ── Garis pemisah ─────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Root.Colors.surface1
                    visible: root.weatherForecast.length > 0
                }

                // ── 3-hari forecast ───────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    visible: root.weatherForecast.length > 0

                    Repeater {
                        model: root.weatherForecast

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            height: forecastCol.implicitHeight + 14
                            radius: 10
                            color: index === 0 ? Root.Colors.surface0 : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }

                            // Pemisah antar hari (kecuali pertama)
                            Rectangle {
                                visible: index > 0
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 8
                                anchors.bottomMargin: 8
                                width: 1
                                color: Root.Colors.surface1
                            }

                            ColumnLayout {
                                id: forecastCol
                                anchors.centerIn: parent
                                spacing: 3

                                // Nama hari
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.dayName
                                    font.pixelSize: 11
                                    font.weight: index === 0 ? Font.SemiBold : Font.Normal
                                    color: index === 0 ? Root.Colors.peach : Root.Colors.subtext
                                }

                                // Ikon cuaca
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 24
                                    color: Root.Colors.text
                                }

                                // Max / Min
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.maxC + "°"
                                    font.pixelSize: 15
                                    font.weight: Font.SemiBold
                                    color: Root.Colors.text
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.minC + "°"
                                    font.pixelSize: 12
                                    color: Root.Colors.subtext
                                }

                                // Chance of rain
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 3
                                    visible: parseInt(modelData.rain) > 0
                                    Text {
                                        text: "󰖌"
                                        font.pixelSize: 11
                                        color: Root.Colors.blue
                                    }
                                    Text {
                                        text: modelData.rain + "%"
                                        font.pixelSize: 11
                                        color: Root.Colors.blue
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }

        // Spacer kecil di bawah agar tidak mepet pinggir
        Item { Layout.preferredHeight: 0 }
    }

}
