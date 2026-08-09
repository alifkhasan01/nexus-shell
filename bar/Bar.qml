import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root
import "./widgets"
import "../panels"
import "../power"
import "../notifications"
import "../dashboard" as Dash

PanelWindow {
    id: bar

    // State dashboard dibagikan dari shell.qml (bisa di-toggle lewat
    // global shortcut Hyprland ataupun klik jam).
    property var shellState: null
    property bool dashboardOpen: shellState ? shellState.dashboardOpen : false
    // powerMenuOpen dibaca dari shellState sehingga GlobalShortcut Hyprland
    // (quickshell:powermenu) dan klik tombol di Bar keduanya sinkron.
    property bool powerMenuOpen: shellState ? shellState.powerMenuOpen : false
    // Satu panel gabungan Wi-Fi + Bluetooth (tag dipilih via connectTab).
    property bool connectPanelOpen: false
    property int connectTab: 0  // 0 = Wi-Fi, 1 = Bluetooth
    property bool volumePanelOpen: false
    property bool batteryPanelOpen: false
    property bool wallpaperPanelOpen: shellState ? shellState.wallpaperPanelOpen : false
    property bool notifPanelOpen: false
    property bool clipboardPanelOpen: false

    onConnectPanelOpenChanged: {
        if (!connectPanelOpen) connectCloseTimer.restart()
        if (!connectPanelOpen) netStatus.refresh()
        if (!connectPanelOpen) btStatus.refresh()
    }
    onVolumePanelOpenChanged:    if (!volumePanelOpen)    volumeCloseTimer.restart()
    onBatteryPanelOpenChanged:   if (!batteryPanelOpen)   batteryCloseTimer.restart()
    onWallpaperPanelOpenChanged: if (!wallpaperPanelOpen) wallpaperCloseTimer.restart()
    onPowerMenuOpenChanged:      if (!powerMenuOpen)      powerCloseTimer.restart()
    onNotifPanelOpenChanged:     if (!notifPanelOpen)     notifCloseTimer.restart()
    onClipboardPanelOpenChanged: if (!clipboardPanelOpen) clipboardCloseTimer.restart()

    // ── Close timers — di root agar selalu tersedia ───────────────────────
    Timer { id: powerCloseTimer;     interval: 300; repeat: false }
    Timer { id: connectCloseTimer;   interval: 300; repeat: false }
    Timer { id: volumeCloseTimer;    interval: 300; repeat: false }
    Timer { id: batteryCloseTimer;   interval: 300; repeat: false }
    Timer { id: wallpaperCloseTimer; interval: 300; repeat: false }
    Timer { id: notifCloseTimer;     interval: 300; repeat: false }
    Timer { id: clipboardCloseTimer; interval: 300; repeat: false }

    anchors { top: true; left: true; right: true }
    margins.top: 10
    margins.left: 16
    margins.right: 16

    implicitHeight: 45
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: implicitHeight
    WlrLayershell.namespace: "quickshell-bar"

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            // ── LEFT ──────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    MenuButton {}
                    Workspaces {}
                }
            }

            // ── CENTER ────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Judul window aktif
                    ActiveWindow {
                        maxWidth: 200
                    }

                    Clock {
                        onClicked: {
                            bar.shellState.dashboardOpen = !bar.shellState.dashboardOpen
                            bar.connectPanelOpen = false
                            bar.volumePanelOpen = false
                            bar.batteryPanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                        onRightClicked: controlCenterProcess.running = true
                    }

                    // Stopwatch (hanya tampil saat aktif)
                    Stopwatch {}
                }
            }

            // ── RIGHT ─────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    // ── Tray indicators (Syncthing, VPN, Tailscale) ───────
                    TrayIndicators {}

                    NetworkStatus {
                        id: netStatus
                        panelOpen: bar.connectPanelOpen && bar.connectTab === 0
                        onTogglePanel: {
                            bar.connectTab = 0
                            bar.connectPanelOpen = !bar.connectPanelOpen
                            bar.shellState.dashboardOpen = false
                            bar.volumePanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                        onToggleWifi: {} // handled inside NetworkStatus widget
                    }

                    BluetoothStatus {
                        id: btStatus
                        panelOpen: bar.connectPanelOpen && bar.connectTab === 1
                        onTogglePanel: {
                            bar.connectTab = 1
                            bar.connectPanelOpen = !bar.connectPanelOpen
                            bar.shellState.dashboardOpen = false
                            bar.volumePanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                        onToggleBt: {} // handled inside BluetoothStatus widget
                    }

                    // ── Clipboard Button ──────────────────────────────────
                    Item {
                        width: 30
                        height: 26

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: clipArea.containsMouse
                                 ? Root.Colors.surface1
                                 : (bar.clipboardPanelOpen ? Root.Colors.surface0 : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅍"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 15
                            color: bar.clipboardPanelOpen ? Root.Colors.blue : Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: clipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.clipboardPanelOpen = !bar.clipboardPanelOpen
                                bar.connectPanelOpen = false
                                bar.volumePanelOpen = false
                                bar.shellState.dashboardOpen = false
                                bar.shellState.wallpaperPanelOpen = false
                                bar.notifPanelOpen = false
                            }
                        }
                    }

                    // ── Notification History Button ───────────────────────
                    Item {
                        width: 30
                        height: 26

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: notifArea.containsMouse
                                 ? Root.Colors.surface1
                                 : (bar.notifPanelOpen ? Root.Colors.surface0 : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰂞"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 15
                            color: bar.notifPanelOpen ? Root.Colors.blue : Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: notifArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.notifPanelOpen = !bar.notifPanelOpen
                                bar.connectPanelOpen = false
                                bar.volumePanelOpen = false
                                bar.shellState.dashboardOpen = false
                                bar.shellState.wallpaperPanelOpen = false
                                bar.clipboardPanelOpen = false
                            }
                        }
                    }

                    // ── Wallpaper Button ──────────────────────────────────
                    Item {
                        width: 30
                        height: 26

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: wpArea.containsMouse
                                 ? Root.Colors.surface1
                                 : (bar.wallpaperPanelOpen ? Root.Colors.surface0 : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰸉"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 16
                            color: bar.wallpaperPanelOpen ? Root.Colors.blue : Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: wpArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    bar.shellState.wallpaperRandom.pickRandom()
                                } else {
                                    bar.shellState.wallpaperPanelOpen = !bar.shellState.wallpaperPanelOpen
                                    bar.connectPanelOpen   = false
                                    bar.volumePanelOpen    = false
                                    bar.shellState.dashboardOpen = false
                                    bar.notifPanelOpen = false
                                    bar.clipboardPanelOpen = false
                                }
                            }
                        }
                    }

                    Volume {
                        id: volumeStatus
                        panelOpen: bar.volumePanelOpen
                        onTogglePanel: {
                            bar.volumePanelOpen = !bar.volumePanelOpen
                            bar.connectPanelOpen = false
                            bar.shellState.dashboardOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                        onOsdVolume: (value, muted) => osd.showVolume(value, muted)
                    }

                    Brightness {
                        onOsdBrightness: value => osd.showBrightness(value)
                    }
                    Battery {
                        panelOpen: bar.batteryPanelOpen
                        onTogglePanel: {
                            bar.batteryPanelOpen = !bar.batteryPanelOpen
                            bar.connectPanelOpen = false
                            bar.volumePanelOpen = false
                            bar.shellState.dashboardOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                    }
                    PowerButton {
                        menuOpen: bar.powerMenuOpen
                        onToggleMenu: {
                            bar.shellState.powerMenuOpen = !bar.shellState.powerMenuOpen
                            bar.connectPanelOpen  = false
                            bar.volumePanelOpen  = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.shellState.dashboardOpen = false
                            bar.notifPanelOpen = false
                            bar.clipboardPanelOpen = false
                        }
                    }
                }
            }
        }
    }

    // ── Power Menu ────────────────────────────────────────────────────────
    LazyLoader {
        id: powerLoader
        active: bar.powerMenuOpen || powerCloseTimer.running

        PowerMenu {
            open: bar.powerMenuOpen
            onCloseRequested: bar.shellState.powerMenuOpen = false
        }
    }

    // ── Dashboard ─────────────────────────────────────────────────────────
    Timer {
        id: dashCloseTimer
        interval: 300   // sedikit lebih lama dari durasi animasi (180ms)
        running: false
        repeat: false
    }

    LazyLoader {
        active: bar.dashboardOpen || dashCloseTimer.running

        Dash.Dashboard {
            open: bar.dashboardOpen
            dndActive: bar.shellState ? bar.shellState.dnd : false
            onCloseRequested: bar.shellState.dashboardOpen = false
            onScreenshotRequested: bar.takeScreenshot()
            onGrimRequested: bar.takeGrim()
            onRecorderToggleRequested: bar.toggleRecorder()
            onRecorderMicToggleRequested: bar.toggleRecorderMic()
            onSetFaceRequested: bar.startFacePicker()
            onNotifyRequested: (icon, summary, body) => bar.sendNotif(icon, summary, body)
            onDndToggleRequested: {
                bar.shellState.dnd = !bar.shellState.dnd
                if (bar.shellState.dnd)
                    bar.sendNotif("notifications-disabled", "Do Not Disturb Aktif", "Notifikasi dinonaktifkan.")
                else
                    bar.sendNotif("notification", "Do Not Disturb Nonaktif", "Notifikasi diaktifkan kembali.")
            }
            onOpenChanged: {
                if (!open) dashCloseTimer.restart()
            }
        }
    }

    // ── Connect Panel (Wi-Fi + Bluetooth) ─────────────────────────────────
    LazyLoader {
        id: connectLoader
        active: bar.connectPanelOpen || connectCloseTimer.running

        ConnectPanel {
            open: bar.connectPanelOpen
            requestedTab: bar.connectTab
            onCloseRequested: bar.connectPanelOpen = false
        }
    }

    // ── Volume Panel ──────────────────────────────────────────────────────
    LazyLoader {
        id: volumeLoader
        active: bar.volumePanelOpen || volumeCloseTimer.running

        VolumePanel {
            open: bar.volumePanelOpen
            onCloseRequested: bar.volumePanelOpen = false
        }
    }

    // ── Battery Panel ─────────────────────────────────────────────────────
    LazyLoader {
        id: batteryLoader
        active: bar.batteryPanelOpen || batteryCloseTimer.running

        BatteryPanel {
            open: bar.batteryPanelOpen
            onCloseRequested: bar.batteryPanelOpen = false
        }
    }

    // ── Wallpaper Panel ───────────────────────────────────────────────────
    LazyLoader {
        id: wallpaperLoader
        active: bar.wallpaperPanelOpen || wallpaperCloseTimer.running

        WallpaperPanel {
            open: bar.wallpaperPanelOpen
            onCloseRequested: bar.shellState.wallpaperPanelOpen = false
        }
    }

    // ── Notification History Panel ────────────────────────────────────────
    LazyLoader {
        id: notifPanelLoader
        active: bar.notifPanelOpen || notifCloseTimer.running

        NotificationPanel {
            open: bar.notifPanelOpen
            onCloseRequested: bar.notifPanelOpen = false
        }
    }

    // ── Clipboard Panel ───────────────────────────────────────────────────
    LazyLoader {
        id: clipboardLoader
        active: bar.clipboardPanelOpen || clipboardCloseTimer.running

        ClipboardPanel {
            open: bar.clipboardPanelOpen
            onCloseRequested: bar.clipboardPanelOpen = false
        }
    }

    // ── Notification Popup ────────────────────────────────────────────────
    // Dipindahkan ke shell.qml agar render di atas semua komponen lain

    // ── OSD (Volume & Brightness) ─────────────────────────────────────────
    Osd { id: osd }

    Process {
        id: controlCenterProcess
        command: ["control-center"]
    }

    // Screenshot select (area) — grimblast copysave, notif setelah selesai via stdout
    Process {
        id: screenshotProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave area \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    bar.sendNotif("camera-photo", "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard")
                else
                    bar.sendNotif("dialog-error", "Screenshot Dibatalkan",
                        "Area tidak dipilih atau gagal menyimpan.")
            }
        }
    }

    // Screenshot full — grimblast copysave, delay 400ms agar dashboard hilang dulu
    Process {
        id: grimProc
        command: ["sh", "-c",
            "DIR=~/Pictures/Screenshots; " +
            "mkdir -p \"$DIR\"; " +
            "FILE=\"$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png\"; " +
            "grimblast copysave screen \"$FILE\" 2>/dev/null && echo \"$FILE\" || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const file = text.trim()
                if (file !== "")
                    bar.sendNotif("camera-photo", "Screenshot Tersimpan",
                        file.replace(/.*\//, "") + "  ·  disalin ke clipboard")
                else
                    bar.sendNotif("dialog-error", "Screenshot Gagal",
                        "Tidak dapat mengambil screenshot.")
            }
        }
    }

    Timer {
        id: grimDelayTimer
        interval: 400
        repeat: false
        onTriggered: grimProc.running = true
    }

    // gpu-screen-recorder — desktop only (left click, default)
    // Script fork GSR lalu langsung exit, jadi onRunningChanged tidak dipakai
    // untuk deteksi stop. Deteksi stop dilakukan via pidfile di recCheckProc.
    Process {
        id: recorderProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh desktop-only"]
    }

    // gpu-screen-recorder — desktop + mic gabungan (right click)
    Process {
        id: recorderMicProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh both"]
    }

    function takeScreenshot()    { screenshotProc.running = true }
    function takeGrim()          { bar.shellState.dashboardOpen = false; grimDelayTimer.restart() }
    function toggleRecorder()    { recorderProc.running = true }
    function toggleRecorderMic() { recorderMicProc.running = true }

    // Kirim notifikasi via notify-send (dipanggil dari dashboard)
    Process {
        id: notifProc
    }
    function sendNotif(icon, summary, body) {
        const args = ["notify-send", "--app-name=Quickshell", "--expire-time=4000"]
        if (icon !== "") args.push("--icon=" + icon)
        args.push(summary)
        if (body !== "") args.push(body)
        notifProc.command = args
        notifProc.running = true
    }

    // ── Face picker (jalankan di level Bar agar tidak ikut mati saat
    //    dashboard ditutup; dashboard ditutup dulu supaya window zenity
    //    tidak tertutup dashboard, lalu dibuka lagi setelah selesai).
    function startFacePicker() {
        bar.shellState.dashboardOpen = false
        facePickerProc.running = true
    }

    Process {
        id: facePickerProc
        command: ["sh", "-c",
            "FILE=$(zenity --file-selection --title='Pilih foto profil' " +
            "--file-filter='Gambar | *.png *.jpg *.jpeg *.webp' 2>/dev/null); " +
            "[ -n \"$FILE\" ] && cp \"$FILE\" ~/.face && echo 'ok'"
        ]
        onRunningChanged: {
            if (!running) bar.shellState.dashboardOpen = true
        }
    }
}
