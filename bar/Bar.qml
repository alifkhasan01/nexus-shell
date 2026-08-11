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
    // menuOpen dibaca dari shellState sehingga GlobalShortcut dan klik tombol di Bar
    // keduanya sinkron.
    property bool menuOpen: shellState ? shellState.menuOpen : false
    // Panel lama (calendar/connect/clipboard/notif/volume/battery) sudah
    // digabung jadi tab di Dashboard. Highlight tombol bar dihitung dari
    // tab dashboard yang sedang aktif.
    property bool connectPanelOpen:   shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 4) : false
    property bool clipboardPanelOpen: shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 5) : false
    property bool calendarPanelOpen:  shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 7) : false
    property bool notifPanelOpen:     shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 6) : false
    property bool volumePanelOpen:    shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 2) : false
    property bool batteryPanelOpen:   shellState ? (shellState.dashboardOpen && shellState.dashboardTab === 3) : false
    property bool wallpaperPanelOpen: shellState ? shellState.wallpaperPanelOpen : false

    // Buka control center di tab tertentu. Tutup panel lain yang mungkin
    // masih terbuka supaya tidak bertumpuk.
    function openDashboard(tab, connectSubTab) {
        if (connectSubTab !== undefined)
            bar.shellState.dashboardConnectSubTab = connectSubTab
        bar.shellState.dashboardTab = tab
        bar.shellState.dashboardOpen = true
        bar.shellState.menuOpen = false
        bar.shellState.powerMenuOpen = false
        bar.shellState.wallpaperPanelOpen = false
        bar.volumePanelOpen = false
        bar.batteryPanelOpen = false
        bar.notifPanelOpen = false
    }

    onWallpaperPanelOpenChanged: if (!wallpaperPanelOpen) wallpaperCloseTimer.restart()
    onPowerMenuOpenChanged:      if (!powerMenuOpen)      powerCloseTimer.restart()

    // ── Close timers — di root agar selalu tersedia ───────────────────────
    Timer { id: powerCloseTimer;     interval: 300; repeat: false }
    Timer { id: wallpaperCloseTimer; interval: 300; repeat: false }
    anchors { top: true; left: true; right: true }
    margins.top: 2
    margins.left: 4
    margins.right: 4

    implicitHeight: 45
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: implicitHeight + margins.top  // 45 + 6 = 51
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
                    MenuButton {
                        menuOpen: bar.menuOpen
                        onToggleMenu: {
                            bar.shellState.menuOpen = !bar.shellState.menuOpen
                            bar.shellState.dashboardOpen      = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.shellState.powerMenuOpen      = false
                        }
                    }
                    Workspaces {}
                    // ActiveWindow {
                        // maxWidth: 200
                    // }
                }
            }

            // ── CENTER ────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Clock {
                        // Left click → tab Kalender
                        onClicked: {
                            bar.openDashboard(7)
                        }
                        // Right click → tab Overview
                        onRightClicked: {
                            bar.openDashboard(0)
                        }
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
                        panelOpen: bar.shellState
                            ? (bar.shellState.dashboardOpen && bar.shellState.dashboardTab === 4 && bar.shellState.dashboardConnectSubTab === 0)
                            : false
                        onTogglePanel: bar.openDashboard(4, 0)
                        onToggleWifi: {} // handled inside NetworkStatus widget
                    }

                    BluetoothStatus {
                        id: btStatus
                        panelOpen: bar.shellState
                            ? (bar.shellState.dashboardOpen && bar.shellState.dashboardTab === 4 && bar.shellState.dashboardConnectSubTab === 1)
                            : false
                        onTogglePanel: bar.openDashboard(4, 1)
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
                                if (bar.clipboardPanelOpen && bar.shellState.dashboardOpen) {
                                    bar.shellState.dashboardOpen = false
                                } else {
                                    bar.openDashboard(5)
                                }
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
                                if (bar.notifPanelOpen && bar.shellState.dashboardOpen) {
                                    bar.shellState.dashboardOpen = false
                                } else {
                                    bar.openDashboard(6)
                                }
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
                                    bar.shellState.dashboardOpen = false
                                    bar.shellState.menuOpen = false
                                    bar.shellState.powerMenuOpen = false
                                }
                            }
                        }
                    }

                    Volume {
                        id: volumeStatus
                        panelOpen: bar.volumePanelOpen
                        onTogglePanel: bar.openDashboard(2)
                        onOsdVolume: (value, muted) => osd.showVolume(value, muted)
                    }

                    Brightness {
                        onOsdBrightness: value => osd.showBrightness(value)
                    }
                    Battery {
                        panelOpen: bar.batteryPanelOpen
                        onTogglePanel: bar.openDashboard(3)
                    }
                    PowerButton {
                        menuOpen: bar.powerMenuOpen
                        onToggleMenu: {
                            bar.shellState.powerMenuOpen = !bar.shellState.powerMenuOpen
                            bar.shellState.dashboardOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.shellState.menuOpen = false
                        }
                    }
                }
            }
        }
    }

    // ── Menu Panel ────────────────────────────────────────────────────────
    MenuPanel {
        open: bar.menuOpen
        onCloseRequested: bar.shellState.menuOpen = false
    }

    // ── Power Menu ────────────────────────────────────────────────────────
    LazyLoader {
        id: powerLoader
        active: bar.powerMenuOpen || powerCloseTimer.running

        PowerMenu {
            open: bar.powerMenuOpen
            onCloseRequested: bar.shellState.powerMenuOpen = false
            lockFn: bar.shellState ? bar.shellState.lockFn : function() {}
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
            requestedTab: bar.shellState ? bar.shellState.dashboardTab : 0
            requestedConnectTab: bar.shellState ? bar.shellState.dashboardConnectSubTab : 0
            dndActive: bar.shellState ? bar.shellState.dnd : false
            onCloseRequested: bar.shellState.dashboardOpen = false
            onScreenshotRequested: bar.takeScreenshot()
            onGrimRequested: bar.takeGrim()
            onRecorderToggleRequested: bar.toggleRecorder()
            onRecorderMicToggleRequested: bar.toggleRecorderMic()
            onSetFaceRequested: bar.startFacePicker()
            onNotifyRequested: (icon, summary, body) => bar.sendNotif(icon, summary, body)
            onTabSelectionChanged: {
                if (bar.shellState) bar.shellState.dashboardTab = index
            }
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

    // ── Wallpaper Panel ───────────────────────────────────────────────────
    LazyLoader {
        id: wallpaperLoader
        active: bar.wallpaperPanelOpen || wallpaperCloseTimer.running

        WallpaperPanel {
            open: bar.wallpaperPanelOpen
            onCloseRequested: bar.shellState.wallpaperPanelOpen = false
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
