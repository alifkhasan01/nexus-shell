import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../" as Root

// Tab Volume di Dashboard — dua-tab (inspirasi KDE plasma-pa):
//   Tab "Perangkat" : semua output + input hardware, radio pilih default
//   Tab "Aplikasi"  : per-app audio streams
// Content dipindah dari panels/VolumePanel.qml (PanelWindow → tab).

Item {
    id: root

    // ── Pipewire data ──────────────────────────────────────────────────────
    property var defaultSink:   Pipewire.defaultAudioSink
    property var defaultSource: Pipewire.defaultAudioSource

    // Semua hardware output sink
    property var outputDevices: {
        const list = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (n && n.audio && n.isSink && !n.isStream) list.push(n)
        }
        // Reaktif terhadap perubahan node (Bluetooth masuk/keluar)
        void Pipewire.nodes.values
        void Pipewire.defaultAudioSink
        // Default di atas
        list.sort((a, b) => {
            const aDefault = root.defaultSink && a.id === root.defaultSink.id
            const bDefault = root.defaultSink && b.id === root.defaultSink.id
            if (aDefault !== bDefault) return aDefault ? -1 : 1
            return (a.description || a.name || "").localeCompare(b.description || b.name || "")
        })
        return list
    }

    // Semua hardware input source
    property var inputDevices: {
        const list = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (n && n.audio && !n.isSink && !n.isStream) list.push(n)
        }
        void Pipewire.nodes.values
        void Pipewire.defaultAudioSource
        list.sort((a, b) => {
            const aDefault = root.defaultSource && a.id === root.defaultSource.id
            const bDefault = root.defaultSource && b.id === root.defaultSource.id
            if (aDefault !== bDefault) return aDefault ? -1 : 1
            return (a.description || a.name || "").localeCompare(b.description || b.name || "")
        })
        return list
    }

    // Per-app output streams (sink-input: isStream + isSink)
    property var appOutputStreams: []
    property var appInputStreams: []

    function _refreshAppStreams() {
        const outList = []
        const inList  = []
        const nodes   = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isStream) continue
            const nm = (n.name || "").toLowerCase()
            if (nm.includes("monitor") || nm.includes("loopback")) continue
            if (n.isSink) outList.push(n)
            else           inList.push(n)
        }
        appOutputStreams = outList
        appInputStreams  = inList
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root._refreshAppStreams() }
    }

    Component.onCompleted: root._refreshAppStreams()

    PwObjectTracker {
        objects: {
            const tracked = []
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && n.audio && !n.isStream) tracked.push(n)
            }
            if (root.defaultSink)   tracked.push(root.defaultSink)
            if (root.defaultSource) tracked.push(root.defaultSource)
            void Pipewire.nodes.values
            return tracked
        }
    }

    PwObjectTracker {
        objects: {
            const tracked = []
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && n.audio && n.isStream) tracked.push(n)
            }
            return tracked
        }
    }

    // ── Tab state ──────────────────────────────────────────────────────────
    property int currentTab: 0  // 0 = Perangkat, 1 = Aplikasi

    // ── Konten ─────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab bar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "transparent"

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: ["Perangkat", "Aplikasi"]

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        width: 90
                        height: 28
                        radius: 7
                        color: root.currentTab === index
                            ? Root.Colors.surface1
                            : (tabMa.containsMouse ? Root.Colors.surface0 : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: root.currentTab === index
                            color: root.currentTab === index ? Root.Colors.text : Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }
        }

        // ── Konten tab scrollable ──────────────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentCol
                width: parent.width
                spacing: 0

                // ── TAB 0: PERANGKAT ──────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 2
                    visible: root.currentTab === 0
                    opacity: root.currentTab === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Item { width: 1; height: 4 }

                    // ── Output devices ────────────────────────────────────
                    SectionLabel {
                        text: "OUTPUT"
                        leftPadding: 10
                    }

                    Repeater {
                        model: root.outputDevices
                        delegate: DeviceRow {
                            required property var modelData
                            required property int index

                            width: parent.width
                            node: modelData
                            isDefault: root.defaultSink && modelData.id === root.defaultSink.id
                            showRadio: root.outputDevices.length > 1
                            onSetDefault: Pipewire.preferredDefaultAudioSink = modelData
                            deviceIcon: {
                                const nm = (modelData.nickname || modelData.description || modelData.name || "").toLowerCase()
                                const props = modelData.properties || {}
                                if (nm.includes("bluetooth") || nm.includes("a2dp") || props["device.api"] === "bluez5") return "󰋋"
                                if (nm.includes("hdmi")) return "󰍹"
                                if (nm.includes("usb")) return "󰻇"
                                return "󰓃"
                            }
                        }
                    }

                    Text {
                        visible: root.outputDevices.length === 0
                        width: parent.width
                        text: "Tidak ada perangkat output"
                        font.pixelSize: 10
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 6; bottomPadding: 6
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { width: 1; height: 4 }

                    Rectangle {
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 1
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { width: 1; height: 4 }

                    // ── Input devices ─────────────────────────────────────
                    SectionLabel {
                        text: "INPUT"
                        leftPadding: 10
                    }

                    Repeater {
                        model: root.inputDevices
                        delegate: DeviceRow {
                            required property var modelData
                            required property int index

                            width: parent.width
                            node: modelData
                            isDefault: root.defaultSource && modelData.id === root.defaultSource.id
                            showRadio: root.inputDevices.length > 1
                            onSetDefault: Pipewire.preferredDefaultAudioSource = modelData
                            deviceIcon: "󰍬"
                        }
                    }

                    Text {
                        visible: root.inputDevices.length === 0
                        width: parent.width
                        text: "Tidak ada perangkat input"
                        font.pixelSize: 10
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 6; bottomPadding: 6
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { width: 1; height: 8 }
                }

                // ── TAB 1: APLIKASI ───────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 2
                    visible: root.currentTab === 1
                    opacity: root.currentTab === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Item { width: 1; height: 4 }

                    // ── App output streams ────────────────────────────────
                    SectionLabel {
                        text: "MEMUTAR AUDIO"
                        leftPadding: 10
                        visible: root.appOutputStreams.length > 0 || root.appInputStreams.length === 0
                    }

                    Repeater {
                        model: root.appOutputStreams
                        delegate: AppStreamRow {
                            required property var modelData
                            required property int index

                            width: parent.width
                            node: modelData
                        }
                    }

                    Text {
                        visible: root.appOutputStreams.length === 0 && root.appInputStreams.length === 0
                        width: parent.width
                        text: "Tidak ada aplikasi yang memutar audio"
                        font.pixelSize: 10
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 10; bottomPadding: 10
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { 
                        width: 1
                        height: 4
                        visible: root.appInputStreams.length > 0
                    }

                    Rectangle {
                        visible: root.appInputStreams.length > 0
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 1
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { 
                        width: 1
                        height: 4
                        visible: root.appInputStreams.length > 0
                    }

                    // ── App input streams (recording) ─────────────────────
                    SectionLabel {
                        text: "MEREKAM AUDIO"
                        leftPadding: 10
                        visible: root.appInputStreams.length > 0
                    }

                    Repeater {
                        model: root.appInputStreams
                        delegate: AppStreamRow {
                            required property var modelData
                            required property int index

                            width: parent.width
                            node: modelData
                        }
                    }

                    Item { width: 1; height: 8 }
                }
            }
        }
    }

    // ── Process pool untuk wpctl ──────────────────────────────────────────
    Process {
        id: wpctlVolProc
        running: false
    }
    Process {
        id: wpctlMuteProc
        running: false
    }

    function deviceSetVolume(nodeId, value) {
        wpctlVolProc.command = ["wpctl", "set-volume", String(nodeId), value.toFixed(3)]
        wpctlVolProc.running = true
    }

    function deviceSetMute(nodeId, muted) {
        wpctlMuteProc.command = ["wpctl", "set-mute", String(nodeId), muted ? "1" : "0"]
        wpctlMuteProc.running = true
    }

    // ── Component: SectionLabel ────────────────────────────────────────────
    component SectionLabel: Text {
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 0.6
        color: Root.Colors.subtext
        opacity: 0.7
        topPadding: 2
        bottomPadding: 2
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Component: DeviceRow ───────────────────────────────────────────────
    component DeviceRow: Rectangle {
        id: devRow

        property var node: null
        property bool isDefault: false
        property bool showRadio: true
        property string deviceIcon: "󰓃"
        signal setDefault()

        implicitHeight: 56
        color: devHover.hovered ? Root.Colors.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        readonly property bool muted: node?.audio ? node.audio.muted : false
        readonly property real volume: node?.audio ? (node.audio.volume ?? 0) : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6

            // Radio button
            Rectangle {
                width: 16
                height: 16
                radius: 8
                visible: devRow.showRadio
                color: "transparent"
                border.width: 2
                border.color: devRow.isDefault ? Root.Colors.blue : Root.Colors.overlay0
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Root.Colors.blue
                    opacity: devRow.isDefault ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: devRow.setDefault()
                }
            }

            Item {
                width: 16
                height: 16
                visible: !devRow.showRadio
            }

            // Tombol mute
            Rectangle {
                width: 28
                height: 28
                radius: 7
                color: devRow.muted
                    ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                    : (muteBtnMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1)
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: devRow.muted ? "󰝟" : devRow.deviceIcon
                    font.pixelSize: 14
                    color: devRow.muted ? Root.Colors.red : Root.Colors.blue
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: muteBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!devRow.node) return
                        root.deviceSetMute(devRow.node.id, !devRow.muted)
                    }
                }
            }

            // Nama + slider
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: devRow.node?.nickname || devRow.node?.description || devRow.node?.name || "Device"
                    font.pixelSize: 11
                    font.bold: devRow.isDefault
                    color: devRow.isDefault ? Root.Colors.text : Root.Colors.subtext
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: devRow.showRadio ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (devRow.showRadio) devRow.setDefault()
                    }
                }

                VolumeSlider {
                    Layout.fillWidth: true
                    node: devRow.node
                    muted: devRow.muted
                    currentVolume: devRow.volume
                    onCommitVolume: v => root.deviceSetVolume(devRow.node.id, v)
                }
            }

            // Persen
            Text {
                text: Math.round(devRow.volume * 100) + "%"
                font.pixelSize: 10
                color: Root.Colors.subtext
                Layout.minimumWidth: 32
                horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        HoverHandler { id: devHover; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!devRow.node) return
                const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                const newVol = Math.max(0, Math.min(1, devRow.volume + delta))
                root.deviceSetVolume(devRow.node.id, newVol)
            }
        }
    }

    // ── Component: AppStreamRow ────────────────────────────────────────────
    component AppStreamRow: Rectangle {
        id: appRow

        property var node: null

        implicitHeight: 56
        color: appHover.hovered ? Root.Colors.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        readonly property bool muted: node?.audio ? node.audio.muted : false
        readonly property real volume: node?.audio ? (node.audio.volume ?? 0) : 0
        readonly property string appName: {
            const props = node?.properties || {}
            return props["application.name"]
                || props["media.name"]
                || node?.nickname
                || node?.description
                || node?.name
                || "Aplikasi"
        }
        readonly property string appIcon: {
            if (!node) return "󰝟"
            const props = node.properties || {}
            const name = (props["application.name"] || node.name || "").toLowerCase()
            if (name.includes("firefox")) return "󰈹"
            if (name.includes("chrome") || name.includes("chromium")) return ""
            if (name.includes("spotify")) return "󰓇"
            if (name.includes("mpv") || name.includes("vlc")) return "󰐈"
            if (name.includes("discord")) return "󰙯"
            if (name.includes("telegram")) return "󰔁"
            if (appRow.muted || appRow.volume === 0) return "󰕿"
            return appRow.volume < 0.5 ? "󰖀" : "󰕾"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6

            Item { width: 16; height: 1 }

            Rectangle {
                width: 28
                height: 28
                radius: 7
                color: appRow.muted
                    ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                    : (appMuteMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1)
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: appRow.muted ? "󰝟" : appRow.appIcon
                    font.pixelSize: 13
                    color: appRow.muted ? Root.Colors.red : Root.Colors.overlay2
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: appMuteMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (appRow.node?.audio) appRow.node.audio.muted = !appRow.node.audio.muted }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: appRow.appName
                    font.pixelSize: 11
                    color: Root.Colors.text
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                VolumeSlider {
                    Layout.fillWidth: true
                    node: appRow.node
                    muted: appRow.muted
                    currentVolume: appRow.volume
                }
            }

            Text {
                text: Math.round(appRow.volume * 100) + "%"
                font.pixelSize: 10
                color: Root.Colors.subtext
                Layout.minimumWidth: 32
                horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        HoverHandler { id: appHover; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!appRow.node?.audio) return
                const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                appRow.node.audio.volume = Math.max(0, Math.min(1, appRow.volume + delta))
            }
        }
    }

    // ── Component: VolumeSlider ────────────────────────────────────────────
    component VolumeSlider: Slider {
        id: volSlider

        property var node: null
        property bool muted: false
        property real currentVolume: 0
        property var onCommitVolume: null

        implicitHeight: 16
        from: 0
        to: 1

        property bool dragging: false
        value: dragging ? volSlider.value : currentVolume

        function _commit(v) {
            if (typeof onCommitVolume === "function") {
                onCommitVolume(v)
            } else if (node?.audio) {
                node.audio.volume = v
            }
        }

        onMoved: _commit(value)
        onPressedChanged: {
            dragging = pressed
            if (!pressed) _commit(value)
        }

        background: Rectangle {
            x: volSlider.leftPadding
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            width: volSlider.availableWidth
            height: 4
            radius: 2
            color: Root.Colors.surface1

            Rectangle {
                width: volSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: volSlider.muted ? Root.Colors.red : Root.Colors.blue
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        handle: Rectangle {
            x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            width: 12
            height: 12
            radius: 6
            color: Root.Colors.text
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
