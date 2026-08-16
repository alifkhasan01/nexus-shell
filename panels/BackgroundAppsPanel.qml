import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "../" as Root

Scope {
    id: scope
    property bool open: false
    signal closeRequested()

    // Refresh apps saat panel dibuka
    onOpenChanged: if (open) refreshApps()

    property var apps: []

    function refreshApps() {
        appsProc.running = true
    }

    function killApp(pid) {
        killProc.command = ["kill", "-15", pid]
        killProc.running = true
    }

    // Proses untuk mendapatkan daftar aplikasi background
    // Deteksi aplikasi GUI yang berjalan (memiliki window atau berjalan di background)
    Process {
        id: appsProc
        command: ["sh", "-c",
            // Gabungkan dua pendekatan:
            // 1. Aplikasi yang ada di /proc dengan environment DISPLAY (GUI apps)
            // 2. Filter out system services dan shell
            "for pid in /proc/[0-9]*; do " +
            "  [ -f \"$pid/environ\" ] || continue; " +
            "  grep -q \"DISPLAY\" \"$pid/environ\" 2>/dev/null || continue; " +
            "  [ -f \"$pid/cmdline\" ] || continue; " +
            "  cmd=$(tr '\\0' ' ' < \"$pid/cmdline\" 2>/dev/null | sed 's/ *$//'); " +
            "  [ -z \"$cmd\" ] && continue; " +
            "  pidnum=$(basename \"$pid\"); " +
            "  user=$(ps -o user= -p \"$pidnum\" 2>/dev/null); " +
            "  [ \"$user\" != \"$USER\" ] && continue; " +
            "  cpu=$(ps -o %cpu= -p \"$pidnum\" 2>/dev/null | tr -d ' '); " +
            "  mem=$(ps -o %mem= -p \"$pidnum\" 2>/dev/null | tr -d ' '); " +
            "  echo \"$pidnum|$cpu|$mem|$cmd\"; " +
            "done | " +
            "grep -v 'quickshell\\|/bin/bash\\|/bin/sh\\|/bin/zsh\\|/bin/fish\\|" +
            "kded\\|kwin\\|plasmashell\\|kglobalaccel\\|kscreen\\|baloo\\|akonadi\\|" +
            "xdg-desktop-portal\\|gvfsd\\|dconf-service\\|at-spi\\|" +
            "polkit\\|systemd\\|/usr/lib/\\|/usr/libexec/\\|" +
            "plasma\\|kactivitymanager\\|ksmserver' | " +
            "head -n 50"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.length > 0)
                const newApps = []
                
                // Daftar proses yang harus diabaikan (system services, helpers, dll)
                const ignorePatterns = [
                    /^sh$/i, /^bash$/i, /^zsh$/i, /^fish$/i,
                    /kded/i, /kwin/i, /plasma/i, /kglobalaccel/i, /kscreen/i,
                    /baloo/i, /akonadi/i, /kactivity/i, /ksmserver/i,
                    /xdg-desktop-portal/i, /gvfsd/i, /dconf-service/i, /at-spi/i,
                    /polkit/i, /systemd/i, /dbus/i,
                    /\/usr\/lib\//i, /\/usr\/libexec\//i,
                    /^agent$/i, /^helper$/i, /daemon$/i,
                    /\[/i, // kernel threads
                    /^cat$/i, /^tail$/i, /^sleep$/i, /^watch$/i, /^grep$/i
                ]
                
                // Map untuk nama aplikasi yang lebih friendly
                const appNameMap = {
                    'discord': 'Discord',
                    'slack': 'Slack',
                    'telegram': 'Telegram',
                    'telegram-desktop': 'Telegram',
                    'spotify': 'Spotify',
                    'steam': 'Steam',
                    'code': 'VS Code',
                    'firefox': 'Firefox',
                    'chromium': 'Chromium',
                    'chrome': 'Chrome',
                    'brave': 'Brave',
                    'vivaldi': 'Vivaldi',
                    'opera': 'Opera',
                    'qbittorrent': 'qBittorrent',
                    'transmission': 'Transmission',
                    'deluge': 'Deluge',
                    'syncthing': 'Syncthing',
                    'dropbox': 'Dropbox',
                    'nextcloud': 'Nextcloud',
                    'megasync': 'MEGAsync',
                    'insync': 'Insync',
                    'thunderbird': 'Thunderbird',
                    'evolution': 'Evolution',
                    'mailspring': 'Mailspring',
                    'signal-desktop': 'Signal',
                    'zoom': 'Zoom',
                    'teams': 'Teams',
                    'skype': 'Skype',
                    'kdeconnect': 'KDE Connect',
                    'gsconnect': 'GSConnect',
                    'flameshot': 'Flameshot',
                    'spectacle': 'Spectacle',
                    'copyq': 'CopyQ',
                    'keepassxc': 'KeePassXC',
                    'bitwarden': 'Bitwarden',
                    'solaar': 'Solaar',
                    'openrgb': 'OpenRGB',
                    'corectrl': 'CoreCtrl',
                    'blueman-applet': 'Bluetooth',
                    'nm-applet': 'Network',
                    'noisetorch': 'NoiseTorch',
                    'jamesdsp': 'JamesDSP',
                    'easyeffects': 'EasyEffects',
                    'vorta': 'Vorta',
                    'timeshift': 'Timeshift',
                    'dolphin': 'Dolphin',
                    'nautilus': 'Files',
                    'thunar': 'Thunar',
                    'konsole': 'Konsole',
                    'gnome-terminal': 'Terminal',
                    'kitty': 'Kitty',
                    'alacritty': 'Alacritty',
                    'gimp': 'GIMP',
                    'inkscape': 'Inkscape',
                    'krita': 'Krita',
                    'vlc': 'VLC',
                    'mpv': 'MPV'
                }
                
                const seen = new Set() // untuk menghindari duplikasi berdasarkan nama app
                
                for (const line of lines) {
                    const parts = line.split('|')
                    if (parts.length >= 4) {
                        const pid = parts[0].trim()
                        const cpu = parts[1].trim()
                        const mem = parts[2].trim()
                        const cmd = parts[3].trim()
                        
                        if (!cmd) continue
                        
                        // Ambil nama aplikasi (kata pertama dari command, tanpa path)
                        let appName = cmd.split(' ')[0].split('/').pop()
                        if (!appName) continue
                        
                        const appNameLower = appName.toLowerCase()
                        
                        // Skip jika match dengan ignore patterns
                        let shouldIgnore = false
                        for (const pattern of ignorePatterns) {
                            if (pattern.test(appNameLower) || pattern.test(cmd)) {
                                shouldIgnore = true
                                break
                            }
                        }
                        if (shouldIgnore) continue
                        
                        // Skip jika sudah ada (hindari duplikasi)
                        if (seen.has(appNameLower)) continue
                        seen.add(appNameLower)
                        
                        // Gunakan nama friendly jika ada
                        const displayName = appNameMap[appNameLower] || appName
                        
                        // Coba cari icon dari nama aplikasi
                        let iconName = appNameLower
                        
                        newApps.push({
                            pid: pid,
                            name: displayName,
                            fullCmd: cmd.length > 60 ? cmd.substring(0, 60) + "..." : cmd,
                            cpu: cpu + "%",
                            mem: mem + "%",
                            icon: iconName
                        })
                    }
                }
                
                scope.apps = newApps
            }
        }
    }

    Process {
        id: killProc
        onExited: refreshApps()
    }

    // Refresh otomatis setiap 5 detik saat panel terbuka
    Timer {
        running: scope.open
        repeat: true
        interval: 5000
        onTriggered: refreshApps()
    }

    PanelWindow {
        id: panel
        visible: scope.showPanel

        property bool showPanel: false

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell-background-apps"
        WlrLayershell.exclusiveZone: 0

        // Update showPanel berdasarkan open
        Connections {
            target: scope
            function onOpenChanged() {
                if (scope.open) {
                    panel.showPanel = true
                }
            }
        }

        // Klik di luar untuk tutup
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: scope.closeRequested()
        }

        Rectangle {
            id: panelRect
            
            // Posisi di kanan atas
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 5
            anchors.rightMargin: 100

            width: 480
            height: 600
            color: Root.Colors.base
            radius: 12
            border.width: 1
            border.color: Root.Colors.surface0

            // Animasi masuk/keluar
            opacity: 0
            scale: 0.95
            
            states: State {
                name: "visible"
                when: scope.open
                PropertyChanges { target: panelRect; opacity: 1; scale: 1 }
            }
            
            transitions: [
                Transition {
                    from: ""; to: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 150; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "visible"; to: ""
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; duration: 120; easing.type: Easing.InCubic }
                            NumberAnimation { property: "scale"; duration: 150; easing.type: Easing.InCubic }
                        }
                        ScriptAction { script: panel.showPanel = false }
                    }
                }
            ]

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: ""
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 20
                        color: Root.Colors.blue
                    }

                    Text {
                        text: "Background Apps"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: Root.Colors.text
                        Layout.fillWidth: true
                    }

                    // Tombol refresh
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: refreshArea.containsMouse 
                             ? Root.Colors.surface1 
                             : Root.Colors.surface0
                        
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 14
                            color: Root.Colors.text
                        }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: scope.refreshApps()
                        }
                    }

                    // Tombol close
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: closeArea.containsMouse 
                             ? Root.Colors.surface1 
                             : Root.Colors.surface0
                        
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 14
                            color: Root.Colors.red
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: scope.closeRequested()
                        }
                    }
                }

                // Info bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: Root.Colors.surface0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 13
                            color: Root.Colors.green
                        }

                        Text {
                            text: scope.apps.length + " aplikasi background"
                            font.pixelSize: 12
                            color: Root.Colors.text
                            Layout.fillWidth: true
                        }
                    }
                }

                // Apps list
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Root.Colors.mantle
                    radius: 10
                    border.width: 1
                    border.color: Root.Colors.surface0

                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.rightMargin: 20
                        contentHeight: appsColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: appsColumn
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: scope.apps

                                Rectangle {
                                    width: appsColumn.width - 8
                                    height: 72
                                    radius: 8
                                    color: itemArea.containsMouse 
                                         ? Root.Colors.surface1 
                                         : Root.Colors.surface0
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MouseArea {
                                        id: itemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        // Icon menggunakan system icon
                                        IconImage {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            source: modelData.icon 
                                                ? Quickshell.iconPath(modelData.icon, true) 
                                                : ""
                                            asynchronous: true
                                            
                                            // Fallback icon jika tidak ditemukan
                                            Rectangle {
                                                anchors.fill: parent
                                                visible: parent.source === ""
                                                radius: 20
                                                color: Qt.rgba(
                                                    Root.Colors.blue.r,
                                                    Root.Colors.blue.g,
                                                    Root.Colors.blue.b,
                                                    0.2
                                                )

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: ""
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.pixelSize: 18
                                                    color: Root.Colors.blue
                                                }
                                            }
                                        }

                                        // Info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: modelData.name
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: Root.Colors.text
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: modelData.fullCmd
                                                font.pixelSize: 10
                                                color: Root.Colors.subtext
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            RowLayout {
                                                spacing: 12

                                                Row {
                                                    spacing: 4
                                                    Text {
                                                        text: "󰘚"
                                                        font.family: "CaskaydiaCove Nerd Font"
                                                        font.pixelSize: 10
                                                        color: Root.Colors.yellow
                                                    }
                                                    Text {
                                                        text: modelData.cpu
                                                        font.pixelSize: 10
                                                        color: Root.Colors.text
                                                    }
                                                }

                                                Row {
                                                    spacing: 4
                                                    Text {
                                                        text: "󰍛"
                                                        font.family: "CaskaydiaCove Nerd Font"
                                                        font.pixelSize: 10
                                                        color: Root.Colors.green
                                                    }
                                                    Text {
                                                        text: modelData.mem
                                                        font.pixelSize: 10
                                                        color: Root.Colors.text
                                                    }
                                                }

                                                Text {
                                                    text: "PID: " + modelData.pid
                                                    font.pixelSize: 9
                                                    color: Root.Colors.subtext
                                                }
                                            }
                                        }

                                        // Kill button
                                        Rectangle {
                                            width: 36
                                            height: 36
                                            radius: 18
                                            color: killArea.containsMouse 
                                                 ? Root.Colors.red 
                                                 : Qt.rgba(
                                                     Root.Colors.red.r,
                                                     Root.Colors.red.g,
                                                     Root.Colors.red.b,
                                                     0.2
                                                 )
                                            
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: ""
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: 14
                                                color: killArea.containsMouse 
                                                     ? Root.Colors.base 
                                                     : Root.Colors.red
                                                
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: killArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: scope.killApp(modelData.pid)
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty state
                            Item {
                                visible: scope.apps.length === 0
                                width: parent.width
                                height: 200

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰂛"
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 48
                                        color: Root.Colors.overlay1
                                        opacity: 0.5
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Tidak ada aplikasi background"
                                        font.pixelSize: 12
                                        color: Root.Colors.text
                                    }
                                }
                            }
                        }
                    }

                    // Custom scrollbar
                    Rectangle {
                        visible: flickable.contentHeight > flickable.height
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        anchors.rightMargin: 4
                        width: 6
                        radius: 3
                        color: Root.Colors.surface1

                        Rectangle {
                            width: parent.width
                            height: Math.max(30, (flickable.height / flickable.contentHeight) * flickable.height)
                            y: (flickable.contentY / flickable.contentHeight) * flickable.height
                            radius: 3
                            color: Root.Colors.overlay0
                        }
                    }
                }

                // Footer dengan hint
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Root.Colors.surface0

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 11
                            color: Root.Colors.blue
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Klik"
                            font.pixelSize: 10
                            color: Root.Colors.text
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 4
                            color: Root.Colors.surface1
                            
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 9
                                color: Root.Colors.red
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "untuk menutup aplikasi"
                            font.pixelSize: 10
                            color: Root.Colors.text
                        }
                    }
                }
            }
        }
    }
}
