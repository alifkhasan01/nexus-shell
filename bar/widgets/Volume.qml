import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../" as Root

Item {
    id: root
    implicitWidth: label.implicitWidth
    width: implicitWidth
    height: 20

    // dikontrol dari Bar.qml
    property bool panelOpen: false
    signal togglePanel()

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

    property real volume: {
        // Kalau default sink adalah EasyEffects, tampilkan volume hardware sink
        // supaya persentase di bar mencerminkan volume yang benar-benar terdengar
        if (root._hwSinkId !== "") {
            const nodes = Pipewire.nodes.values
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i]
                if (n && String(n.id) === root._hwSinkId && n.audio)
                    return n.audio.volume
            }
        }
        return sink?.audio ? sink.audio.volume : 0
    }
    property bool muted:  sink?.audio ? sink.audio.muted  : true

    PwObjectTracker {
        objects: {
            const list = [root._defaultSink, root._btSink].filter(n => n != null)
            // Track juga hardware sink supaya root.volume reaktif saat volume berubah
            if (root._hwSinkId !== "") {
                const nodes = Pipewire.nodes.values
                for (let i = 0; i < nodes.length; i++) {
                    const n = nodes[i]
                    if (n && String(n.id) === root._hwSinkId) { list.push(n); break }
                }
            }
            return list
        }
    }

    // Proses wpctl — route lewat @DEFAULT_SINK@ supaya EasyEffects diikutsertakan
    Process {
        id: wpctlVol
        running: false
    }
    Process {
        id: wpctlMute
        running: false
    }
    // Process untuk hardware sink di bawah EasyEffects
    Process {
        id: wpctlVolHw
        running: false
    }
    Process {
        id: wpctlMuteHw
        running: false
    }

    // Detect hardware sink aktif di balik EasyEffects.
    // EasyEffects simpan node.driver-id = ID hardware sink yang sedang di-drive.
    // Ini otomatis update saat user switch output (BT → speaker, dll).
    property string _hwSinkId: {
        if (!root.sink) return ""
        const eeName = (root.sink.name || "").toLowerCase()
        if (!eeName.includes("easyeffects")) return ""
        const driverId = (root.sink.properties || {})["node.driver-id"]
        return driverId != null ? String(driverId) : ""
    }

    function _setVolume(v) {
        // Set ke EasyEffects sink supaya display % di EasyEffects sinkron
        wpctlVol.command = ["wpctl", "set-volume", "@DEFAULT_SINK@", v.toFixed(3)]
        wpctlVol.running = true
        // Set juga ke hardware sink supaya volume benar-benar berubah
        if (root._hwSinkId !== "") {
            wpctlVolHw.command = ["wpctl", "set-volume", root._hwSinkId, v.toFixed(3)]
            wpctlVolHw.running = true
        }
    }
    function _toggleMute() {
        wpctlMute.command = ["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"]
        wpctlMute.running = true
        if (root._hwSinkId !== "") {
            wpctlMuteHw.command = ["wpctl", "set-mute", root._hwSinkId, "toggle"]
            wpctlMuteHw.running = true
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: volMa.containsMouse ? Root.Colors.surface1 : "transparent"
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.muted ? Root.Colors.red
             : root.panelOpen ? Root.Colors.blue
             : Root.Colors.blue
        font.pixelSize: 14
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
        text: {
            if (root.muted || !root.sink?.audio) return "  Mute"
            const pct = Math.round(root.volume * 100)
            const icon = pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
            return icon + "  " + pct + "%"
        }
    }

    // Signal ke Bar.qml untuk tampilkan OSD
    signal osdVolume(real value, bool muted)

    MouseArea {
        id: volMa
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.togglePanel()
            } else if (mouse.button === Qt.RightButton) {
                root._toggleMute()
                root.osdVolume(root.volume, !root.muted)
            }
        }

        onWheel: wheel => {
            if (!root.sink?.audio) return
            const step = 0.05
            let v = root.volume + (wheel.angleDelta.y > 0 ? step : -step)
            v = Math.max(0, Math.min(1, v))
            root._setVolume(v)
            volDebounce.restart()
        }
    }

    Timer {
        id: volDebounce
        interval: 60
        repeat: false
        onTriggered: root.osdVolume(root.volume, root.muted)
    }
}
