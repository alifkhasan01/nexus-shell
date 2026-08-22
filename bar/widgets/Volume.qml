import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../" as Root

Item {
    id: root
    implicitWidth: row.implicitWidth
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
    property bool muted: sink?.audio ? sink.audio.muted : true

    // ── Microphone source ──────────────────────────────────────────────────
    property var _defaultSource: Pipewire.defaultAudioSource
    property bool micMuted: _defaultSource?.audio ? _defaultSource.audio.muted : false

    // Track sink + hardware sink
    PwObjectTracker {
        objects: {
            const list = [root._defaultSink, root._btSink].filter(n => n != null)
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

    // Track mic source agar micMuted reaktif
    PwObjectTracker {
        objects: root._defaultSource ? [root._defaultSource] : []
    }

    // Proses wpctl
    Process { id: wpctlVol;     running: false }
    Process { id: wpctlMute;    running: false }
    Process { id: wpctlVolHw;   running: false }
    Process { id: wpctlMuteHw;  running: false }
    Process { id: wpctlMicMute; running: false }

    property string _hwSinkId: {
        if (!root.sink) return ""
        const eeName = (root.sink.name || "").toLowerCase()
        if (!eeName.includes("easyeffects")) return ""
        const driverId = (root.sink.properties || {})["node.driver-id"]
        return driverId != null ? String(driverId) : ""
    }

    function _setVolume(v) {
        wpctlVol.command = ["wpctl", "set-volume", "@DEFAULT_SINK@", v.toFixed(3)]
        wpctlVol.running = true
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
    function _toggleMicMute() {
        wpctlMicMute.command = ["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"]
        wpctlMicMute.running = true
    }

    // ── Hover background ───────────────────────────────────────────────────
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

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        // ── Volume label ───────────────────────────────────────────────────
        Text {
            id: label
            color: root.muted ? Root.Colors.red : Root.Colors.blue
            font.pixelSize: 14
            Behavior on color { ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }}
            text: {
                if (root.muted || !root.sink?.audio) return "  Mute"
                const pct = Math.round(root.volume * 100)
                const icon = pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
                return icon + "  " + pct + "%"
            }
        }

        // ── Mic mute indicator — hanya muncul saat mic di-mute ────────────
        Text {
            id: micIndicator
            visible: root.micMuted
            color: Root.Colors.red
            font.pixelSize: 12
            text: "󰍭"
            Behavior on color { ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }}
        }
    }

    // ── Satu MouseArea untuk seluruh widget ───────────────────────────────
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
                // Klik kanan di area micIndicator → toggle mic mute
                // Klik kanan di luar → toggle volume mute
                const localPt = mapToItem(micIndicator, mouse.x, mouse.y)
                if (root.micMuted && micIndicator.contains(localPt)) {
                    root._toggleMicMute()
                } else {
                    root._toggleMute()
                    root.osdVolume(root.volume, !root.muted)
                }
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

    // Signal ke Bar.qml untuk tampilkan OSD
    signal osdVolume(real value, bool muted)

    Timer {
        id: volDebounce
        interval: 60
        repeat: false
        onTriggered: root.osdVolume(root.volume, root.muted)
    }
}
