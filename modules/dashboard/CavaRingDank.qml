import QtQuick
import Quickshell
import QtQuick.Effects
import "../../" as Root

// Ring audio visualizer (cava) berbasis Canvas — ciri khas "dank":
// bar memanjang ke luar + refleksi pendek ke dalam (mirrored), attack cepat
// dan decay lembut. Album art digambar bulat di tengah pakai MultiEffect mask.
Item {
    id: root

    property int size: 200
    property real artRadius: size * 0.32      // radius album art di tengah
    property real gap: 4                       // jarak art ke bar
    property real maxBarLength: size * 0.20
    // barWidth otomatis menyesuaikan jumlah bar agar ring terlihat padat
    property real barWidth: Math.max(1.5, (2 * Math.PI * (artRadius + gap)) / (bars * 1.6))
    property int bars: 64                      // harus sama dengan BARS di cava_feed.sh
    property string colorStart: "#cba6f7"        // mauve
    property string colorEnd: "#f5c2e7"          // pink
    property bool mirrored: true                // bar dobel dari titik tengah
    property string coverSource: ""             // URL/path album art
    property var smoothValues: []

    implicitWidth: size
    implicitHeight: size

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            const target = Root.CavaService.values
            if (target.length === 0) return
            if (root.smoothValues.length !== target.length) {
                root.smoothValues = target.slice()
            } else {
                const next = []
                for (let i = 0; i < target.length; i++) {
                    const cur = root.smoothValues[i]
                    const tgt = target[i]
                    const rate = tgt > cur ? 0.55 : 0.12
                    next.push(cur + (tgt - cur) * rate)
                }
                root.smoothValues = next
            }
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const values = root.smoothValues
            const bars = values.length
            if (bars === 0) return

            const baseRadius = root.artRadius + root.gap
            ctx.lineCap = "round"
            ctx.lineWidth = root.barWidth

            for (let i = 0; i < bars; i++) {
                const angle = (i / bars) * Math.PI * 2 - Math.PI / 2
                const magnitude = Math.max(0, Math.min(100, values[i])) / 100
                const barLen = magnitude * root.maxBarLength

                // gradient per bar mengikuti posisi sudut
                const t = i / bars
                const r = Math.round(lerp(hexPart(root.colorStart, 0), hexPart(root.colorEnd, 0), t))
                const g = Math.round(lerp(hexPart(root.colorStart, 1), hexPart(root.colorEnd, 1), t))
                const b = Math.round(lerp(hexPart(root.colorStart, 2), hexPart(root.colorEnd, 2), t))
                ctx.strokeStyle = `rgb(${r},${g},${b})`

                const x1 = cx + Math.cos(angle) * baseRadius
                const y1 = cy + Math.sin(angle) * baseRadius
                const x2 = cx + Math.cos(angle) * (baseRadius + barLen)
                const y2 = cy + Math.sin(angle) * (baseRadius + barLen)

                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()

                // mirror: bar kedua nongol ke arah dalam art, efek "napas" dua arah
                if (root.mirrored) {
                    const mx2 = cx + Math.cos(angle) * (baseRadius - barLen * 0.4)
                    const my2 = cy + Math.sin(angle) * (baseRadius - barLen * 0.4)
                    ctx.globalAlpha = 0.5
                    ctx.beginPath()
                    ctx.moveTo(x1, y1)
                    ctx.lineTo(mx2, my2)
                    ctx.stroke()
                    ctx.globalAlpha = 1.0
                }
            }
        }

        function lerp(a, b, t) { return a + (b - a) * t }
        function hexPart(hex, index) {
            const h = hex.replace("#", "")
            return parseInt(h.substr(index * 2, 2), 16)
        }
    }

    // ── Album art bulat di tengah ─────────────────────────────────────────
    Item {
        id: artLayer
        anchors.centerIn: parent
        width: root.artRadius * 2
        height: root.artRadius * 2

        Image {
            id: artImg
            anchors.fill: parent
            source: root.coverSource
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: false
        }

        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: width / 2
            color: "black"
            layer.enabled: true
            visible: false
        }

        // Rectangle.clip tidak ikut radius, jadi mask lewat MultiEffect
        MultiEffect {
            anchors.fill: parent
            source: artImg
            maskEnabled: true
            maskSource: artMask
            visible: artImg.status === Image.Ready && root.coverSource !== ""
        }

        // Placeholder saat belum ada art
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Root.Colors.base
            border.color: Root.Colors.surface2
            border.width: 2
            visible: artImg.status !== Image.Ready || root.coverSource === ""

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.pixelSize: parent.width * 0.3
                color: Root.Colors.subtext
            }
        }
    }
}
