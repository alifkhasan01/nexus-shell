pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import "../" as Root


// ── SystemInfo ────────────────────────────────────────────────────────────────
// Panel kanan dashboard: profile picture + face setter, CPU/GPU/RAM/Disk
// dalam satu card statistik, lalu weather card memakai sisa ruang.
// Data cuaca dibaca langsung dari Root.WeatherService (singleton, always-on).

Item {
    id: root

// ── StatRow — satu baris kompak untuk CPU / GPU / RAM / Disk ─────────
component StatRow: Item {
    id: box

    property string label: ""
    property string icon: ""
    property color accent: Root.Colors.blue
    property real pct: 0
    property string tempText: ""
    property color tempColor: Root.Colors.subtext
    property string subText: ""

    Layout.fillWidth: true
    implicitHeight: 28

    RowLayout {
        anchors.fill: parent
        spacing: 6

        // Ikon
        Text {
            text: box.icon
            font.pixelSize: 13
            color: box.tempColor
            Layout.preferredWidth: 16
            horizontalAlignment: Text.AlignHCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Label
        Text {
            text: box.label
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Root.Colors.text
            Layout.preferredWidth: 28
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Bar
        Rectangle {
            Layout.fillWidth: true
            height: 5
            radius: 2.5
            color: Root.Colors.surface1
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, box.pct)) / 100
                height: parent.height
                radius: parent.radius
                color: box.tempColor
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        // Persentase
        Text {
            text: Math.round(box.pct) + "%"
            font.pixelSize: 11
            font.weight: Font.SemiBold
            color: box.tempColor
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Temp atau sub-teks pendek
        Text {
            visible: box.tempText !== "" || box.subText !== ""
            text: box.tempText !== "" ? box.tempText : box.subText
            font.pixelSize: 10
            color: Root.Colors.subtext
            elide: Text.ElideRight
            Layout.preferredWidth: 60
            horizontalAlignment: Text.AlignRight
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}


    // ── Data state ────────────────────────────────────────────────────────
    property real   cpuUsage:  0
    property real   cpuTemp:   0
    property real   gpuTemp:   0
    property real   gpuUsage:  0
    property string ramText:   "—"
    property real   ramUsage:  0
    property string cpuName:   "AMD Ryzen 5 7530U"
    property string gpuName:   "AMD Radeon (iGPU)"
    property string faceSource: "file:///home/xans/.face"

    property string diskText:  "—"
    property real   diskUsage: 0

    signal setFaceRequested()

    // ── Pollers ───────────────────────────────────────────────────────────

    // CPU usage — delta /proc/stat
    property var _cpuPrev: null
    Process {
        id: cpuStatProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).slice(1).map(Number)
                const idle  = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)
                if (root._cpuPrev) {
                    const dTotal = total - root._cpuPrev.total
                    const dIdle  = idle  - root._cpuPrev.idle
                    root.cpuUsage = dTotal > 0 ? Math.round((1 - dIdle / dTotal) * 100) : 0
                }
                root._cpuPrev = { total, idle }
            }
        }
    }

    // CPU temp (k10temp Tctl)
    Process {
        id: cpuTempProc
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon5/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTemp = Math.round(parseInt(text.trim()) / 1000)
        }
    }

    // GPU temp (amdgpu edge)
    Process {
        id: gpuTempProc
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon4/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: root.gpuTemp = Math.round(parseInt(text.trim()) / 1000)
        }
    }

    // GPU usage
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
            "free -b | awk '/^Mem:/ {used=$2-$7; pct=int(used/$2*100); printf \"%s / %s %d\", int(used/1073741824*10)/10\"G\", int($2/1073741824*10)/10\"G\", pct}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const pct = parseInt(parts[parts.length - 1])
                root.ramUsage = isNaN(pct) ? 0 : pct
                root.ramText  = parts.slice(0, parts.length - 1).join(" ")
            }
        }
    }

    // Disk
    Process {
        id: diskProc
        command: ["sh", "-c",
            "df / | awk 'NR==2 {used=$3; total=$2; pct=int(used/total*100); printf \"%s / %s %d\", int(used/1048576*10)/10\"G\", int(total/1048576*10)/10\"G\", pct}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const pct = parseInt(parts[parts.length - 1])
                root.diskUsage = isNaN(pct) ? 0 : pct
                root.diskText  = parts.slice(0, parts.length - 1).join(" ")
            }
        }
    }

    // Tick tiap 2 detik
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            cpuStatProc.running  = true
            cpuTempProc.running  = true
            gpuTempProc.running  = true
            gpuUsageProc.running = true
            ramProc.running      = true
            diskProc.running     = true
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ── Profile card ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Avatar
                Item {
                    width: 60; height: 60

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Root.Colors.surface0
                        border.color: Root.Colors.lavender
                        border.width: 2
                    }

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
                        font.pixelSize: 28
                        color: Root.Colors.subtext
                    }

                    // Hover overlay
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
                            font.pixelSize: 18
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

        // ── Card Stats: CPU · GPU · RAM · Disk ────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: statsCol.implicitHeight + 20
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                id: statsCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                StatRow {
                    label: "CPU"; icon: "󰻠"
                    tempColor: root.cpuTemp > 85 ? Root.Colors.red
                              : root.cpuTemp > 70 ? Root.Colors.yellow
                              : Root.Colors.blue
                    tempText: root.cpuTemp + "°C"
                    pct: root.cpuUsage
                }
                StatRow {
                    label: "GPU"; icon: "󰾲"
                    accent: Root.Colors.mauve
                    tempColor: root.gpuTemp > 75 ? Root.Colors.red
                              : root.gpuTemp > 60 ? Root.Colors.yellow
                              : Root.Colors.mauve
                    tempText: root.gpuTemp + "°C"
                    pct: root.gpuUsage
                }
                StatRow {
                    label: "RAM"; icon: "󰍛"
                    accent: Root.Colors.green
                    tempColor: root.ramUsage > 85 ? Root.Colors.red
                              : root.ramUsage > 65 ? Root.Colors.yellow
                              : Root.Colors.green
                    pct: root.ramUsage
                    subText: root.ramText
                }
                StatRow {
                    label: "Disk"; icon: "󰋊"
                    accent: Root.Colors.yellow
                    tempColor: root.diskUsage > 90 ? Root.Colors.red
                              : root.diskUsage > 75 ? Root.Colors.peach
                              : Root.Colors.yellow
                    pct: root.diskUsage
                    subText: root.diskText
                }
            }
        }

        // ── Weather card — data dari WeatherService (always-on singleton) ─
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 130
            radius: 14
            color: Root.Colors.base
            clip: true
            Behavior on color { ColorAnimation { duration: 200 } }

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
                        // Loading indicator
                        Text {
                            visible: Root.WeatherService.loading
                            text: "memuat…"
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                        }
                        Text {
                            visible: !Root.WeatherService.loading
                            text: Root.WeatherService.city
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
                            text: Root.WeatherService.icon
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 36
                            color: Root.Colors.peach
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: Root.WeatherService.hasData ? Root.WeatherService.temp + "°C" : "—"
                                font.pixelSize: 30
                                font.weight: Font.Bold
                                color: Root.Colors.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Text {
                                text: Root.WeatherService.desc
                                font.pixelSize: 13
                                color: Root.Colors.subtext
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Terasa " + (Root.WeatherService.hasData ? Root.WeatherService.feels + "°C" : "—")
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: "󰖌 " + (Root.WeatherService.hasData ? Root.WeatherService.humidity + "%" : "—")
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: "󰞄 " + (Root.WeatherService.hasData ? Root.WeatherService.wind + " km/h" : "—")
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }

                    // Last updated
                    Text {
                        visible: Root.WeatherService.updated !== ""
                        text: "Diperbarui: " + Root.WeatherService.updated
                        font.pixelSize: 10
                        color: Root.Colors.surface2
                    }

                    // Garis pemisah
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Colors.surface1
                        visible: Root.WeatherService.forecast.length > 0
                    }

                    // 3-hari forecast
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: Root.WeatherService.forecast.length > 0

                        Repeater {
                            model: Root.WeatherService.forecast

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                height: forecastCol.implicitHeight + 14
                                radius: 10
                                color: index === 0 ? Root.Colors.surface0 : "transparent"
                                Behavior on color { ColorAnimation { duration: 200 } }

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

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.dayName
                                        font.pixelSize: 11
                                        font.weight: index === 0 ? Font.SemiBold : Font.Normal
                                        color: index === 0 ? Root.Colors.peach : Root.Colors.subtext
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 24
                                        color: Root.Colors.text
                                    }
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

        Item { Layout.preferredHeight: 0 }
    }
}
