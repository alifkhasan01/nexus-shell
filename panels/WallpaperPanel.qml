import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
            if (root.wallpapers.length === 0)
                loadConfigProc.running = true
            else
                // Panel sudah pernah scan — langsung muat cache untuk wallpaper yang ada
                root.loadExistingThumbs(root.wallpapers)
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
    // path wallpaper yang sedang di-preview (hover / klik)
    property string previewPath:    ""
    property string currentWallpaperPath: ""  // wallpaper aktif saat ini

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
        command: ["sh", "-c", "cat ~/.config/quickshell/wallpaper.json 2>/dev/null || cat ~/.config/wallpicker/config.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text)
                    root.wallpaperDir       = c.wallpaper_dir                  || (root._home() + "/Pictures/Wallpapers")
                    root.transitionType     = c.transition_type                || "wipe"
                    root.transitionDuration = c.transition_duration            || 1.0
                    root.transitionFps      = c.transition_fps                 || 60
                    root.slideshowEnabled   = c.slideshow_enabled              || false
                    root.slideshowMinutes   = c.slideshow_interval_minutes     || 5
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
                }
            }
        }
    }

    function _home() { return "/home/xans" }

    function saveConfig() {
        const cfg = {
            wallpaper_dir: root.wallpaperDir,
            transition_type: root.transitionType,
            transition_duration: root.transitionDuration,
            transition_fps: root.transitionFps,
            thumb_size: 220, columns: 4,
            slideshow_enabled: root.slideshowEnabled,
            slideshow_interval_minutes: root.slideshowMinutes
        }
        const json = JSON.stringify(cfg, null, 2)
        saveConfigProc.command = ["sh", "-c",
            "mkdir -p ~/.config/quickshell && cat > ~/.config/quickshell/wallpaper.json << 'EOCFG'\n" +
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
    // Output per baris: "<thumbPath>|<origPath>" → diisi ke thumbCache.
    function loadExistingThumbs(paths) {
        if (paths.length === 0) return
        const scriptPath = "/home/xans/.config/quickshell/scripts/gen-thumbs.sh"
        const escaped = paths.map(p => p.replace(/'/g, "'\\''")).join("\\n")
        // Jalankan script — entri yang thumb-nya sudah baru langsung return
        // tanpa regenerate; entri yang belum ada atau stale akan di-generate.
        genThumbsProc.command = ["sh", "-c",
            "printf '" + escaped + "\\n' | bash '" +
            scriptPath.replace(/'/g, "'\\''") + "'"]
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

    // ── Set wallpaper ─────────────────────────────────────────────────────
    function setWallpaper(path) {
        root.statusText = "Menerapkan " + path.split("/").pop() + "..."
        const esc = path.replace(/'/g, "'\\''")
        setProc.command = ["sh", "-c",
            "(awww query >/dev/null 2>&1 || (awww-daemon >/dev/null 2>&1 & sleep 0.4)) && " +
            "awww img '" + esc + "'" +
            " --transition-type "     + root.transitionType +
            " --transition-duration " + root.transitionDuration +
            " --transition-fps "      + root.transitionFps +
            " && mkdir -p ~/.cache/wallpaper" +
            " && printf '%s' '" + esc + "' > ~/.cache/wallpaper/current" +
            " && ln -sf '"     + esc + "' ~/.cache/wallpaper/hyprlock-bg" +
            " && echo ok"]
        setProc.running = true
    }

    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "ok") {
                    root.currentWallpaperPath = root.previewPath
                    root.statusText = "✓ Wallpaper diset: " + root.previewPath.split("/").pop()
                } else {
                    root.statusText = "⚠ Gagal set wallpaper."
                }
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

        opacity: 0
        transform: Translate { id: cardTranslate; y: -50 }

        states: State {
            name: "open"; when: root.open
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
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Search
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 30
                            radius: 8; color: Root.Colors.surface0
                            border.color: searchInput.activeFocus ? Root.Colors.blue : "transparent"
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

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
                            Behavior on color { ColorAnimation { duration: 120 } }
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
                            Behavior on color { ColorAnimation { duration: 120 } }
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
                            Behavior on color { ColorAnimation { duration: 120 } }
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
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "󱎘"; font.pixelSize: 13; color: Root.Colors.subtext }
                            MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1 }
                }

                // ── Settings collapsible ──────────────────────────────
                Item {
                    id: settingsPanel
                    Layout.fillWidth: true
                    Layout.leftMargin: 14; Layout.rightMargin: 14; Layout.topMargin: 4
                    Layout.preferredHeight: root.settingsOpen ? settingsInner.height : 0
                    clip: true
                    visible: Layout.preferredHeight > 0
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: settingsInner
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: settingsCol.implicitHeight + 24
                        radius: 10
                        color: Root.Colors.base
                        border.color: Root.Colors.surface1
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            id: settingsCol
                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                            spacing: 10

                            // Folder
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Folder"; font.pixelSize: 11; color: Root.Colors.subtext; Layout.preferredWidth: 70 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 6
                                    color: dirHov.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6
                                        Text { text: "󰉋"; font.pixelSize: 12; font.family: root.nf; color: Root.Colors.subtext }
                                        Text { Layout.fillWidth: true; text: root.wallpaperDir; font.pixelSize: 11; color: Root.Colors.text; elide: Text.ElideLeft }
                                    }
                                    MouseArea {
                                        id: dirHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { dirPickProc.command = ["sh", "-c", "zenity --file-selection --directory --title='Pilih folder wallpaper' 2>/dev/null"]; dirPickProc.running = true }
                                    }
                                }
                            }

                            // Transition chips
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Transisi"; font.pixelSize: 11; color: Root.Colors.subtext; Layout.preferredWidth: 70 }
                                Flow {
                                    spacing: 4; Layout.fillWidth: true
                                    Repeater {
                                        model: ["simple","fade","wipe","wave","grow","center","outer","random"]
                                        delegate: Rectangle {
                                            required property string modelData
                                            height: 22; width: chipLbl.implicitWidth + 16; radius: 6
                                            color: root.transitionType === modelData ? Root.Colors.blue : (chipMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text { id: chipLbl; anchors.centerIn: parent; text: modelData; font.pixelSize: 10; color: root.transitionType === modelData ? Root.Colors.base : Root.Colors.text }
                                            MouseArea { id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.transitionType = modelData; root.saveConfig() } }
                                        }
                                    }
                                }
                            }

                            // Dur / FPS
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text { text: "Durasi"; font.pixelSize: 11; color: Root.Colors.subtext }
                                Rectangle {
                                    height: 24; width: 60; radius: 6; color: Root.Colors.surface0
                                    TextInput {
                                        id: durInput
                                        anchors.centerIn: parent; width: parent.width - 10
                                        text: root.transitionDuration
                                        font.pixelSize: 11; color: Root.Colors.text
                                        validator: DoubleValidator { bottom: 0.1; top: 5.0; decimals: 1 }
                                        onEditingFinished: { root.transitionDuration = parseFloat(text) || 1.0; root.saveConfig() }
                                    }
                                }
                                Text { text: "dtk"; font.pixelSize: 11; color: Root.Colors.subtext }

                                Item { Layout.preferredWidth: 8 }

                                Text { text: "FPS"; font.pixelSize: 11; color: Root.Colors.subtext }
                                Rectangle {
                                    height: 24; width: 52; radius: 6; color: Root.Colors.surface0
                                    TextInput {
                                        id: fpsInput
                                        anchors.centerIn: parent; width: parent.width - 10
                                        text: root.transitionFps
                                        font.pixelSize: 11; color: Root.Colors.text
                                        validator: IntValidator { bottom: 24; top: 144 }
                                        onEditingFinished: { root.transitionFps = parseInt(text) || 60; root.saveConfig() }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            // Slideshow
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text { text: "Slideshow"; font.pixelSize: 11; color: Root.Colors.subtext }
                                Text { text: "tiap"; font.pixelSize: 11; color: Root.Colors.subtext }
                                Rectangle {
                                    height: 24; width: 46; radius: 6; color: Root.Colors.surface0
                                    TextInput {
                                        id: slideInput
                                        anchors.centerIn: parent; width: parent.width - 10
                                        text: root.slideshowMinutes
                                        font.pixelSize: 11; color: Root.Colors.text
                                        validator: IntValidator { bottom: 1; top: 120 }
                                        onEditingFinished: { root.slideshowMinutes = parseInt(text) || 5; root.saveConfig() }
                                    }
                                }
                                Text { text: "menit"; font.pixelSize: 11; color: Root.Colors.subtext }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 26; width: slideLbl.implicitWidth + 22; radius: 6
                                    color: root.slideshowEnabled ? Root.Colors.blue : (slideTogMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text { id: slideLbl; anchors.centerIn: parent; text: root.slideshowEnabled ? "ON" : "OFF"; font.pixelSize: 10; font.bold: true; color: root.slideshowEnabled ? Root.Colors.base : Root.Colors.subtext }
                                    MouseArea { id: slideTogMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.slideshowEnabled = !root.slideshowEnabled; root.saveConfig(); root.slideshowEnabled ? root.startSlideshow() : root.stopSlideshow() }
                                    }
                                }
                            }
                        }
                    }

                    Process {
                        id: dirPickProc
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const d = text.trim()
                                if (d.length > 0) { root.wallpaperDir = d; root.saveConfig(); root.scanWallpapers() }
                            }
                        }
                    }
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
                            Behavior on color { ColorAnimation { duration: 120 } }

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
                                    Behavior on color { ColorAnimation { duration: 150 } }
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
                                border.color: root.currentWallpaperPath === modelData ? Root.Colors.green
                                            : (tMa.containsMouse ? Root.Colors.blue : "transparent")
                                border.width: 2
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: tMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered:  root.previewPath = modelData
                                onExited:   root.previewPath = root.currentWallpaperPath
                                onClicked:  { root.previewPath = modelData; root.setWallpaper(modelData) }
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
                        Behavior on color { ColorAnimation { duration: 150 } }
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
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { id: closeFtTxt; anchors.centerIn: parent; text: "Tutup"; font.pixelSize: 12; color: Root.Colors.text }
                        MouseArea { id: closeFtMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                    }
                }
            }

            // ════════════════════════════════════════════════════════════
            // KOLOM KANAN — preview wallpaper (tersembunyi saat settings terbuka)
            // ════════════════════════════════════════════════════════════
            Rectangle {
                id: previewCol
                Layout.preferredWidth: root.settingsOpen ? 0 : 260
                Layout.minimumWidth: 0
                Layout.maximumWidth: root.settingsOpen ? 0 : 260
                Layout.fillHeight: true
                clip: true
                color: Root.Colors.base
                radius: 0
                layer.enabled: true
                opacity: root.settingsOpen ? 0 : 1

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on Layout.maximumWidth   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity               { NumberAnimation { duration: 180 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Label
                    Text {
                        text: "Preview"
                        font.pixelSize: 12; font.bold: true; font.letterSpacing: 0.5
                        color: Root.Colors.subtext; opacity: 0.8
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Preview image
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(width * 9 / 16)
                        radius: 10; color: Root.Colors.surface0; clip: true
                        Behavior on color { ColorAnimation { duration: 150 } }

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
                        Behavior on color { ColorAnimation { duration: 150 } }
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

                    Item { Layout.fillHeight: true }

                    // Tombol Set Wallpaper
                    Rectangle {
                        Layout.fillWidth: true; height: 38; radius: 10
                        enabled: root.previewPath.length > 0
                        color: setWpMa.containsMouse && enabled
                             ? Qt.lighter(Root.Colors.blue, 1.1) : Root.Colors.blue
                        opacity: enabled ? 1 : 0.4
                        Behavior on color { ColorAnimation { duration: 120 } }

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
                        Behavior on color { ColorAnimation { duration: 120 } }

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
    }

}
