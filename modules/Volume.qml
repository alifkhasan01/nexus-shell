import QtQuick
import Quickshell.Services.Pipewire
import "../" as Root

Item {
    id: root
    implicitWidth: label.implicitWidth
    width: implicitWidth
    height: 20

    // dikontrol dari Bar.qml
    property bool panelOpen: false
    signal togglePanel()

    // Resolve sink yang benar-benar aktif dipakai:
    // kalau BT sink ada dan sedang jadi defaultAudioSink, pakai itu.
    property var _defaultSink: Pipewire.defaultAudioSink
    property var _btSink: {
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n || !n.audio || !n.isSink || n.isStream) continue
            const props = n.properties || {}
            if (props["device.api"] === "bluez5" ||
                (n.name || "").startsWith("bluez_output."))
                return n
        }
        return null
    }
    property var sink: {
        if (_btSink && _defaultSink && _btSink.id === _defaultSink.id)
            return _btSink
        return _defaultSink
    }

    property real volume: sink?.audio ? sink.audio.volume : 0
    property bool muted:  sink?.audio ? sink.audio.muted  : true

    PwObjectTracker {
        objects: [root._defaultSink, root._btSink].filter(n => n != null)
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.muted ? Root.Colors.subtext
             : root.panelOpen ? Root.Colors.blue
             : Root.Colors.text
        font.pixelSize: 14
        Behavior on color { ColorAnimation { duration: 150 } }
        text: {
            if (root.muted || !root.sink?.audio) return "󰸈"
            const pct = Math.round(root.volume * 100)
            const icon = pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
            return icon + "  " + pct + "%"
        }
    }

    // Signal ke Bar.qml untuk tampilkan OSD
    signal osdVolume(real value, bool muted)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.togglePanel()
            } else if (mouse.button === Qt.RightButton) {
                if (root.sink?.audio) {
                    root.sink.audio.muted = !root.sink.audio.muted
                    root.osdVolume(root.sink.audio.volume, root.sink.audio.muted)
                }
            }
        }

        onWheel: wheel => {
            if (!root.sink?.audio) return
            const step = 0.05
            let v = root.sink.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
            root.sink.audio.volume = Math.max(0, Math.min(1, v))
            volDebounce.restart()
        }
    }

    // Debounce agar OSD tidak update setiap frame saat scroll cepat
    Timer {
        id: volDebounce
        interval: 60
        repeat: false
        onTriggered: root.osdVolume(root.volume, root.muted)
    }
}
