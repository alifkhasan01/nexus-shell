import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

PanelWindow {
    id: bar

    // State dashboard dibagikan dari shell.qml (bisa di-toggle lewat
    // global shortcut Hyprland ataupun klik jam).
    property var shellState: null
    property bool dashboardOpen: shellState ? shellState.dashboardOpen : false
    // powerMenuOpen dibaca dari shellState sehingga GlobalShortcut Hyprland
    // (quickshell:powermenu) dan klik tombol di Bar keduanya sinkron.
    property bool powerMenuOpen: shellState ? shellState.powerMenuOpen : false
    property bool wifiPanelOpen: false
    property bool btPanelOpen: false
    property bool volumePanelOpen: false
    property bool updatePanelOpen: false
    property bool wallpaperPanelOpen: shellState ? shellState.wallpaperPanelOpen : false

    onWifiPanelOpenChanged: if (!wifiPanelOpen) netStatus.refresh()
    onBtPanelOpenChanged: if (!btPanelOpen) btStatus.refresh()

    anchors { top: true; left: true; right: true }
    margins.top: 8
    margins.left: 10
    margins.right: 10

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
                        bar.wifiPanelOpen = false
                        bar.btPanelOpen   = false
                        bar.volumePanelOpen = false
                        bar.updatePanelOpen = false
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
                        panelOpen: bar.wifiPanelOpen
                        onTogglePanel: {
                            bar.wifiPanelOpen = !bar.wifiPanelOpen
                            bar.btPanelOpen   = false
                            bar.shellState.dashboardOpen = false
                            bar.volumePanelOpen = false
                            bar.updatePanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                        }
                    }

                    BluetoothStatus {
                        id: btStatus
                        panelOpen: bar.btPanelOpen
                        onTogglePanel: {
                            bar.btPanelOpen   = !bar.btPanelOpen
                            bar.wifiPanelOpen = false
                            bar.shellState.dashboardOpen = false
                            bar.volumePanelOpen = false
                            bar.updatePanelOpen = false
                            bar.shellState.wallpaperPanelOpen = false
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
                                text: "Wallpaper"
                                font.pixelSize: 11
                                color: Root.Colors.text
                            }
                        }

                        MouseArea {
                            id: wpArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.shellState.wallpaperPanelOpen = !bar.shellState.wallpaperPanelOpen
                                bar.wifiPanelOpen      = false
                                bar.btPanelOpen        = false
                                bar.volumePanelOpen    = false
                                bar.updatePanelOpen    = false
                                bar.shellState.dashboardOpen = false
                            }
                        }
                    }

                    SystemUpdate {
                        id: sysUpdate
                        panelOpen: bar.updatePanelOpen
                        onTogglePanel: {
                            bar.updatePanelOpen = !bar.updatePanelOpen
                            bar.wifiPanelOpen   = false
                            bar.btPanelOpen     = false
                            bar.volumePanelOpen = false
                            bar.shellState.dashboardOpen = false
                            bar.shellState.wallpaperPanelOpen = false
                        }
                    }

                    Volume {
                        id: volumeStatus
                        panelOpen: bar.volumePanelOpen
                        onTogglePanel: {
                            bar.volumePanelOpen = !bar.volumePanelOpen
                            bar.wifiPanelOpen  = false
                            bar.btPanelOpen    = false
                            bar.shellState.dashboardOpen = false
                            bar.updatePanelOpen = false
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
                            bar.wifiPanelOpen    = false
                            bar.btPanelOpen      = false
                            bar.volumePanelOpen  = false
                            bar.updatePanelOpen  = false
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
        active: true

        PowerMenu {
            open: bar.powerMenuOpen
            onCloseRequested: bar.shellState.powerMenuOpen = false
        }
    }

    // ── Dashboard ─────────────────────────────────────────────────────────
    LazyLoader {
        active: bar.dashboardOpen

        Dashboard {
            open: bar.dashboardOpen
            onCloseRequested: bar.shellState.dashboardOpen = false
            onScreenshotRequested: bar.takeScreenshot()
            onGrimRequested: bar.takeGrim()
            onRecorderToggleRequested: bar.toggleRecorder()
            onRecorderMicToggleRequested: bar.toggleRecorderMic()
        }
    }

    // ── WiFi Panel ────────────────────────────────────────────────────────
    LazyLoader {
        active: true

        WifiPanel {
            open: bar.wifiPanelOpen
            onCloseRequested: bar.wifiPanelOpen = false
        }
    }

    // ── Bluetooth Panel ───────────────────────────────────────────────────
    LazyLoader {
        active: true

        BluetoothPanel {
            open: bar.btPanelOpen
            onCloseRequested: bar.btPanelOpen = false
        }
    }

    // ── Volume Panel ──────────────────────────────────────────────────────
    LazyLoader {
        active: true

        VolumePanel {
            open: bar.volumePanelOpen
            onCloseRequested: bar.volumePanelOpen = false
        }
    }

    // ── Update Panel ──────────────────────────────────────────────────────
    LazyLoader {
        active: true

        UpdatePanel {
            open: bar.updatePanelOpen
            pending: sysUpdate.pending
            packages: sysUpdate.packages
            onCloseRequested: bar.updatePanelOpen = false
        }
    }

    // ── Wallpaper Panel ───────────────────────────────────────────────────
    LazyLoader {
        active: true

        WallpaperPanel {
            open: bar.wallpaperPanelOpen
            onCloseRequested: bar.shellState.wallpaperPanelOpen = false
        }
    }

    // ── Notification Popup ────────────────────────────────────────────────
    NotificationPopup {}

    // ── OSD (Volume & Brightness) ─────────────────────────────────────────
    Osd { id: osd }

    Process {
        id: controlCenterProcess
        command: ["control-center"]
    }

    // Screenshot — tinggal di Bar (persisten) supaya tidak ikut dihancurkan
    // saat Dashboard/LazyLoader ditutup, dan di-detach via setsid.
    Process {
        id: screenshotProc
        command: ["sh", "-c", "setsid -f bash ~/.config/quickshell/screenshot.sh </dev/null >/dev/null 2>&1"]
    }

    // Grim full-screen screenshot
    Process {
        id: grimProc
        command: ["sh", "-c",
            "setsid -f sh -c 'sleep 0.3; grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png' </dev/null >/dev/null 2>&1"]
    }

    // wf-recorder tanpa mic
    Process {
        id: recorderProc
        command: ["sh", "-c",
            "pgrep -x wf-recorder > /dev/null && pkill -INT wf-recorder || " +
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "setsid -f wf-recorder -f ~/Videos/Recordings/$(date +%Y%m%d_%H%M%S).mp4 </dev/null >/dev/null 2>&1 &"]
    }

    // wf-recorder dengan mic — query default source dulu via pactl agar
    // tidak bergantung pada auto-detect yang bisa gagal di child process.
    // Pakai --audio-backend=pipewire + opus codec di mkv untuk menghindari
    // suara kres di awal (AAC punya priming delay, opus tidak).
    Process {
        id: recorderMicProc
        command: ["sh", "-c",
            "pgrep -x wf-recorder > /dev/null && pkill -INT wf-recorder || { " +
            "DEV=$(XDG_RUNTIME_DIR=/run/user/$(id -u) pactl get-default-source 2>/dev/null); " +
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "setsid -f wf-recorder --audio-backend=pipewire --audio=${DEV:-default} " +
            "-C libopus -R 48000 " +
            "-f ~/Videos/Recordings/$(date +%Y%m%d_%H%M%S).mkv </dev/null >/dev/null 2>&1 & }"]
    }

    function takeScreenshot()       { screenshotProc.running = true }
    function takeGrim()             { grimProc.running = true }
    function toggleRecorder()       { recorderProc.running = true }
    function toggleRecorderMic()    { recorderMicProc.running = true }
}
