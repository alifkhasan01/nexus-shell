import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../" as Root

// Panel volume dua-tab (inspirasi KDE plasma-pa):
//   Tab "Perangkat" : semua output + input hardware, radio pilih default
//   Tab "Aplikasi"  : per-app audio streams
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-volume"
    WlrLayershell.exclusiveZone: 0

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

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
        void Pipewire.defaultAudioSink
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
        void Pipewire.defaultAudioSource
        return list
    }

    // Per-app output streams (sink-input: isStream + isSink)
    // Tidak pakai computed property reaktif supaya tidak timbul binding loop
    // saat node masuk/keluar registry (contoh: wf-recorder mulai/berhenti).
    // List di-refresh via onNodesChanged saja.
    property var appOutputStreams: []
    property var appInputStreams: []

    function _refreshAppStreams() {
        const outList = []
        const inList  = []
        const nodes   = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isStream) continue
            // Filter: jangan tampilkan monitor/loopback/virtual (biasanya nama mengandung "monitor")
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

    // Track hardware devices — pisah dari stream agar tidak loop
    // saat recorder masuk/keluar registry.
    PwObjectTracker {
        objects: {
            const tracked = []
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                // Track hanya hardware nodes (bukan stream) agar tidak
                // memicu re-bind setiap kali wf-recorder/OBS start/stop
                if (n && n.audio && !n.isStream) tracked.push(n)
            }
            if (root.defaultSink)   tracked.push(root.defaultSink)
            if (root.defaultSource) tracked.push(root.defaultSource)
            return tracked
        }
    }

    // Track stream nodes secara terpisah — re-bind lebih terisolasi
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

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 420
        implicitHeight: Math.max(tabContent.implicitHeight + tabBar.height + 24 + 16, 80)
        height: implicitHeight
        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi ────────────────────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -50 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                NumberAnimation { target: cardTranslate; property: "y"; duration: 220; easing.type: Easing.OutCubic }
                OpacityAnimator { target: card; duration: 200; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: 160; easing.type: Easing.InCubic }
                        OpacityAnimator { target: card; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Blokir klik di dalam kartu
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.bottomMargin: 12
            spacing: 0

            // ── Header + Tab bar ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 10
                spacing: 0

                Text {
                    text: "󰕾  Volume"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Tab bar kecil di pojok kanan header
                Rectangle {
                    id: tabBar
                    width: tabRow.implicitWidth + 6
                    height: 28
                    radius: 8
                    color: Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: ["Perangkat", "Aplikasi"]

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: tabLbl.implicitWidth + 16
                                height: 22
                                radius: 6
                                color: root.currentTab === index
                                    ? Root.Colors.surface2
                                    : (tabMa.containsMouse ? Root.Colors.surface1 : "transparent")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: tabLbl
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
            }

            // ── Konten tab ─────────────────────────────────────────────────
            Item {
                id: tabContent
                Layout.fillWidth: true
                implicitHeight: root.currentTab === 0 ? devicesCol.implicitHeight : appsCol.implicitHeight

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // ── TAB 0: PERANGKAT ──────────────────────────────────────
                ColumnLayout {
                    id: devicesCol
                    width: parent.width
                    spacing: 2
                    opacity: root.currentTab === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // ── Output devices ────────────────────────────────────
                    SectionLabel {
                        text: "OUTPUT"
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 2
                    }

                    Repeater {
                        model: root.outputDevices
                        delegate: DeviceRow {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8

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

                    // placeholder kalau tidak ada output
                    Text {
                        visible: root.outputDevices.length === 0
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        text: "Tidak ada perangkat output"
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 4; bottomPadding: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ── Divider ───────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        height: 1
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ── Input devices ─────────────────────────────────────
                    SectionLabel {
                        text: "INPUT"
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                    }

                    Repeater {
                        model: root.inputDevices
                        delegate: DeviceRow {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8

                            node: modelData
                            isDefault: root.defaultSource && modelData.id === root.defaultSource.id
                            showRadio: root.inputDevices.length > 1
                            onSetDefault: Pipewire.preferredDefaultAudioSource = modelData
                            deviceIcon: "󰍬"
                        }
                    }

                    // placeholder kalau tidak ada input
                    Text {
                        visible: root.inputDevices.length === 0
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        text: "Tidak ada perangkat input"
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 4; bottomPadding: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { Layout.preferredHeight: 2 }
                }

                // ── TAB 1: APLIKASI ───────────────────────────────────────
                ColumnLayout {
                    id: appsCol
                    width: parent.width
                    spacing: 2
                    opacity: root.currentTab === 1 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // ── App output streams ────────────────────────────────
                    SectionLabel {
                        text: "MEMUTAR AUDIO"
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 2
                        visible: root.appOutputStreams.length > 0 || root.appInputStreams.length === 0
                    }

                    Repeater {
                        model: root.appOutputStreams
                        delegate: AppStreamRow {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            node: modelData
                        }
                    }

                    Text {
                        visible: root.appOutputStreams.length === 0 && root.appInputStreams.length === 0
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        text: "Tidak ada aplikasi yang memutar audio"
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ── Divider ───────────────────────────────────────────
                    Rectangle {
                        visible: root.appInputStreams.length > 0
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        height: 1
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ── App input streams (recording) ─────────────────────
                    SectionLabel {
                        text: "MEREKAM AUDIO"
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        visible: root.appInputStreams.length > 0
                    }

                    Repeater {
                        model: root.appInputStreams
                        delegate: AppStreamRow {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            node: modelData
                        }
                    }

                    Item { Layout.preferredHeight: 2 }
                }
            }
        }
    }

    // ── Component: SectionLabel ────────────────────────────────────────────
    component SectionLabel: Text {
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 0.8
        color: Root.Colors.subtext
        opacity: 0.7
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Component: DeviceRow ───────────────────────────────────────────────
    // Satu baris device hardware: [radio/spacer] [icon] [nama + slider] [persen]
    component DeviceRow: Rectangle {
        id: devRow

        property var node: null
        property bool isDefault: false
        property bool showRadio: true
        property string deviceIcon: "󰓃"
        signal setDefault()

        implicitHeight: devLayout.implicitHeight + 12
        radius: 10
        color: devHover.hovered ? Root.Colors.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        readonly property bool muted: node?.audio ? node.audio.muted : false
        readonly property real volume: node?.audio ? (node.audio.volume ?? 0) : 0

        RowLayout {
            id: devLayout
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 8; rightMargin: 8
            }
            spacing: 8

            // Radio button — pilih sebagai default
            Rectangle {
                width: 18
                height: 18
                radius: 9
                visible: devRow.showRadio
                color: "transparent"
                border.width: 2
                border.color: devRow.isDefault ? Root.Colors.blue : Root.Colors.overlay0
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
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

            // Spacer sebagai pengganti radio kalau cuma 1 device
            Item {
                width: 18
                height: 18
                visible: !devRow.showRadio
            }

            // Tombol mute + ikon
            Rectangle {
                width: 30
                height: 30
                radius: 8
                color: devRow.muted
                    ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                    : (muteBtnMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1)
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: devRow.muted ? "󰝟" : devRow.deviceIcon
                    font.pixelSize: 15
                    color: devRow.muted ? Root.Colors.red : Root.Colors.blue
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: muteBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (devRow.node?.audio) devRow.node.audio.muted = !devRow.node.audio.muted }
                }
            }

            // Nama + slider dalam kolom
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Nama device — klik untuk set default
                Text {
                    Layout.fillWidth: true
                    text: devRow.node?.nickname || devRow.node?.description || devRow.node?.name || "Device"
                    font.pixelSize: 12
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

                // Slider volume
                VolumeSlider {
                    Layout.fillWidth: true
                    node: devRow.node
                    muted: devRow.muted
                    currentVolume: devRow.volume
                }
            }

            // Persen
            Text {
                text: Math.round(devRow.volume * 100) + "%"
                font.pixelSize: 11
                color: Root.Colors.subtext
                Layout.minimumWidth: 34
                horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        HoverHandler { id: devHover; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!devRow.node?.audio) return
                const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                devRow.node.audio.volume = Math.max(0, Math.min(1, devRow.volume + delta))
            }
        }
    }

    // ── Component: AppStreamRow ────────────────────────────────────────────
    // Baris per-app stream: [mute] [nama app] [slider] [persen]
    component AppStreamRow: Rectangle {
        id: appRow

        property var node: null

        implicitHeight: appLayout.implicitHeight + 12
        radius: 10
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
            id: appLayout
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 8; rightMargin: 8
            }
            spacing: 8

            // Spacer sejajar dengan radio di DeviceRow
            Item { width: 18; height: 1 }

            // Tombol mute + ikon app
            Rectangle {
                width: 30
                height: 30
                radius: 8
                color: appRow.muted
                    ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                    : (appMuteMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1)
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: appRow.muted ? "󰝟" : appRow.appIcon
                    font.pixelSize: 14
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

            // Nama + slider
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: appRow.appName
                    font.pixelSize: 12
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

            // Persen
            Text {
                text: Math.round(appRow.volume * 100) + "%"
                font.pixelSize: 11
                color: Root.Colors.subtext
                Layout.minimumWidth: 34
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

        implicitHeight: 18
        from: 0
        to: 1

        property bool dragging: false
        value: dragging ? volSlider.value : currentVolume

        onMoved: {
            if (node?.audio) node.audio.volume = value
        }
        onPressedChanged: {
            dragging = pressed
            if (!pressed && node?.audio) node.audio.volume = value
        }

        background: Rectangle {
            x: volSlider.leftPadding
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            width: volSlider.availableWidth
            height: 5
            radius: 3
            color: Root.Colors.surface1

            Rectangle {
                width: volSlider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: volSlider.muted ? Root.Colors.red : Root.Colors.blue
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        handle: Rectangle {
            x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: Root.Colors.text
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
