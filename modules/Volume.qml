import QtQuick
import Quickshell.Services.Pipewire
import "../" as Root

Item {
    id: root
    width: label.width
    height: 20

    property var sink: Pipewire.defaultAudioSink
    property real volume: sink?.audio ? sink.audio.volume : 0
    property bool muted: sink?.audio ? sink.audio.muted : true

    // Wajib supaya properti audio pada sink ter-refresh (lihat dokumentasi Pipewire)
    PwObjectTracker {
        objects: [root.sink]
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.muted ? Root.Colors.subtext : Root.Colors.text
        font.pixelSize: 14
        text: {
            if (root.muted || !root.sink?.audio) return "󰝟  --%"
            const pct = Math.round(root.volume * 100)
            const icon = pct === 0 ? "󰕿" : (pct < 50 ? "󰖀" : "󰕾")
            return icon + "   " + pct + "%"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (!root.sink?.audio) return
            if (mouse.button === Qt.RightButton) {
                root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        onWheel: wheel => {
            if (!root.sink?.audio) return
            const step = 0.05
            let v = root.sink.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
            root.sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }
}
