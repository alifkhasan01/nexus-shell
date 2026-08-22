import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root
import "../services"

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()
    signal pickFolderRequested()

    // Dipanggil dari Bar setelah zenity selesai — update folder dan scan ulang
    function onFolderPicked(dir) {
        if (dir.length > 0) {
            root.wallpaperDir = dir
            root.saveConfig()
            root.scanWallpapers()
        }
    }

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
            grid.forceActiveFocus()
            if (root.wallpapers.length === 0)
                loadConfigProc.running = true
            else {
                // Panel sudah pernah scan — langsung muat cache untuk wallpaper yang ada
                root.loadExistingThumbs(root.wallpapers)
                // Auto-scroll ke wallpaper aktif
                root.focusCurrentWallpaper()
            }
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.exclusiveZone: 0

    // ── State ─────────────────────────────────────────────────────────────
    property var    wallpapers: []
    property var    filtered:   []
    property string statusText: "Siap."
    property bool   scanning:   false
    property bool   slideshowEnabled: false
    property int    slideshowMinutes: 5
    property string transitionType:     "wipe"
    property real   transitionDuration: 1.0
    property int    transitionFps:      60
    property string wallpaperDir:   ""
    property bool   settingsOpen:   false
    property string searchQuery:    ""
    // "fill" | "fit" | "stretch" | "center" | "tile"
    property string wallpaperMode:  "fill"
    // path wallpaper yang sedang di-preview (hover / klik)
    property string previewPath:    ""
    property string currentWallpaperPath: ""  // wallpaper aktif saat ini
    // index yang diseleksi lewat keyboard (panah). -1 = belum ada seleksi.
    property int selectedIndex: -1

    // ── Thumbnail cache (disk) ─────────────────────────────────────────────
    // Map: origPath (string) → thumbPath (string).
    // Diisi oleh genThumbsProc. Jika path belum ada di sini, Image load dari
    // sumber asli sambil thumb di-generate di background.
    property var thumbCache: ({})

    // Kembalikan URL source terbaik untuk sebuah wallpaper:
    // thumb dari cache (lebih cepat) → file asli (fallback).
    function thumbSource(origPath) {
        const t = root.thumbCache[origPath]
        return (t && t.length > 0) ? ("file://" + t) : ("file://" + origPath)
    }

    // Perbarui satu entri cache dan paksa QML model refresh melalui re-assign.
    function _setCacheEntry(origPath, thumbPath) {
        const c = root.thumbCache
        c[origPath] = thumbPath
        root.thumbCache = c   // trigger propertyChanged → delegate re-evaluate
    }

    readonly property string nf: "CaskaydiaCove Nerd Font"

    // ── Config ────────────────────────────────────────────────────────────
    Process {
        id: loadConfigProc
        command: ["sh", "-c", "cat ~/.config/quickshell/data/wallpaper.json 2>/dev/null || cat ~/.config/wallpicker/config.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text)
                    root.wallpaperDir       = c.wallpaper_dir              || (root._home() + "/Pictures/Wallpapers")
                    root.transitionType     = c.transition_type            || "wipe"
                    root.transitionDuration = c.transition_duration        || 1.0
                    root.transitionFps      = c.transition_fps             || 60
                    root.slideshowEnabled   = c.slideshow_enabled          || false
                    root.slideshowMinutes   = c.slideshow_interval_minutes || 5
                    root.wallpaperMode      = c.wallpaper_mode             || "fill"
                } catch(e) {
                    root.wallpaperDir = root._home() + "/Pictures/Wallpapers"
                }
                root.scanWallpapers()
                if (root.slideshowEnabled) root.startSlideshow()
            }
        }
    }

    Process {
        id: readCurrentProc
        command: ["sh", "-c", "cat ~/.cache/wallpaper/current 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0) {
                    root.currentWallpaperPath = p
                    if (root.previewPath === "") root.previewPath = p
                    // Update service juga
                    WallpaperService.setCurrent(p)
                }
            }
        }
    }

    // Sinkronisasi dengan WallpaperService (yang di-update oleh WallpaperRandom)
    Connections {
        target: WallpaperService
        function onCurrentWallpaperChanged() {
            if (WallpaperService.currentWallpaper !== "") {
                root.currentWallpaperPath = WallpaperService.currentWallpaper
                // Auto-focus ke wallpaper baru jika panel terbuka
                if (root.open)
                    root.focusCurrentWallpaper()
            }
        }
    }

    // Refresh currentWallpaper setiap 2 detik saat panel terbuka
    // (untuk menangkap perubahan dari WallpaperRandom atau sumber lain)
    Timer {
        id: currentWallpaperRefreshTimer
        interval: 2000
        running: root.open
        repeat: true
        onTriggered: readCurrentProc.running = true
    }

    function _home() { return Quickshell.env("HOME") || "" }

    function saveConfig() {
        const cfg = {
            wallpaper_dir: root.wallpaperDir,
            transition_type: root.transitionType,
            transition_duration: root.transitionDuration,
            transition_fps: root.transitionFps,
            wallpaper_mode: root.wallpaperMode,
            thumb_size: 220, columns: 4,
            slideshow_enabled: root.slideshowEnabled,
            slideshow_interval_minutes: root.slideshowMinutes
        }
        const json = JSON.stringify(cfg, null, 2)
        saveConfigProc.command = ["sh", "-c",
            "mkdir -p ~/.config/quickshell/data && cat > ~/.config/quickshell/data/wallpaper.json << 'EOCFG'\n" +
            json + "\nEOCFG"]
        saveConfigProc.running = true
    }
    Process { id: saveConfigProc }

    // ── Thumbnail cache — generate + load ────────────────────────────────
    // Jalankan gen-thumbs.sh dengan daftar file dari stdin.
    // Output per baris: "<thumbPath>|<origPath>"  (thumbPath kosong = gagal)
    Process {
        id: genThumbsProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                for (const line of lines) {
                    const sep = line.indexOf("|")
                    if (sep < 0) continue
                    const thumbPath = line.substring(0, sep)
                    const origPath  = line.substring(sep + 1)
                    if (origPath.length > 0 && thumbPath.length > 0)
                        root._setCacheEntry(origPath, thumbPath)
                }
            }
        }
    }

    // Kirim daftar path ke gen-thumbs.sh. Script otomatis skip file yang
    // thumb-nya sudah up-to-date (cek mtime), generate hanya yang baru/stale.
    // Generate paralel di sisi script (xargs -P). Output per baris:
    // "<thumbPath>|<origPath>" → diisi ke thumbCache.
    function loadExistingThumbs(paths) {
        if (paths.length === 0) return
        const esc = paths.map(p => p.replace(/'/g, "'\\''"))
        // Batch kecil supaya aman dari limit ARG_MAX saat koleksi ribuan file
        const BATCH = 500
        let prints = ""
        for (let i = 0; i < esc.length; i += BATCH)
            prints += "printf '" + esc.slice(i, i + BATCH).join("\\n") + "\\n'; "
        genThumbsProc.command = ["sh", "-c",
            "{ " + prints + "} | bash \"$HOME/.config/quickshell/scripts/gen-thumbs.sh\""]
        genThumbsProc.running = true
    }

    // ── Scan ──────────────────────────────────────────────────────────────
    function scanWallpapers() {
        if (root.wallpaperDir === "") return
        root.scanning = true
        root.statusText = "Memindai wallpaper..."
        scanProc.command = ["sh", "-c",
            "find '" + root.wallpaperDir.replace(/'/g, "'\\''") + "'" +
            " -maxdepth 3 -type f" +
            " \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png'" +
            "    -o -iname '*.webp' -o -iname '*.bmp' \\)" +
            " | sort"]
        scanProc.running = true
        readCurrentProc.running = true
    }

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                root.wallpapers = lines
                root.applyFilter()
                root.scanning = false
                root.statusText = lines.length + " wallpaper ditemukan."
                // Muat / generate thumbnail cache untuk semua wallpaper yang baru di-scan.
                // Script otomatis skip file yang thumb-nya sudah baru (mtime check).
                root.loadExistingThumbs(lines)
                // Auto-scroll ke wallpaper aktif jika panel terbuka
                if (root.open)
                    root.focusCurrentWallpaper()
            }
        }
        onExited: (code) => {
            if (code !== 0 && !root.scanning) return
            if (code !== 0) {
                root.scanning = false
                root.statusText = "⚠ Folder tidak ditemukan: " + root.wallpaperDir
            }
        }
    }

    function applyFilter() {
        const q = root.searchQuery.toLowerCase()
        root.filtered = q === "" ? root.wallpapers
            : root.wallpapers.filter(p =>
                p.split("/").pop().toLowerCase().includes(q))
    }
    onSearchQueryChanged: applyFilter()
    onFilteredChanged: root.selectedIndex = -1

    // ── Navigasi keyboard (panah + Enter) ───────────────────────────────
    function moveSelection(dx, dy) {
        const n = root.filtered.length
        if (n === 0) return
        let idx = (root.selectedIndex >= 0 && root.selectedIndex < n) ? root.selectedIndex : 0
        const cols = Math.max(1, grid.cols)
        let row = Math.floor(idx / cols)
        let col = idx % cols
        col += dx
        row += dy
        if (col < 0) { col = cols - 1; row -= 1 }
        if (col >= cols) { col = 0; row += 1 }
        if (row < 0) row = 0
        root.setSelection(Math.max(0, Math.min(n - 1, row * cols + col)))
    }

    function setSelection(i) {
        if (i < 0 || i >= root.filtered.length) return
        root.selectedIndex = i
        root.previewPath = root.filtered[i]
        grid.positionViewAtIndex(i, GridView.Center)
    }

    function focusCurrentWallpaper() {
        // Auto-scroll dan highlight wallpaper yang sedang aktif
        if (root.currentWallpaperPath === "" || root.filtered.length === 0)
            return
        
        // Cari index wallpaper aktif di filtered list
        const idx = root.filtered.indexOf(root.currentWallpaperPath)
        if (idx >= 0) {
            // Set sebagai selected dan scroll ke posisinya
            root.setSelection(idx)
            // Jangan ubah previewPath jika tidak perlu
            if (root.previewPath === "")
                root.previewPath = root.currentWallpaperPath
        } else if (root.previewPath === "") {
            // Wallpaper aktif tidak ada di filtered (mungkin karena search) —
            // set preview ke wallpaper aktif tetap supaya preview konsisten
            root.previewPath = root.currentWallpaperPath
        }
    }

    function activateSelection() {
        const i = root.selectedIndex
        if (i >= 0 && i < root.filtered.length) {
            root.previewPath = root.filtered[i]
            root.setWallpaper(root.filtered[i])
        }
    }

    // ── Set wallpaper ─────────────────────────────────────────────────────
    // Saat dipanggil: sembunyikan card → jalankan awww → tampilkan lagi
    property bool hiddenForTransition: false

    // Durasi sembunyi = durasi transisi awww + 200 ms buffer (dalam ms)
    Timer {
        id: reshowTimer
        repeat: false
        onTriggered: root.hiddenForTransition = false
    }

    // Map wallpaperMode → flag resize awww (--resize, awww ≥0.10 tidak pakai --scaling)
    function _modeToResize(mode) {
        switch (mode) {
            case "fit":     return "--resize fit"
            case "stretch": return "--resize stretch"
            case "center":  return "--no-resize"   // center + padding
            case "tile":    return "--resize crop" // awww tidak support tile
            default:        return "--resize crop" // "fill" → crop (PreserveAspectCrop)
        }
    }

    function setWallpaper(path) {
        root.statusText = "Menerapkan " + path.split("/").pop() + "..."

        root.hiddenForTransition = true
        reshowTimer.interval = Math.round(root.transitionDuration * 1000) + 800
        reshowTimer.restart()

        const esc     = path.replace(/'/g, "'\\''")
        const resize  = root._modeToResize(root.wallpaperMode)
        setProc.command = ["sh", "-c",
            "(awww query >/dev/null 2>&1 || (awww-daemon >/dev/null 2>&1 & sleep 0.4)) && " +
            "awww img '" + esc + "'" +
            " --transition-type "     + root.transitionType +
            " --transition-duration " + root.transitionDuration +
            " --transition-fps "      + root.transitionFps +
            " "                       + resize +
            " && mkdir -p ~/.cache/wallpaper" +
            " && printf '%s' '" + esc + "' > ~/.cache/wallpaper/current" +
            " && ln -sf '"     + esc + "' ~/.cache/wallpaper/hyprlock-bg" +
            " && echo ok"]
        setProc.running = true
    }

    Process {
        id: setProc
        property string lastError: ""
        stderr: StdioCollector {
            onStreamFinished: setProc.lastError = text.trim()
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "ok") {
                    root.currentWallpaperPath = root.previewPath
                    root.statusText = "✓ Wallpaper diset: " + root.previewPath.split("/").pop()
                    // Update WallpaperService
                    WallpaperService.setCurrent(root.previewPath)
                } else {
                    root.statusText = "⚠ Gagal set wallpaper." +
                        (setProc.lastError.length > 0 ? " (" + setProc.lastError.split("\n")[0] + ")" : "")
                    // Gagal? tampilkan panel langsung jangan tunggu timer
                    reshowTimer.stop()
                    root.hiddenForTransition = false
                }
                // Panel akan muncul kembali via reshowTimer (biarkan timer jalan penuh)
            }
        }
    }

    // ── Random (dipanggil juga dari IPC di shell.qml) ─────────────────────
    function pickRandom() {
        if (root.filtered.length === 0) {
            // Kalau panel belum dimuat, scan dulu lalu set acak via timer
            if (root.wallpapers.length === 0 && root.wallpaperDir !== "") {
                root.scanning = true
                root.statusText = "Memindai untuk acak..."
                scanProc.command = ["sh", "-c",
                    "find '" + root.wallpaperDir.replace(/'/g, "'\\''") + "'" +
                    " -maxdepth 3 -type f" +
                    " \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png'" +
                    "    -o -iname '*.webp' -o -iname '*.bmp' \\)" +
                    " | sort"]
                scanProc.running = true
                randomAfterScanTimer.start()
                return
            }
        }
        const idx = Math.floor(Math.random() * root.filtered.length)
        root.previewPath = root.filtered[idx]
        root.setWallpaper(root.filtered[idx])
    }

    Timer {
        id: randomAfterScanTimer
        interval: 1200; repeat: false
        onTriggered: {
            if (root.filtered.length > 0) {
                const idx = Math.floor(Math.random() * root.filtered.length)
                root.previewPath = root.filtered[idx]
                root.setWallpaper(root.filtered[idx])
            }
        }
    }

    // ── Slideshow ─────────────────────────────────────────────────────────
    Timer {
        id: slideshowTimer
        interval: 60000
        repeat: true
        onTriggered: root.pickRandom()
    }

    function startSlideshow() {
        slideshowTimer.interval = Math.max(1, root.slideshowMinutes) * 60000
        slideshowTimer.restart()
    }

    function stopSlideshow() {
        slideshowTimer.stop()
    }

    Component.onCompleted: loadConfigProc.running = true

    // ── Kartu utama ───────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  Math.min(1300, root.width  - 40)
        height: Math.min(720,  root.height - 60)
        radius: 16
        color:  Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // opacity dikontrol: 0 saat belum open, 1 saat open, 0 sementara saat transisi wallpaper
        opacity: root.open && !root.hiddenForTransition ? 1 : 0
        transform: Translate { id: cardTranslate; y: -50 }

        // Animasi opacity — cepat saat transisi wallpaper, normal saat buka/tutup panel
        Behavior on opacity {
            NumberAnimation {
                duration: root.hiddenForTransition ? Root.Appearance.animation.elementMoveFast.duration : Root.Appearance.animation.elementMoveSmall.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.open ? Root.Appearance.animation.elementMoveEnter.bezierCurve : Root.Appearance.animation.elementMoveExit.bezierCurve
            }
        }

        states: State {
            name: "open"; when: root.open
            PropertyChanges { target: cardTranslate; y: 0 }
        }
        transitions: [
            Transition {
                from: ""; to: "open"
                NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Layout: kiri = kontrol+grid, kanan = preview ──────────────────
        RowLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ════════════════════════════════════════════════════════════
            // KOLOM KIRI — header + settings + grid
            // ════════════════════════════════════════════════════════════
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ── Header ────────────────────────────────────────────
                ColumnLayout {
                    id: headerCol
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰸉  Wallpaper"
                            font.pixelSize: 16; font.bold: true
                            font.family: root.nf
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }

                        // Search
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 30
                            radius: 8; color: Root.Colors.surface0
                            border.color: searchInput.activeFocus ? Root.Colors.blue : "transparent"
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6
                                Text {
                                    text: "\uf002"; font.pixelSize: 12; font.family: root.nf
                                    color: Root.Colors.subtext
                                }
                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    font.pixelSize: 12; color: Root.Colors.text
                                    onTextChanged: root.searchQuery = text
                                }
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
                                visible: searchInput.text.length === 0 && !searchInput.activeFocus
                                text: "Cari wallpaper..."; font.pixelSize: 12; color: Root.Colors.subtext
                            }
                        }

                        // Random
                        Rectangle {
                            implicitWidth: 30; implicitHeight: 30; radius: 8
                            color: randHov.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            Text {
                                anchors.centerIn: parent
                                text: ""; font.pixelSize: 15; font.family: root.nf
                                color: Root.Colors.blue
                            }
                            MouseArea { id: randHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pickRandom() }
                        }

                        // Refresh
                        Rectangle {
                            implicitWidth: 30; implicitHeight: 30; radius: 8
                            color: refHov.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            Text {
                                anchors.centerIn: parent
                                text: ""; font.pixelSize: 15; font.family: root.nf
                                color: root.scanning ? Root.Colors.blue : Root.Colors.subtext
                                RotationAnimation on rotation {
                                    running: root.scanning; from: 0; to: 360
                                    duration: 900; loops: Animation.Infinite
                                    direction: RotationAnimation.Counterclockwise
                                }
                            }
                            MouseArea { id: refHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (!root.scanning) root.scanWallpapers() } }
                        }

                        // Settings
                        Rectangle {
                            implicitWidth: 30; implicitHeight: 30; radius: 8
                            color: root.settingsOpen ? Root.Colors.blue : (setHov.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            Text {
                                anchors.centerIn: parent
                                text: ""; font.pixelSize: 14; font.family: root.nf
                                color: root.settingsOpen ? Root.Colors.base : Root.Colors.subtext
                            }
                            MouseArea { id: setHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsOpen = !root.settingsOpen }
                        }

                        // Close
                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 8
                            color: closeHov.containsMouse ? Root.Colors.surface1 : "transparent"
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            Text { anchors.centerIn: parent; text: "󱎘"; font.pixelSize: 13; color: Root.Colors.subtext }
                            MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1 }
                }


                // ── Grid thumbnail ────────────────────────────────────
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 8
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 4
                    clip: true

                    // kolom adaptif: muat sebanyak mungkin (target ~180px + gap)
                    readonly property int pad: 8
                    readonly property int cols: Math.max(1, Math.floor((width + pad) / (180 + pad)))
                    // thumbW dihitung agar cols*(thumbW+pad) == width (isi penuh tanpa
                    // sisa kosong / overflow di sebelah kanan)
                    readonly property int thumbW: Math.max(1, Math.floor((width - pad * cols) / cols))
                    readonly property int thumbH: Math.round(thumbW * 9 / 16)

                    cellWidth:  thumbW + pad
                    cellHeight: thumbH + 20

                    focus: true
                    activeFocusOnTab: true

                    Keys.onUpPressed:    root.moveSelection(0, -1)
                    Keys.onDownPressed:  root.moveSelection(0, 1)
                    Keys.onLeftPressed:  root.moveSelection(-1, 0)
                    Keys.onRightPressed: root.moveSelection(1, 0)
                    Keys.onReturnPressed: root.activateSelection()
                    Keys.onEnterPressed:  root.activateSelection()

                    model: root.filtered

                    ScrollBar.vertical: ScrollBar {
                        width: 4; policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { radius: 2; color: Root.Colors.surface2; opacity: parent.active ? 1.0 : 0.4 }
                        background: Rectangle { color: "transparent" }
                    }

                    delegate: Item {
                        required property string modelData
                        required property int    index

                        readonly property int labelH: 16  // tinggi area label bawah (fixed)
                        readonly property int pad2: grid.pad / 2

                        width:  grid.cellWidth
                        height: grid.cellHeight

                        Text {
                            id: thumbLabel
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
                            height: parent.labelH
                            text: modelData.split("/").pop()
                            font.pixelSize: 9; color: Root.Colors.subtext
                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            id: thumbCard
                            anchors {
                                top: parent.top; topMargin: 4
                                left: parent.left; leftMargin: pad2
                                right: parent.right; rightMargin: pad2
                                bottom: thumbLabel.top; bottomMargin: 3
                            }
                            radius: 8; color: Root.Colors.surface0; clip: true
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            Image {
                                anchors.fill: parent
                                source: root.thumbSource(modelData)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true; cache: true
                                sourceSize.width:  grid.thumbW * 2
                                sourceSize.height: grid.thumbH * 2
                                smooth: true; mipmap: false

                                Rectangle {
                                    anchors.fill: parent; radius: 8
                                    color: Root.Colors.surface1
                                    visible: parent.status !== Image.Ready
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                    // Spinner saat load langsung dari file asli (belum ada thumb cache)
                                    Text {
                                        anchors.centerIn: parent
                                        visible: parent.parent.status === Image.Loading
                                        text: "\udb80\udde3"; font.pixelSize: 18; font.family: root.nf
                                        color: Root.Colors.blue
                                        RotationAnimation on rotation {
                                            running: parent.parent.status === Image.Loading
                                            from: 0; to: 360; duration: 800; loops: Animation.Infinite
                                            direction: RotationAnimation.Counterclockwise
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: parent.parent.status === Image.Error
                                        text: "\udb82\udcdb"; font.pixelSize: 18; font.family: root.nf
                                        color: Root.Colors.subtext
                                    }
                                }
                            }

                            // Hover overlay — tahan klik untuk preview, klik untuk set
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                color: Qt.rgba(0,0,0,0.38)
                                opacity: tMa.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 130 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\udb80\udc58"; font.pixelSize: 20; font.family: root.nf
                                    color: "white"
                                }
                            }

                            // Border aktif
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; color: "transparent"
                                border.color: root.selectedIndex === index ? Root.Colors.blue
                                            : root.currentWallpaperPath === modelData ? Root.Colors.green
                                            : (tMa.containsMouse ? Root.Colors.blue : "transparent")
                                border.width: root.selectedIndex === index ? 3 : 2
                                Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            MouseArea {
                                id: tMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered:  root.previewPath = modelData
                                onExited:   root.previewPath = root.currentWallpaperPath
                                onClicked:  {
                                    root.setSelection(index)
                                    root.setWallpaper(modelData)
                                }
                            }
                        }
                    }

                    // Empty / scanning states
                    Text {
                        anchors.centerIn: parent
                        visible: !root.scanning && root.filtered.length === 0
                        text: root.wallpapers.length === 0
                            ? "Tidak ada wallpaper.\nCek folder di pengaturan."
                            : "Tidak ada hasil untuk \"" + root.searchQuery + "\""
                        font.pixelSize: 13; color: Root.Colors.subtext
                        horizontalAlignment: Text.AlignHCenter; lineHeight: 1.5
                    }
                    Column {
                        anchors.centerIn: parent; spacing: 10; visible: root.scanning
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\udb80\udde3"; font.pixelSize: 28; font.family: root.nf; color: Root.Colors.blue
                            RotationAnimation on rotation { running: root.scanning; from: 0; to: 360; duration: 900; loops: Animation.Infinite; direction: RotationAnimation.Counterclockwise }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Memindai..."; font.pixelSize: 12; color: Root.Colors.subtext }
                    }
                }

                // ── Footer ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12; Layout.leftMargin: 14; Layout.rightMargin: 14; Layout.topMargin: 6
                    spacing: 8

                    Text {
                        Layout.fillWidth: true; text: root.statusText; font.pixelSize: 11; elide: Text.ElideRight
                        color: root.statusText.startsWith("⚠") ? Root.Colors.red
                             : root.statusText.startsWith("✓") ? Root.Colors.green : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    }
                    Text {
                        visible: root.filtered.length > 0 && !root.scanning
                        text: root.filtered.length +
                              (root.filtered.length !== root.wallpapers.length ? " / " + root.wallpapers.length : "") +
                              " gambar"
                        font.pixelSize: 11; color: Root.Colors.subtext
                    }
                    Rectangle {
                        implicitWidth: closeFtTxt.implicitWidth + 24; implicitHeight: 32; radius: 8
                        color: closeFtMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        Text { id: closeFtTxt; anchors.centerIn: parent; text: "Tutup"; font.pixelSize: 12; color: Root.Colors.text }
                        MouseArea { id: closeFtMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                    }
                }
            }

            // ════════════════════════════════════════════════════════════
            // KOLOM KANAN — preview wallpaper
            // ════════════════════════════════════════════════════════════
            Rectangle {
                id: previewCol
                Layout.preferredWidth: 260
                Layout.minimumWidth: 0
                Layout.fillHeight: true
                clip: true
                color: Root.Colors.base
                radius: 0
                layer.enabled: true
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Label
                    Text {
                        text: "Preview"
                        font.pixelSize: 12; font.bold: true; font.letterSpacing: 0.5
                        color: Root.Colors.subtext; opacity: 0.8
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    }

                    // Preview image
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(width * 9 / 16)
                        radius: 10; color: Root.Colors.surface0; clip: true
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                        Image {
                            id: previewImg
                            anchors.fill: parent
                            source: root.previewPath.length > 0 ? "file://" + root.previewPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; cache: false
                            sourceSize.width:  520
                            sourceSize.height: 292
                            smooth: true

                            Behavior on source {}

                            // Fade saat ganti gambar
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // Placeholder
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: previewImg.status !== Image.Ready
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\udb81\udc09"; font.pixelSize: 32; font.family: root.nf
                                color: Root.Colors.surface2
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Hover wallpaper"; font.pixelSize: 11; color: Root.Colors.surface2
                            }
                        }
                    }

                    // Nama file
                    Text {
                        Layout.fillWidth: true
                        text: root.previewPath.length > 0 ? root.previewPath.split("/").pop() : ""
                        font.pixelSize: 11; color: Root.Colors.text
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 2; elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    }

                    // Path folder
                    Text {
                        Layout.fillWidth: true
                        text: root.previewPath.length > 0
                            ? root.previewPath.substring(0, root.previewPath.lastIndexOf("/"))
                            : ""
                        font.pixelSize: 9; color: Root.Colors.subtext; elide: Text.ElideLeft
                    }

                    // Badge "aktif"
                    Rectangle {
                        visible: root.previewPath === root.currentWallpaperPath && root.currentWallpaperPath !== ""
                        height: 22; width: activeLbl.implicitWidth + 16; radius: 6
                        color: Qt.rgba(Root.Colors.green.r, Root.Colors.green.g, Root.Colors.green.b, 0.18)
                        border.color: Root.Colors.green; border.width: 1
                        Text { id: activeLbl; anchors.centerIn: parent; text: "✓ Aktif saat ini"; font.pixelSize: 10; color: Root.Colors.green }
                    }

                    // Badge mode positioning
                    Rectangle {
                        visible: root.wallpaperMode !== ""
                        height: 22; width: modeBadgeLbl.implicitWidth + 16; radius: 6
                        color: Qt.rgba(Root.Colors.lavender.r, Root.Colors.lavender.g, Root.Colors.lavender.b, 0.15)
                        border.color: Qt.rgba(Root.Colors.lavender.r, Root.Colors.lavender.g, Root.Colors.lavender.b, 0.5)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                        Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

                        RowLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: {
                                    switch (root.wallpaperMode) {
                                        case "fit":     return "󰹚"
                                        case "stretch": return "󰢅"
                                        case "center":  return "󰘞"
                                        case "tile":    return "󰙀"
                                        default:        return "󰹙"  // fill
                                    }
                                }
                                font.pixelSize: 11; font.family: root.nf
                                color: Root.Colors.lavender
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                            }
                            Text {
                                id: modeBadgeLbl
                                text: root.wallpaperMode.charAt(0).toUpperCase() + root.wallpaperMode.slice(1)
                                font.pixelSize: 10; color: Root.Colors.lavender
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Tombol Set Wallpaper
                    Rectangle {
                        Layout.fillWidth: true; height: 38; radius: 10
                        enabled: root.previewPath.length > 0
                        color: setWpMa.containsMouse && enabled
                             ? Qt.lighter(Root.Colors.blue, 1.1) : Root.Colors.blue
                        opacity: enabled ? 1 : 0.4
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                        RowLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text {
                                text: "\udb80\udc58"; font.pixelSize: 15; font.family: root.nf
                                color: Root.Colors.base
                            }
                            Text { text: "Set Wallpaper"; font.pixelSize: 13; color: Root.Colors.base }
                        }

                        MouseArea {
                            id: setWpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.previewPath.length > 0) root.setWallpaper(root.previewPath)
                        }
                    }

                    // Tombol Random
                    Rectangle {
                        Layout.fillWidth: true; height: 34; radius: 10
                        color: randRightMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                        RowLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text {
                                text: ""; font.pixelSize: 14; font.family: root.nf
                                color: Root.Colors.blue
                            }
                            Text { text: "Acak"; font.pixelSize: 12; color: Root.Colors.text }
                        }

                        MouseArea {
                            id: randRightMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickRandom()
                        }
                    }
                }
            }
        }

        // ── Settings popup overlay ────────────────────────────────────────
        WallpaperSettings {
            id: settingsPopup
            anchors.fill: parent

            open: root.settingsOpen
            onOpenChanged: root.settingsOpen = open

            wallpaperDir:       root.wallpaperDir
            transitionType:     root.transitionType
            transitionDuration: root.transitionDuration
            transitionFps:      root.transitionFps
            slideshowEnabled:   root.slideshowEnabled
            slideshowMinutes:   root.slideshowMinutes
            wallpaperMode:      root.wallpaperMode

            onWallpaperDirChanged:       root.wallpaperDir       = wallpaperDir
            onTransitionTypeChanged:     root.transitionType     = transitionType
            onTransitionDurationChanged: root.transitionDuration = transitionDuration
            onTransitionFpsChanged:      root.transitionFps      = transitionFps
            onSlideshowEnabledChanged: {
                root.slideshowEnabled = slideshowEnabled
                root.slideshowEnabled ? root.startSlideshow() : root.stopSlideshow()
            }
            onSlideshowMinutesChanged:   root.slideshowMinutes   = slideshowMinutes
            onWallpaperModeChanged:      root.wallpaperMode      = wallpaperMode

            onSaveRequested:        root.saveConfig()
            onScanRequested:        root.scanWallpapers()
            onPickFolderRequested:  root.pickFolderRequested()
            onPickingDirChanged:    {} // tidak dipakai lagi
        }
    }

}
