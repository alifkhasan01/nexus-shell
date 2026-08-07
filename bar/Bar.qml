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
    property bool wallpaperPanelOpen: shellState ? shellState.wallpaperPanelOpen : false

    onConnectPanelOpenChanged: {
        if (!connectPanelOpen) connectCloseTimer.restart()
        if (!connectPanelOpen) netStatus.refresh()
        if (!connectPanelOpen) btStatus.refresh()
    }
    onVolumePanelOpenChanged:    if (!volumePanelOpen)    volumeCloseTimer.restart()
    onWallpaperPanelOpenChanged: if (!wallpaperPanelOpen) wallpaperCloseTimer.restart()
    onPowerMenuOpenChanged:      if (!powerMenuOpen)      powerCloseTimer.restart()

    // ── Close timers — di root agar selalu tersedia ───────────────────────
    Timer { id: powerCloseTimer;    interval: 300; repeat: false }
    Timer { id: connectCloseTimer;  interval: 300; repeat: false }
    Timer { id: volumeCloseTimer;   interval: 300; repeat: false }
    Timer { id: wallpaperCloseTimer; interval: 300; repeat: false }

    anchors { top: true; left: true; right: true }
    margins.top: 2
    margins.left: 4
    margins.right: 4

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

                Clock {
                    anchors.centerIn: parent
                    onClicked: {
                        bar.shellState.dashboardOpen = !bar.shellState.dashboardOpen
                        bar.connectPanelOpen = false
                        bar.volumePanelOpen = false
                        bar.shellState.wallpaperPanelOpen = false
                    }
                    onRightClicked: controlCenterProcess.running = true
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

                    NetworkStatus {
                        id: netStatus
                        panelOpen: bar.connectPanelOpen && bar.connectTab === 0
                        onTogglePanel: {
                            bar.connectTab = 0
                            bar.connectPanelOpen = !bar.connectPanelOpen
                            bar.shellState.dashboardOpen = false
                            bar.volumePanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
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
                        }
                        onToggleBt: {} // handled inside BluetoothStatus widget
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

                        // Tooltip
                        Rectangle {
                            visible: wpArea.containsMouse
                            z: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 6
                            implicitWidth: wpTip.implicitWidth + 16
                            height: 22
                            radius: 6
                            color: Root.Colors.surface2
                            border.color: Root.Colors.surface1
                            border.width: 1
                            Text {
                                id: wpTip
                                anchors.centerIn: parent
                                text: "Wallpaper  ·  klik kanan: acak"
                                font.pixelSize: 11
                                color: Root.Colors.text
                            }
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
                        }
                        onOsdVolume: (value, muted) => osd.showVolume(value, muted)
                    }

                    Brightness {
                        onOsdBrightness: value => osd.showBrightness(value)
                    }
                    Battery {}
                    PowerButton {
                        menuOpen: bar.powerMenuOpen
                        onToggleMenu: {
                            bar.shellState.powerMenuOpen = !bar.shellState.powerMenuOpen
                            bar.connectPanelOpen  = false
                            bar.volumePanelOpen  = false
                            bar.shellState.wallpaperPanelOpen = false
                            bar.shellState.dashboardOpen = false
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
    LazyLoader {
        active: bar.dashboardOpen

        Dash.Dashboard {
            open: bar.dashboardOpen
            onCloseRequested: bar.shellState.dashboardOpen = false
            onScreenshotRequested: bar.takeScreenshot()
            onGrimRequested: bar.takeGrim()
            onRecorderToggleRequested: bar.toggleRecorder()
            onRecorderMicToggleRequested: bar.toggleRecorderMic()
            onSetFaceRequested: bar.startFacePicker()
            onNotifyRequested: (icon, summary, body) => bar.sendNotif(icon, summary, body)
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

    // Screenshot select (area) — grimblast tanpa detach agar bisa notif setelah selesai
    Process {
        id: screenshotProc
        command: ["sh", "-c",
            "mkdir -p ~/Pictures/Screenshots && " +
            "grimblast save area ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png 2>/dev/null"]
        onRunningChanged: {
            if (!running && exitCode === 0)
                bar.sendNotif("camera-photo", "Screenshot Tersimpan",
                    "Disimpan di ~/Pictures/Screenshots")
        }
    }

    // Screenshot full — grimblast tanpa detach, delay via timer agar dashboard hilang dulu
    Process {
        id: grimProc
        command: ["sh", "-c",
            "mkdir -p ~/Pictures/Screenshots && " +
            "grimblast save screen ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png 2>/dev/null"]
        onRunningChanged: {
            if (!running && exitCode === 0)
                bar.sendNotif("camera-photo", "Screenshot Tersimpan",
                    "Disimpan di ~/Pictures/Screenshots")
        }
    }

    Timer {
        id: grimDelayTimer
        interval: 500
        repeat: false
        onTriggered: grimProc.running = true
    }

    // wf-recorder — desktop only (left click, default)
    Process {
        id: recorderProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh desktop-only"]
        onRunningChanged: {
            if (!running) {
                // Script selesai — cek apakah ini stop (wf-recorder sudah tidak jalan)
                recNotifCheckProc.running = true
            }
        }
    }

    // wf-recorder — desktop + mic gabungan (right click)
    Process {
        id: recorderMicProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh both"]
        onRunningChanged: {
            if (!running) {
                recNotifCheckProc.running = true
            }
        }
    }

    // Cek apakah wf-recorder masih jalan setelah script selesai
    // Kalau tidak jalan = baru saja stop → kirim notif file tersimpan
    Process {
        id: recNotifCheckProc
        command: ["sh", "-c", "pgrep -x wf-recorder > /dev/null && echo running || echo stopped"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "stopped")
                    bar.sendNotif("media-record", "Recording Tersimpan",
                        "File disimpan di ~/Videos/Recordings")
            }
        }
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
