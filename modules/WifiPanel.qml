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

    // Tetap visible selama animasi tutup belum selesai
    property bool showPanel: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-wifi"
    WlrLayershell.exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── State ──────────────────────────────────────────────────────────────
    property bool wifiEnabled: false
    property bool scanning: false
    property string connectedSsid: ""
    property var networks: []   // [{ssid, signal, secured, connected}]

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        // Posisi: di bawah bar (bar = 45px + margin top 8px + gap 6px = 59px)
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 420
        // Tinggi adaptif: minimum 480px, max 720px atau layar - 70px
        height: Math.min(Math.max(headerHeight + listHeight + 32, minHeight), maxHeight)

        property int headerHeight: 56   // header + divider
        property int minHeight: 480
        property int maxHeight: Math.min(720, root.height - 70)
        property int listHeight: {
            if (!root.wifiEnabled) return minHeight - headerHeight - 32
            const count = root.networks.length
            if (count === 0) return minHeight - headerHeight - 32
            return count * 52 + (count - 1) * 2
        }

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi muncul / hilang ────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -20 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                NumberAnimation {
                    target: cardTranslate; property: "y"
                    duration: 220; easing.type: Easing.OutCubic
                }
                OpacityAnimator {
                    target: card
                    duration: 200; easing.type: Easing.OutCubic
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: cardTranslate; property: "y"
                            duration: 160; easing.type: Easing.InCubic
                        }
                        OpacityAnimator {
                            target: card
                            duration: 150; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Block clicks di dalam kartu dari overlay
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Header (tetap, tidak ikut scroll) ─────────────────────────────
        ColumnLayout {
            id: headerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.topMargin: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰖩  Wi-Fi"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Tombol scan
                Rectangle {
                    visible: root.wifiEnabled
                    width: 26; height: 26; radius: 8
                    color: root.scanning ? Root.Colors.blue : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.pixelSize: 13
                        color: root.scanning ? Root.Colors.base : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RotationAnimator on rotation {
                            running: root.scanning
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.scanning = true
                            scanProc.running = true
                        }
                    }
                }

                // Toggle WiFi on/off
                Rectangle {
                    width: 44; height: 26; radius: 13
                    color: root.wifiEnabled ? Root.Colors.blue : Root.Colors.surface1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        x: root.wifiEnabled ? parent.width - width - 4 : 4
                        y: 4; width: 18; height: 18; radius: 9
                        color: Root.Colors.base
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            toggleProc.command = ["sh", "-c",
                                root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
                            ]
                            toggleProc.running = true
                            root.wifiEnabled = !root.wifiEnabled
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // ── Scrollable network list ────────────────────────────────────────
        ScrollView {
            id: scrollArea
            anchors {
                top: headerCol.bottom
                topMargin: 6
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 12
            }
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ScrollBar.vertical: ScrollBar {
                width: 4
                anchors.right: parent.right
                anchors.rightMargin: 2
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 2
                    color: Root.Colors.surface2
                    opacity: parent.active ? 1.0 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                background: Rectangle { color: "transparent" }
            }

            // Pesan WiFi mati
            Text {
                visible: !root.wifiEnabled
                width: scrollArea.width
                horizontalAlignment: Text.AlignHCenter
                text: "Wi-Fi dimatikan"
                font.pixelSize: 12
                color: Root.Colors.subtext
                topPadding: 12; bottomPadding: 12
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Daftar jaringan
            ColumnLayout {
                visible: root.wifiEnabled
                width: scrollArea.width - 16
                x: 8
                spacing: 2

                Repeater {
                    model: root.networks

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: 12
                        color: modelData.connected
                               ? Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.15)
                               : (hoverMa.containsMouse ? Root.Colors.surface0 : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // Ikon sinyal
                            Text {
                                text: {
                                    if (modelData.signal >= 75) return "󰤨"
                                    if (modelData.signal >= 50) return "󰤥"
                                    if (modelData.signal >= 25) return "󰤢"
                                    return "󰤟"
                                }
                                font.pixelSize: 20
                                color: modelData.connected ? Root.Colors.blue : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // SSID + status
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                    font.pixelSize: 13
                                    font.bold: modelData.connected
                                    color: modelData.connected ? Root.Colors.blue : Root.Colors.text
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    visible: modelData.connected
                                    text: "Terhubung"
                                    font.pixelSize: 11
                                    color: Root.Colors.green
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            // Ikon kunci
                            Text {
                                visible: modelData.secured
                                text: "󰌾"
                                font.pixelSize: 11
                                color: Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Tombol connect / disconnect
                            Rectangle {
                                visible: hoverMa.containsMouse || modelData.connected
                                implicitWidth: connTxt.implicitWidth + 20
                                implicitHeight: 28
                                radius: 8
                                color: modelData.connected ? Root.Colors.surface1 : Root.Colors.blue
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: connTxt
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Putus" : "Hubung"
                                    font.pixelSize: 12
                                    color: modelData.connected ? Root.Colors.text : Root.Colors.base
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            disconnectProc.command = ["sh", "-c",
                                                "nmcli con down id '" + modelData.ssid + "'"
                                            ]
                                            disconnectProc.running = true
                                        } else {
                                            connectProc.command = ["sh", "-c",
                                                "nmcli dev wifi connect '" + modelData.ssid + "'"
                                            ]
                                            connectProc.running = true
                                        }
                                        Qt.callLater(() => { listProc.running = true })
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: hoverMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // Pesan kosong
                Text {
                    visible: root.wifiEnabled && root.networks.length === 0 && !root.scanning
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Tidak ada jaringan ditemukan"
                    font.pixelSize: 12
                    color: Root.Colors.subtext
                    topPadding: 8; bottomPadding: 8
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Pesan saat scanning
                Text {
                    visible: root.scanning
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Sedang scan…"
                    font.pixelSize: 12
                    color: Root.Colors.subtext
                    topPadding: 4; bottomPadding: 4
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }

    // ── Proses ────────────────────────────────────────────────────────────
    Process { id: toggleProc }
    Process { id: connectProc;    onRunningChanged: if (!running) listProc.running = true }
    Process { id: disconnectProc; onRunningChanged: if (!running) listProc.running = true }

    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 2"]
        onRunningChanged: {
            if (!running) {
                root.scanning = false
                listProc.running = true
            }
        }
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const seen = new Set()
                const result = []
                for (const line of lines) {
                    const inUse = line.startsWith("*")
                    const rest  = line.slice(1).replace(/^:/, "")
                    const parts = rest.split(":")
                    if (parts.length < 3) continue
                    const security = parts[parts.length - 1]
                    const signal   = parseInt(parts[parts.length - 2]) || 0
                    const ssid     = parts.slice(0, parts.length - 2).join(":").trim()
                    if (!ssid || seen.has(ssid)) continue
                    seen.add(ssid)
                    result.push({
                        ssid:      ssid,
                        signal:    signal,
                        secured:   security !== "" && security !== "--",
                        connected: inUse
                    })
                }
                result.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return b.signal - a.signal
                })
                root.networks = result
                const conn = result.find(n => n.connected)
                root.connectedSsid = conn ? conn.ssid : ""
            }
        }
    }

    onOpenChanged: {
        if (open) {
            showPanel = true
            statusProc.running = true
            listProc.running = true
        }
    }

    Timer {
        interval: 8000
        running: root.open && root.wifiEnabled
        repeat: true
        onTriggered: listProc.running = true
    }
}
