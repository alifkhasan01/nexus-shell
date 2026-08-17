import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

// Welcome Panel — muncul saat startup bila ada dependensi yang kurang.
//   • Menampilkan status dependensi (✓ terpasang / ✗ belum)
//   • Tombol "Install Dependensi" → menjalankan scripts/install-deps.sh (via pkexec)
//   • Output install ditampilkan di console area
//   • Toggle "Tampilkan saat startup" disimpan ke ~/.config/quickshell/welcome-settings.json
// Trigger: GlobalShortcut quickshell:welcome  +  auto-open dari shell.qml
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()
    signal installFinished(var allInstalled)
    signal depsUpdated()

    // Di-inject dari shell.qml — untuk re-check flags ProcessManager setelah install
    property var procManager: null
    // Supaya console scroll ikut output terbaru
    property string consoleText: ""
    property bool installing: false
    property int missingCount: 0
    property bool settingsLoaded: false
    property bool _installDonePending: false

    // Tampilkan di startup? (default true)
    property bool showOnStartup: true

    onShowOnStartupChanged: _saveSettings()
    onOpenChanged: {
        if (open && !visible) {
            showPanel = true
            checkDeps()
        }
    }

    function _saveSettings() {
        if (!settingsLoaded) return
        const json = JSON.stringify({ "showOnStartup": showOnStartup })
        const escaped = json.replace(/'/g, "'\\''")
        saveSettingsProc.command = ["sh", "-c",
            "echo '" + escaped + "' > ~/.config/quickshell/welcome-settings.json"]
        saveSettingsProc.running = true
    }

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel
    property bool showPanel: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-welcome"
    WlrLayershell.exclusiveZone: 0

    // ── Data dependensi ─────────────────────────────────────────────────
    property var deps: [
        { name: "grimblast",  label: "grimblast",  desc: "Screenshot" },
        { name: "bluetoothctl", label: "bluez-utils", desc: "Bluetooth" },
        { name: "nmcli",      label: "NetworkManager", desc: "Wi-Fi" },
        { name: "notify-send", label: "libnotify",  desc: "Notifikasi" },
        { name: "brightnessctl", label: "brightnessctl", desc: "Kecerahan layar" },
        { name: "cliphist",   label: "cliphist",   desc: "Riwayat clipboard" },
        { name: "wl-copy",    label: "wl-clipboard", desc: "Clipboard" },
        { name: "pactl",      label: "pipewire-utils", desc: "Audio" },
        { name: "wpctl",      label: "wireplumber",   desc: "Audio (volume)" },
        { name: "playerctl",  label: "playerctl",  desc: "Media keys" },
        { name: "awww",       label: "awww",        desc: "Wallpaper" },
        { name: "hyprsunset", label: "hyprsunset", desc: "Night light" },
        { name: "zenity",     label: "zenity",     desc: "File picker" },
        { name: "powerprofilesctl", label: "power-profiles-daemon", desc: "Power mode" },
        { name: "jq",         label: "jq",         desc: "JSON tool" },
        { name: "ffmpegthumbnailer", label: "ffmpegthumbnailer", desc: "Video thumb" },
        { name: "magick",     label: "imagemagick", desc: "Thumbnails" },
        { name: "curl",       label: "curl",       desc: "Weather & API" }
    ]

    property var depStatus: ({})

    // ── Cek dependensi (command -v tiap binary) ─────────────────────────
    function checkDeps() {
        const bins = root.deps.map(d => d.name)
        depsCheckProc.command = ["sh", "-c",
            "for b in " + bins.join(" ") + "; do " +
            "command -v \"$b\" >/dev/null 2>&1 && echo \"$b:1\" || echo \"$b:0\"; done"]
        depsCheckProc.running = true
    }

    function _applyDeps(stdout) {
        const newStatus = {}
        for (const line of stdout.split("\n")) {
            const parts = line.trim().split(":")
            if (parts.length === 2) newStatus[parts[0]] = parts[1] === "1"
        }
        for (const d of root.deps) {
            if (newStatus[d.name] === undefined) newStatus[d.name] = false
        }
        root.depStatus = newStatus
        root.missingCount = root.deps.filter(d => !newStatus[d.name]).length
        root.depsUpdated()

        // Emit hasil install HANYA setelah status ter-update
        if (root._installDonePending) {
            root._installDonePending = false
            root.installFinished(root.missingCount === 0)
        }
    }

    // ── Install dependensi ──────────────────────────────────────────────
    function installDeps() {
        if (root.installing) return
        root.installing = true
        root.consoleText = ">> Menyiapkan install dependensi...\n"
        const script = Quickshell.env("HOME") + "/.config/quickshell/scripts/install-deps.sh"
        installProc.command = ["sh", "-c", "exec pkexec bash '" + script + "' 2>&1"]
        installProc.running = true
    }

    function closePanel() {
        root.closeRequested()
        showPanel = false
    }

    // ── Proses ──────────────────────────────────────────────────────────
    Process {
        id: depsCheckProc
        stdout: StdioCollector {
            onStreamFinished: root._applyDeps(text)
        }
    }

    Process {
        id: installProc
        command: ["sh", "-c", "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.consoleText += text
                Qt.callLater(() => consoleScroll.contentY = consoleScroll.contentHeight)
            }
        }
        onRunningChanged: {
            if (!running) {
                root.installing = false
                console.log("[Welcome] Install process finished (exit: " + exitCode + ")")
                // Re-check status + sinkronkan flags ProcessManager
                root.consoleText += "\n>> Selesai (exit code " + exitCode + ").\n"
                Qt.callLater(() => consoleScroll.contentY = consoleScroll.contentHeight)
                root._installDonePending = true
                root.checkDeps()
                if (root.procManager && root.procManager.recheckDependencies)
                    root.procManager.recheckDependencies()
            }
        }
    }

    // ── Settings persistence ────────────────────────────────────────────
    Process { id: saveSettingsProc }

    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/welcome-settings.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const cfg = JSON.parse(text.trim() || "{}")
                    if (cfg.showOnStartup !== undefined) root.showOnStartup = cfg.showOnStartup
                } catch (e) {
                    console.warn("[Welcome] Settings parse error, pakai default")
                }
                root.settingsLoaded = true
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        checkDeps()
    }

    Keys.onEscapePressed: closePanel()

    // ══ UI ═══════════════════════════════════════════════════════════════
    // Backdrop (transparent - klik untuk tutup)
    MouseArea {
        anchors.fill: parent
        onClicked: closePanel()
    }

    // Card utama
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 620
        height: 560
        radius: 18
        color: Root.Colors.base
        border.width: 2
        border.color: Root.Colors.surface1
        opacity: root.showPanel ? 1 : 0
        scale: root.showPanel ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Klik di dalam card jangan menutup
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 12
                    color: Root.Colors.blue
                    Text {
                        anchors.centerIn: parent
                        text: "󰔉"
                        font.pixelSize: 22
                        color: Root.Colors.base
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Selamat Datang di Quickshell"
                        font.pixelSize: 18
                        font.bold: true
                        color: Root.Colors.text
                    }
                    Text {
                        text: root.installing
                            ? "Menginstall dependensi…"
                            : (root.missingCount > 0
                                ? root.missingCount + " dependensi belum terpasang"
                                : "Semua dependensi sudah terpasang")
                        font.pixelSize: 12
                        color: root.missingCount > 0 ? Root.Colors.yellow : Root.Colors.green
                    }
                }
            }

            // ── Daftar dependensi ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 240
                radius: 12
                color: Root.Colors.mantle
                clip: true

                Flickable {
                    id: depScroll
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: depColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: depColumn
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: root.deps
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: 8
                                color: depStatus[modelData.name]
                                    ? "transparent"
                                    : (depHov.containsMouse ? Root.Colors.surface0 : Root.Colors.surface1)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Text {
                                        text: depStatus[modelData.name] ? "✓" : "✗"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: depStatus[modelData.name] ? Root.Colors.green : Root.Colors.red
                                    }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 13
                                        color: Root.Colors.text
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.desc
                                        font.pixelSize: 11
                                        color: Root.Colors.subtext
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                    MouseArea {
                                        id: depHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Console output install ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.installing || root.consoleText.length > 0 ? 110 : 0
                Layout.maximumHeight: 140
                visible: root.consoleText.length > 0
                radius: 10
                color: Root.Colors.mantle
                border.width: 1
                border.color: Root.Colors.surface1
                clip: true

                Flickable {
                    id: consoleScroll
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: consoleTextEdit.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: consoleTextEdit
                        width: consoleScroll.width
                        text: root.consoleText
                        font.family: "monospace"
                        font.pixelSize: 11
                        color: Root.Colors.subtext
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Toggle startup + tombol aksi ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Toggle "Tampilkan saat startup"
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 24
                        radius: 12
                        color: root.showOnStartup ? Root.Colors.green : Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: Root.Colors.base
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.showOnStartup ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showOnStartup = !root.showOnStartup
                        }
                    }
                    Text {
                        text: "Tampilkan saat startup"
                        font.pixelSize: 12
                        color: Root.Colors.text
                    }
                }

                // Periksa ulang
                Rectangle {
                    implicitHeight: 38
                    implicitWidth: 110
                    radius: 10
                    color: refreshHov.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐  Periksa Ulang"
                        font.pixelSize: 12
                        color: Root.Colors.text
                    }
                    MouseArea {
                        id: refreshHov
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.checkDeps()
                    }
                }

                // Install dependensi
                Rectangle {
                    implicitHeight: 38
                    implicitWidth: 150
                    radius: 10
                    color: (root.installing || root.missingCount === 0)
                        ? Root.Colors.surface1
                        : (installHov.containsMouse ? Root.Colors.lavender : Root.Colors.blue)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    opacity: (root.installing || root.missingCount === 0) ? 0.6 : 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.installing ? "󰑭" : "󰒓"
                            font.pixelSize: 14
                            color: (root.installing || root.missingCount === 0) ? Root.Colors.subtext : Root.Colors.base
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.installing ? "Menginstall…" : "Install Dependensi"
                            font.pixelSize: 12
                            font.bold: true
                            color: (root.installing || root.missingCount === 0) ? Root.Colors.subtext : Root.Colors.base
                        }
                    }
                    MouseArea {
                        id: installHov
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        enabled: !root.installing && root.missingCount > 0
                        onClicked: root.installDeps()
                    }
                }
            }
        }
    }
}
