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
    property bool wifiPanelOpen: false
    property bool btPanelOpen: false
    property bool volumePanelOpen: false
    property bool updatePanelOpen: false
    property bool wallpaperPanelOpen: shellState ? shellState.wallpaperPanelOpen : false

    onWifiPanelOpenChanged: {
        if (!wifiPanelOpen) wifiCloseTimer.restart()
        if (!wifiPanelOpen) netStatus.refresh()
    }
    onBtPanelOpenChanged: {
        if (!btPanelOpen) btCloseTimer.restart()
        if (!btPanelOpen) btStatus.refresh()
    }
    onVolumePanelOpenChanged:    if (!volumePanelOpen)    volumeCloseTimer.restart()
    onUpdatePanelOpenChanged:    if (!updatePanelOpen)    updateCloseTimer.restart()
    onWallpaperPanelOpenChanged: if (!wallpaperPanelOpen) wallpaperCloseTimer.restart()
    onPowerMenuOpenChanged:      if (!powerMenuOpen)      powerCloseTimer.restart()

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
                                    bar.shellState.randomWallpaperConsumed = false
                                    bar.shellState.randomWallpaperToken += 1
                                } else {
                                    bar.shellState.wallpaperPanelOpen = !bar.shellState.wallpaperPanelOpen
                                    bar.wifiPanelOpen      = false
                                    bar.btPanelOpen        = false
                                    bar.volumePanelOpen    = false
                                    bar.updatePanelOpen    = false
                                    bar.shellState.dashboardOpen = false
                                }
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
        id: powerLoader
        active: bar.powerMenuOpen || powerCloseTimer.running

        Timer {
            id: powerCloseTimer
            interval: 300
            repeat: false
        }

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
        }
    }

    // ── WiFi Panel ────────────────────────────────────────────────────────
    LazyLoader {
        id: wifiLoader
        active: bar.wifiPanelOpen || wifiCloseTimer.running

        Timer {
            id: wifiCloseTimer
            interval: 300
            repeat: false
        }

        WifiPanel {
            open: bar.wifiPanelOpen
            onCloseRequested: bar.wifiPanelOpen = false
        }
    }

    // ── Bluetooth Panel ───────────────────────────────────────────────────
    LazyLoader {
        id: btLoader
        active: bar.btPanelOpen || btCloseTimer.running

        Timer {
            id: btCloseTimer
            interval: 300
            repeat: false
        }

        BluetoothPanel {
            open: bar.btPanelOpen
            onCloseRequested: bar.btPanelOpen = false
        }
    }

    // ── Volume Panel ──────────────────────────────────────────────────────
    LazyLoader {
        id: volumeLoader
        active: bar.volumePanelOpen || volumeCloseTimer.running

        Timer {
            id: volumeCloseTimer
            interval: 300
            repeat: false
        }

        VolumePanel {
            open: bar.volumePanelOpen
            onCloseRequested: bar.volumePanelOpen = false
        }
    }

    // ── Update Panel ──────────────────────────────────────────────────────
    LazyLoader {
        id: updateLoader
        active: bar.updatePanelOpen || updateCloseTimer.running

        Timer {
            id: updateCloseTimer
            interval: 300
            repeat: false
        }

        UpdatePanel {
            open: bar.updatePanelOpen
            pending: sysUpdate.pending
            packages: sysUpdate.packages
            onCloseRequested: bar.updatePanelOpen = false
        }
    }

    // ── Wallpaper Panel ───────────────────────────────────────────────────
    LazyLoader {
        id: wallpaperLoader
        active: bar.wallpaperPanelOpen || wallpaperCloseTimer.running

        Timer {
            id: wallpaperCloseTimer
            interval: 300
            repeat: false
        }

        WallpaperPanel {
            open: bar.wallpaperPanelOpen
            shellState: bar.shellState
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

    // Screenshot — di-detach via setsid supaya tidak ikut mati saat reload.
    Process {
        id: screenshotProc
        command: ["sh", "-c", "setsid -f bash ~/.config/quickshell/scripts/screenshot.sh </dev/null >/dev/null 2>&1"]
    }

    // Grim full-screen screenshot
    Process {
        id: grimProc
        command: ["sh", "-c",
            "setsid -f sh -c 'sleep 0.3; grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png' </dev/null >/dev/null 2>&1"]
    }

    // wf-recorder — desktop + mic gabungan
    Process {
        id: recorderProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh both"]
    }

    // wf-recorder — desktop only
    Process {
        id: recorderMicProc
        command: ["sh", "-c",
            "env XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=$WAYLAND_DISPLAY " +
            "bash ~/.config/quickshell/scripts/record.sh desktop-only"]
    }

    function takeScreenshot()    { screenshotProc.running = true }
    function takeGrim()          { grimProc.running = true }
    function toggleRecorder()    { recorderProc.running = true }
    function toggleRecorderMic() { recorderMicProc.running = true }
}
