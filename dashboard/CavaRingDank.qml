import QtQuick
import QtQuick.Effects
import "../" as Root

// Ring audio visualizer (cava) — ombak melingkar mulus.
// Titik-titik amplitudo diplot di sepanjang lingkaran lalu
// dihubungkan dengan kurva Bezier cubic sehingga terbentuk
// ombak kontinyu (bukan bar terputus-putus).
// Area antara ring baseline dan ombak di-fill dengan gradient
// transparan untuk efek "glow ombak".
Item {
    id: root

    property int  size:         200
    property real artRadius:    size * 0.32     // radius album art di tengah
    property real gap:          6               // jarak baseline ke tepi art
    property real maxBarLength: Math.max(6, size * 0.16 - 6) // amplitudo max ombak (px); pas muat di dalam item agar tidak terpotong
    property int  bars:         64              // harus sama dengan kBars di qs_visualizer.cpp

    property string colorOuter: "#cba6f7"       // mauve  — puncak ombak luar
    property string colorInner: "#f5c2e7"       // pink   — puncak ombak dalam
    property string coverSource: ""

    property var smoothValues: []

    implicitWidth:  size
    implicitHeight: size

    // Aktifkan CavaService saat komponen visible
    Component.onCompleted:  Root.CavaService.active = visible
    onVisibleChanged:        Root.CavaService.active = visible
    Component.onDestruction: Root.CavaService.active = false

    // ── Smoothing timer ~60 fps ───────────────────────────────────────────
    Timer {
        interval: 16
        running:  root.visible
        repeat:   true
        onTriggered: {
            const target = Root.CavaService.values
            if (target.length === 0) return

            const n = root.bars
            // Pastikan smoothValues punya panjang yang sama dengan `bars`,
            // bukan panjang raw dari cava (yang mungkin berbeda).
            if (root.smoothValues.length !== n) {
                // Inisialisasi ulang, resample target ke panjang n
                const tmp = []
                for (let i = 0; i < n; i++) {
                    const srcIdx = Math.floor(i * target.length / n)
                    tmp.push(target[srcIdx] ?? 0)
                }
                root.smoothValues = tmp
            } else {
                const next = []
                for (let i = 0; i < n; i++) {
                    const srcIdx = Math.floor(i * target.length / n)
                    const tgt = target[srcIdx] ?? 0
                    const cur = root.smoothValues[i]
                    // Attack cepat, decay lembut → terasa seperti ombak
                    const rate = tgt > cur ? 0.45 : 0.10
                    next.push(cur + (tgt - cur) * rate)
                }
                root.smoothValues = next
            }
            canvas.requestPaint()
        }
    }

    // ── Canvas ────────────────────────────────────────────────────────────
    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget:  Canvas.FramebufferObject
        antialiasing:  true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const cx     = width  / 2
            const cy     = height / 2
            const vals   = root.smoothValues
            const n      = vals.length
            if (n < 2) return

            const baseR  = root.artRadius + root.gap
            const maxLen = root.maxBarLength

            // ── Fungsi pembantu ───────────────────────────────────────────
            // Posisi titik di lingkaran pada sudut `a` dengan radius `r`
            function pt(a, r) {
                return { x: cx + Math.cos(a) * r,
                         y: cy + Math.sin(a) * r }
            }

            // Kontrol-point Bezier cubic: tengah-tengah dua titik berurutan
            function cp(p0, p1) {
                return { x: (p0.x + p1.x) / 2,
                         y: (p0.y + p1.y) / 2 }
            }

            // ── Kumpulkan titik ombak luar & dalam ───────────────────────
            const outerPts = []
            const innerPts = []
            for (let i = 0; i <= n; i++) {       // +1 agar lingkaran tertutup
                const idx  = i % n
                const a    = (idx / n) * Math.PI * 2 - Math.PI / 2
                const mag  = Math.max(0, Math.min(100, vals[idx])) / 100
                outerPts.push(pt(a, baseR + mag * maxLen))
                innerPts.push(pt(a, baseR - mag * maxLen * 0.35))  // refleksi lebih kecil
            }

            // ── Helper: gambar path Bezier dari array titik (tertutup) ────
            function drawSmoothRing(pts, close) {
                ctx.beginPath()
                // Mulai dari titik kontrol pertama (midpoint 0→1)
                const m0 = cp(pts[0], pts[1])
                ctx.moveTo(m0.x, m0.y)
                for (let i = 1; i < pts.length - 1; i++) {
                    const mid = cp(pts[i], pts[i + 1])
                    ctx.quadraticCurveTo(pts[i].x, pts[i].y, mid.x, mid.y)
                }
                if (close) ctx.closePath()
            }

            // ── 1. Fill area ombak luar (gradient radial) ─────────────────
            const grad = ctx.createRadialGradient(cx, cy, baseR, cx, cy, baseR + maxLen)
            grad.addColorStop(0,   hexAlpha(root.colorOuter, 0.0))
            grad.addColorStop(0.4, hexAlpha(root.colorOuter, 0.18))
            grad.addColorStop(1.0, hexAlpha(root.colorOuter, 0.55))
            ctx.fillStyle = grad
            drawSmoothRing(outerPts, false)
            // Tutup path balik ke baseline melingkar agar fill rapi
            ctx.arc(cx, cy, baseR, Math.PI * 1.5, -Math.PI / 2 + Math.PI * 2, false)
            ctx.closePath()
            ctx.fill()

            // ── 2. Stroke ombak luar ──────────────────────────────────────
            ctx.strokeStyle = root.colorOuter
            ctx.lineWidth   = 2.0
            ctx.lineJoin    = "round"
            ctx.lineCap     = "round"
            drawSmoothRing(outerPts, true)
            ctx.stroke()

            // ── 3. Fill area ombak dalam (refleksi, lebih transparan) ─────
            const gradIn = ctx.createRadialGradient(cx, cy, baseR - maxLen * 0.35, cx, cy, baseR)
            gradIn.addColorStop(0,   hexAlpha(root.colorInner, 0.45))
            gradIn.addColorStop(0.6, hexAlpha(root.colorInner, 0.12))
            gradIn.addColorStop(1.0, hexAlpha(root.colorInner, 0.0))
            ctx.fillStyle = gradIn
            drawSmoothRing(innerPts, false)
            ctx.arc(cx, cy, baseR, Math.PI * 1.5, -Math.PI / 2 + Math.PI * 2, false)
            ctx.closePath()
            ctx.fill()

            // ── 4. Stroke ombak dalam ─────────────────────────────────────
            ctx.globalAlpha = 0.5
            ctx.strokeStyle = root.colorInner
            ctx.lineWidth   = 1.2
            drawSmoothRing(innerPts, true)
            ctx.stroke()
            ctx.globalAlpha = 1.0

            // ── 5. Ring baseline (lingkaran tipis) ────────────────────────
            ctx.strokeStyle = hexAlpha(root.colorOuter, 0.20)
            ctx.lineWidth   = 1.0
            ctx.beginPath()
            ctx.arc(cx, cy, baseR, 0, Math.PI * 2)
            ctx.stroke()
        }

        // ── Util: hex "#rrggbb" → "rgba(r,g,b,a)" ────────────────────────
        function hexAlpha(hex, alpha) {
            const h = hex.replace("#", "")
            const r = parseInt(h.substr(0, 2), 16)
            const g = parseInt(h.substr(2, 2), 16)
            const b = parseInt(h.substr(4, 2), 16)
            return `rgba(${r},${g},${b},${alpha})`
        }
    }

    // ── Album art bulat di tengah ─────────────────────────────────────────
    Item {
        id: artLayer
        anchors.centerIn: parent
        width:  root.artRadius * 2
        height: root.artRadius * 2

        Image {
            id: artImg
            anchors.fill: parent
            source: root.coverSource
            sourceSize.width:  width  * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            visible: false

            // Cover art berputar pelan (efek vinyl) selama art tampil.
            transform: Rotation {
                id: artSpin
                origin.x: artImg.width / 2
                origin.y: artImg.height / 2
                angle: 0
                NumberAnimation on angle {
                    from: 0; to: 360
                    duration: 16000
                    loops: Animation.Infinite
                    running: artImg.status === Image.Ready && root.coverSource !== ""
                }
            }
        }

        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: width / 2
            color:  "black"
            layer.enabled: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source:       artImg
            maskEnabled:  true
            maskSource:   artMask
            visible: artImg.status === Image.Ready && root.coverSource !== ""
        }

        // Placeholder saat belum ada art
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color:  Root.Colors.base
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
