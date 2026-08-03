import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../" as Root

// Panel volume: system output, output bluetooth, aplikasi per-stream,
// dan mikrofon. Dibuka dengan klik kiri pada ikon volume di Bar.
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }

    color: "transparent"
    visible: showPanel

    // Tetap visible selama animasi tutup belum selesai
    property bool showPanel: false
    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-volume"
    WlrLayershell.exclusiveZone: 0

    // Klik di luar kartu untuk menutup
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── Sink / source aktif ────────────────────────────────────────────────
    property var _defaultSink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    // Bluetooth sink (hardware, bukan stream)
    property var btSink: {
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isSink || n.isStream) continue
            const props = n.properties || {}
            if (props["device.api"] === "bluez5" ||
                (n.name || "").startsWith("bluez_output."))
                return n
        }
        void Pipewire.defaultAudioSink
        return null
    }

    // Sink aktif yang dikontrol slider SYSTEM:
    // kalau BT sink ada dan sedang jadi default, pakai itu
    property var sink: {
        if (btSink && _defaultSink && btSink.id === _defaultSink.id)
            return btSink
        return _defaultSink
    }

    // Stream aplikasi (musik/video/diskusi, dst)
    // Tidak pakai computed property supaya tidak timbul binding loop saat
    // node PipeWire masuk/keluar registry (misal saat wf-recorder jalan).
    // Filter dilakukan langsung di delegate Repeater.

    Component.onCompleted: {
        console.log("VP sink=" + (root.sink ? root.sink.name : "null")
            + " bt=" + (root.btSink ? root.btSink.name : "null")
            + " totalnodes=" + (Pipewire.nodes.values ? Pipewire.nodes.values.length : -1))
    }

    // Keep semua hardware sink + source tetap hidup
    PwObjectTracker {
        objects: {
            const tracked = [root.source]
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && n.isSink && !n.isStream && n.audio)
                    tracked.push(n)
            }
            return tracked
        }
    }

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 460
        implicitHeight: contentCol.implicitHeight + 28
        height: implicitHeight
        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi muncul / hilang ────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -20 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                NumberAnimation {
                    target: cardTranslate; property: "y"
                    duration: 220; easing.type: Easing.OutCubic
                }
                OpacityAnimator {
                    target: card
                    duration: 200; easing.type: Easing.OutCubic
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: cardTranslate; property: "y"
                            duration: 160; easing.type: Easing.InCubic
                        }
                        OpacityAnimator {
                            target: card
                            duration: 150; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Block klik di dalam kartu
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 12
            spacing: 8

            // ── Header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2

                Text {
                    text: "󰕾  Volume"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Sink aktif
                Text {
                    text: root.sink
                          ? (root.sink.nickname || root.sink.description || root.sink.name || "Output")
                          : "Tidak ada output"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // ── System output ──────────────────────────────────────────────
            SectionLabel { text: "SYSTEM" }

            VolumeRow {
                node: root.sink
                iconText: {
                    if (!root.sink?.audio || root.sink.audio.muted) return "󰸈"
                    const pct = Math.round((root.sink.audio.volume ?? 0) * 100)
                    return pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
                }
                labelText: root.sink?.nickname || root.sink?.description ||
                           root.sink?.name || "System"
            }

            // ── Output Bluetooth ───────────────────────────────────────────
            // Muncul hanya kalau BT sink ada tapi bukan default sink
            // (sehingga tidak duplikat dengan slider SYSTEM di atas)
            VolumeRow {
                visible: root.btSink != null && root.btSink.id !== (root._defaultSink?.id ?? -1)
                node: root.btSink
                iconText: "󰋋"
                labelText: root.btSink?.nickname || root.btSink?.description ||
                           root.btSink?.name || "Bluetooth"
            }

            // ── Aplikasi (per-stream) ──────────────────────────────────────
            // Repeater filter langsung dari Pipewire.nodes tanpa intermediate
            // property supaya tidak ada binding loop saat node masuk/keluar.
            SectionLabel {
                text: "APLIKASI"
                visible: appStreamRepeater.count > 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: appStreamRepeater.count > 0

                Repeater {
                    id: appStreamRepeater
                    model: Pipewire.nodes

                    delegate: VolumeRow {
                        required property var modelData
                        visible: isAppOutputStream(modelData)
                        node: modelData
                        iconText: appIcon(modelData)
                        labelText: streamName(modelData)

                        // Jangan makan layout space kalau invisible
                        Layout.preferredHeight: visible ? 46 : 0
                        implicitHeight: visible ? 46 : 0
                    }
                }
            }

            Text {
                visible: appStreamRepeater.count === 0
                Layout.fillWidth: true
                text: "Tidak ada aplikasi yang memutar audio"
                font.pixelSize: 11
                color: Root.Colors.subtext
                horizontalAlignment: Text.AlignHCenter
                topPadding: 2
                bottomPadding: 2
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ── Mikrofon ──────────────────────────────────────────────────
            SectionLabel { text: "MIKROFON" }

            VolumeRow {
                node: root.source
                iconText: {
                    if (!root.source?.audio || root.source.audio.muted) return "󰍭"
                    return "󰍬"
                }
                labelText: root.source?.nickname || root.source?.description ||
                           root.source?.name || "Mikrofon"
            }
        }
    }

    // ── Helper ───────────────────────────────────────────────────────────
    component SectionLabel: Text {
        Layout.fillWidth: true
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 0.8
        color: Root.Colors.subtext
        opacity: 0.7
        leftPadding: 2
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Baris volume: mute + ikon + nama + slider + persen
    component VolumeRow: Rectangle {
        id: row

        property var node: null
        property string iconText: "󰕾"
        property string labelText: "Unknown"

        Layout.fillWidth: true
        implicitHeight: 46
        radius: 10
        color: rowHover.hovered ? Root.Colors.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        readonly property bool muted:
            row.node?.audio ? row.node.audio.muted : false
        readonly property real volume:
            row.node?.audio ? (row.node.audio.volume ?? 0) : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Tombol mute
            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: row.muted
                       ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.2)
                       : (muteMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface0)
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: row.muted ? "󰝟" : iconText
                    font.pixelSize: 15
                    color: row.muted ? Root.Colors.red : Root.Colors.subtext
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: muteMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.node?.audio)
                            row.node.audio.muted = !row.node.audio.muted
                    }
                }
            }

            // Nama stream/sink
            Text {
                Layout.preferredWidth: 130
                Layout.maximumWidth: 130
                text: row.labelText
                font.pixelSize: 13
                color: Root.Colors.text
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Slider volume
            Slider {
                id: slider
                Layout.fillWidth: true
                from: 0
                to: 1

                // Saat user tidak sedang drag, ikuti nilai dari Pipewire
                // Saat sedang drag, jangan override posisi slider
                property bool dragging: false
                value: dragging ? slider.value : row.volume

                // Tulis ke Pipewire setiap kali user geser slider
                onMoved: {
                    if (row.node?.audio)
                        row.node.audio.volume = value
                }
                onPressedChanged: {
                    dragging = pressed
                    // Commit final saat dilepas
                    if (!pressed && row.node?.audio)
                        row.node.audio.volume = value
                }

                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: parent.availableWidth
                    height: 6
                    radius: 3
                    color: Root.Colors.surface0

                    Rectangle {
                        width: parent.width * (slider.visualPosition)
                        height: parent.height
                        radius: 3
                        color: row.muted ? Root.Colors.red : Root.Colors.blue
                    }
                }

                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: Root.Colors.text
                }
            }

            // Persen
            Text {
                text: Math.round(row.volume * 100) + "%"
                font.pixelSize: 12
                color: Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        // Hover background
        HoverHandler {
            id: rowHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        // Scroll untuk ubah volume
        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!row.node?.audio) return
                const step = 0.05
                const delta = event.angleDelta.y > 0 ? step : -step
                row.node.audio.volume = Math.max(0, Math.min(1, row.volume + delta))
            }
        }
    }

    // ── Helper ikon / nama aplikasi ───────────────────────────────────────
    function isAppOutputStream(n) {
        if (!n || !n.audio) return false
        const props = n.properties || {}
        const mc = props["media.class"] || ""
        const isOutputStream = n.isStream === true || mc === "Stream/Output/Audio"
        if (!isOutputStream) return false
        if (mc !== "" && mc !== "Stream/Output/Audio") return false
        if (props["loopback"] === true || (n.name || "").includes("loopback")) return false
        const name = n.name || ""
        if (name.startsWith("alsa_output.") || name.startsWith("bluez_output.")) return false
        return true
    }

    function appIcon(node) {
        const props = node.properties || {}
        const app = (props["application.name"] ||
                     props["application.process.binary"] ||
                     node.name || "").toLowerCase()
        if (app.includes("spotify"))    return "󰓇"
        if (app.includes("discord"))    return "󰙯"
        if (app.includes("firefox"))    return "󰈹"
        if (app.includes("chrome") || app.includes("chromium")) return "󰊯"
        if (app.includes("thunderbird")) return "󰴢"
        if (app.includes("mpv")   || app.includes("vlc"))       return "󰎆"
        if (app.includes("celluloid") || app.includes("youtube")) return "󰎆"
        return "󰝚"
    }

    function streamName(node) {
        const props = node.properties || {}
        return props["application.name"] ||
               props["node.description"] ||
               props["media.name"] ||
               props["node.name"] ||
               "Aplikasi"
    }
}
