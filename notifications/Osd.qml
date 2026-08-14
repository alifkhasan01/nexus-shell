import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root

// ── OSD overlay untuk Volume & Brightness ────────────────────────────────
// Muncul di bawah bar (top-center), auto-hilang setelah beberapa detik.
PanelWindow {
    id: root

    // ── API publik ────────────────────────────────────────────────────────
    function showVolume(value, muted) {
        osdType  = muted ? "mute" : "volume"
        osdValue = muted ? 0 : Math.max(0, Math.min(1, value))
        _show()
    }

    function showBrightness(value) {
        osdType  = "brightness"
        osdValue = Math.max(0, Math.min(1, value))
        _show()
    }

    // ── State internal ────────────────────────────────────────────────────
    property string osdType:  "volume"
    property real   osdValue: 0

    function _show() {
        // Hentikan animasi keluar kalau sedang berjalan
        exitAnim.stop()
        hideTimer.restart()
        if (!visible) {
            // Baru muncul — fade in dari 0
            card.opacity = 0
            visible = true
            enterAnim.start()
        } else {
            // Sudah visible — langsung full opacity, tidak perlu fade in ulang
            card.opacity = 1
        }
    }

    // ── Window — tepat di bawah bar ───────────────────────────────────────
    // bar height 45 + margin top 8 + gap antar bar-OSD 8 = 61
    anchors { top: true; left: true; right: true }
    margins.top: 5
    implicitWidth:  260
    implicitHeight: 44
    color: "transparent"
    visible: false

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "quickshell-osd"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ── Auto-hide ─────────────────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: exitAnim.start()
    }

    // ── Animasi masuk ─────────────────────────────────────────────────────
    NumberAnimation {
        id: enterAnim
        target: card
        property: "opacity"
        from: 0; to: 1
        duration: 160
        easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter
    }

    // ── Animasi keluar ────────────────────────────────────────────────────
    NumberAnimation {
        id: exitAnim
        target: card
        property: "opacity"
        from: 1; to: 0
        duration: 220
        easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit
        onFinished: root.visible = false
    }

    // ── Kartu OSD ─────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 260
        height: 44
        radius: 12
        color: Root.Colors.mantle
        border.color: Root.Colors.surface1
        border.width: 2
        opacity: 0

        Behavior on color        { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            // ── Ikon ──────────────────────────────────────────────────────
            Text {
                font.pixelSize: 18
                color: {
                    if (root.osdType === "mute")       return Root.Colors.subtext
                    if (root.osdType === "brightness")  return Root.Colors.yellow
                    return Root.Colors.blue
                }
                text: {
                    if (root.osdType === "mute") return ""
                    if (root.osdType === "brightness") {
                        const p = root.osdValue
                        return p >= 0.67 ? "󰃞" : (p >= 0.34 ? "󰃝" : "󰃜")
                    }
                    const p = root.osdValue
                    return p === 0 ? "󰕿" : (p < 0.5 ? "󰖀" : "󰕾")
                }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // ── Progress bar ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: parent.width * root.osdValue
                    height: parent.height
                    radius: parent.radius
                    color: {
                        if (root.osdType === "mute")       return Root.Colors.subtext
                        if (root.osdType === "brightness") return Root.Colors.yellow
                        return Root.Colors.blue
                    }
                    Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.standard } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            // ── Persentase (kanan progress bar) ───────────────────────────
            Text {
                font.pixelSize: 12
                Layout.minimumWidth: 34
                horizontalAlignment: Text.AlignRight
                color: root.osdType === "mute" ? Root.Colors.subtext : Root.Colors.text
                text: root.osdType === "mute"
                      ? "Mute"
                      : Math.round(root.osdValue * 100) + "%"
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
