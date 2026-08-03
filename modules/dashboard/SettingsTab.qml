import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../" as Root

ColumnLayout {
    id: root
    spacing: 10

    // ── Audio sink aktif ──────────────────────────────────────────────────
    property var defaultSink: Pipewire.defaultAudioSink
    property var btSink: {
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isSink || n.isStream) continue
            const pr = n.properties || {}
            if (pr["device.api"] === "bluez5" || (n.name || "").startsWith("bluez_output."))
                return n
        }
        void Pipewire.defaultAudioSink
        return null
    }
    property var activeSink: (btSink && defaultSink && btSink.id === defaultSink.id)
                             ? btSink : defaultSink

    // Daftar semua hardware sink (untuk selector)
    property var sinkList: {
        const list = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (n && n.isSink && !n.isStream && n.audio) list.push(n)
        }
        void Pipewire.defaultAudioSink
        return list
    }

    property bool sinkSelectorOpen: false

    PwObjectTracker {
        objects: {
            const arr = []
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && n.isSink && !n.isStream && n.audio) arr.push(n)
            }
            if (root.defaultSink) arr.push(root.defaultSink)
            return arr
        }
    }

    // ── Sound ─────────────────────────────────────────────────────────────
    SectionLabel { text: "Sound" }

    SliderRow {
        Layout.fillWidth: true
        icon: {
            if (!root.activeSink?.audio || root.activeSink.audio.muted) return "󰸈"
            const pct = Math.round((root.activeSink.audio.volume ?? 0) * 100)
            return pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
        }
        value: root.activeSink?.audio ? (root.activeSink.audio.volume ?? 0) : 0
        onMoved: v => { if (root.activeSink?.audio) root.activeSink.audio.volume = v }
    }

    // Slider BT terpisah — hanya muncul kalau BT bukan default sink
    SliderRow {
        Layout.fillWidth: true
        visible: root.btSink != null && root.btSink.id !== (root.defaultSink?.id ?? -1)
        icon: "󰋋"
        value: root.btSink?.audio ? (root.btSink.audio.volume ?? 0) : 0
        onMoved: v => { if (root.btSink?.audio) root.btSink.audio.volume = v }
    }

    // ── Sink selector ─────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 36
        radius: 10
        visible: root.sinkList.length >= 1
        color: trigMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: {
                    const nm = (root.defaultSink?.nickname
                             || root.defaultSink?.description
                             || root.defaultSink?.name || "").toLowerCase()
                    if (nm.includes("bluetooth") || nm.includes("a2dp")) return "󰋋"
                    if (nm.includes("hdmi")) return "󰍹"
                    return "󰓃"
                }
                font.pixelSize: 14
                color: Root.Colors.blue
            }

            Text {
                Layout.fillWidth: true
                text: root.defaultSink?.nickname
                   || root.defaultSink?.description
                   || root.defaultSink?.name
                   || "No output"
                font.pixelSize: 12
                color: Root.Colors.text
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: root.sinkSelectorOpen ? "󰅃" : "󰅀"
                font.pixelSize: 12
                color: Root.Colors.subtext
            }
        }

        MouseArea {
            id: trigMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sinkSelectorOpen = !root.sinkSelectorOpen
        }
    }

    // Dropdown sink list
    Rectangle {
        Layout.fillWidth: true
        height: root.sinkSelectorOpen ? root.sinkList.length * 38 + 8 : 0
        visible: height > 0
        clip: true
        radius: 10
        color: Root.Colors.base
        border.color: Root.Colors.surface1
        border.width: 1
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            Repeater {
                model: root.sinkList

                delegate: Rectangle {
                    id: sinkRow

                    required property var modelData
                    required property int index

                    property bool isActive: root.defaultSink
                                         && modelData.id === root.defaultSink.id

                    width: parent.width
                    height: 34
                    radius: 7
                    color: isActive
                        ? Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.18)
                        : (rowMa.containsMouse ? Root.Colors.surface0 : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: {
                                const nm = (sinkRow.modelData.nickname
                                         || sinkRow.modelData.description
                                         || sinkRow.modelData.name || "").toLowerCase()
                                if (nm.includes("bluetooth") || nm.includes("a2dp")) return "󰋋"
                                if (nm.includes("hdmi")) return "󰍹"
                                return "󰓃"
                            }
                            font.pixelSize: 14
                            color: sinkRow.isActive ? Root.Colors.blue : Root.Colors.subtext
                        }

                        Text {
                            Layout.fillWidth: true
                            text: sinkRow.modelData.nickname
                               || sinkRow.modelData.description
                               || sinkRow.modelData.name
                               || "Unknown"
                            font.pixelSize: 12
                            font.bold: sinkRow.isActive
                            color: sinkRow.isActive ? Root.Colors.blue : Root.Colors.text
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: sinkRow.isActive
                            text: "󰄬"
                            font.pixelSize: 12
                            color: Root.Colors.blue
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                            root.sinkSelectorOpen = false
                        }
                    }
                }
            }
        }
    }

    // ── Display ───────────────────────────────────────────────────────────
    SectionLabel { text: "Display" }

    SliderRow {
        Layout.fillWidth: true
        icon: "󰃞"
        onMoved: v => {
            setBright.command = ["brightnessctl", "set", Math.round(v * 100) + "%"]
            setBright.running = true
        }

        Process { id: setBright }
    }

    // ── Theme ─────────────────────────────────────────────────────────────
    SectionLabel { text: "Theme" }

    ThemeSelector { Layout.fillWidth: true }

    Item { height: 2 }

    // ── Section label helper ──────────────────────────────────────────────
    component SectionLabel: Text {
        Layout.fillWidth: true
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 0.6
        color: Root.Colors.subtext
        opacity: 0.75
        leftPadding: 2
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
