import QtQuick
import "../../" as Root

// Kontrol brightness via BrightnessService (satu sumber untuk Bar & Dashboard).
// Service memantau sysfs dengan inotify + fallback polling cepat, jadi setiap
// perubahan (dari hotkey, slider, dll) langsung tercermin di sini.
Item {
    id: root
    implicitWidth: label.implicitWidth
    width: implicitWidth
    height: 20

    // Nilai selalu dari service — instan saat berubah dari luar
    readonly property int percent: Root.BrightnessService.percent

    // ── Label ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: brightMa.containsMouse ? Root.Colors.surface1 : "transparent"
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: Root.Colors.yellow
        font.pixelSize: 14
        text: {
            const p = root.percent
            const icon = p >= 67 ? "󰃠" : (p >= 34 ? "󰃝" : "󰃞")
            return icon + "  " + p + "%"
        }
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
    }

    // Signal ke Bar.qml untuk tampilkan OSD
    signal osdBrightness(real value)

    // ── Scroll untuk ubah brightness ──────────────────────────────────────
    MouseArea {
        id: brightMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            const step = Math.round(Root.BrightnessService.maxBrightness * 0.05)   // 5% dari max
            const dir  = wheel.angleDelta.y > 0 ? 1 : -1
            root._pendingOsd = true

            // Optimistic update via service — UI langsung berubah
            Root.BrightnessService.setRaw(Root.BrightnessService.brightness + dir * step)
        }
    }

    // Kirim OSD setelah percent berubah
    property bool _pendingOsd: false
    onPercentChanged: {
        if (!_pendingOsd) return
        _pendingOsd = false
        osdBrightness(percent / 100)
    }
}
