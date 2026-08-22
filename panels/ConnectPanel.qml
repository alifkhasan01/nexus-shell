import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

// Panel Wi-Fi + Bluetooth dalam satu window (desain dua-tab seperti VolumePanel).
//   Tab "Wi-Fi"     : daftar jaringan + toggle + scan
//   Tab "Bluetooth" : daftar perangkat + toggle + scan
// Dibuka dari bar (satu panel saja, tab dipilih lewat bar.connectTab).
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
            root.currentTab = root.requestedTab
            wifiStatusProc.running = true
            wifiListProc.running = true
            btStatusProc.running = true
            btListProc.running = true
        } else {
            // Reset state password saat panel ditutup
            root.pendingSsid = ""
            root.pendingPassword = ""
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-connect"
    WlrLayershell.exclusiveZone: 0

    // Klik luar untuk tutup
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── Tab state ──────────────────────────────────────────────────────────
    property int currentTab: 0  // 0 = Wi-Fi, 1 = Bluetooth
    property int requestedTab: 0

    // ── State Wi-Fi ────────────────────────────────────────────────────────
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property string connectedSsid: ""
    property var wifiNetworks: []   // [{ssid, signal, secured, connected}]

    // Input password inline
    property string pendingSsid: ""      // SSID yang sedang menunggu password
    property string pendingPassword: ""  // Password sementara yang diketik

    // ── State Bluetooth ────────────────────────────────────────────────────
    property bool btEnabled: false
    property bool btScanning: false
    property var btDevices: []   // [{name, address, connected, paired}]

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 100

        width: 420
        // Tinggi adaptif: ikuti isi tab aktif, tapi dibatasi layar
        height: Math.min(Math.max(headerH + contentH + 40, 300), maxHeight)

        property int headerH: 52
        property int maxHeight: Math.min(720, root.height - 70)
        property int contentH: {
            if (root.currentTab === 0) {
                if (!root.wifiEnabled) return 260
                const count = root.wifiNetworks.length
                if (count === 0) return 260
                return count * 52 + (count - 1) * 2
            }
            if (!root.btEnabled) return 260
            if (root.btDevices.length === 0) return 260
            const paired = root.btDevices.filter(d => d.paired).length
            const avail  = root.btDevices.filter(d => !d.paired).length
            let h = 0
            if (paired > 0) h += 28 + paired * 54 + 6
            if (avail  > 0) h += 28 + avail  * 54
            return Math.max(h, 260)
        }

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi muncul / hilang ────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -50 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
                    OpacityAnimator { target: card; duration: Root.Appearance.animation.elementMoveEnter.duration }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
                        OpacityAnimator { target: card; duration: Root.Appearance.animation.elementMoveExit.duration }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

        // Blokir klik di dalam kartu
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 12
            spacing: 8

            // ── Header + tab bar ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 0

                Text {
                    text: root.currentTab === 0 ? "󰖩  Wi-Fi" : "󰂯  Bluetooth"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }

                Item { Layout.fillWidth: true }

                // Tab bar (pola VolumePanel)
                Rectangle {
                    id: tabBar
                    width: tabRow.implicitWidth + 6
                    height: 28
                    radius: 8
                    color: Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: ["Wi-Fi", "Bluetooth"]

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: tabLbl.implicitWidth + 16
                                height: 22
                                radius: 6
                                color: root.currentTab === index
                                    ? Root.Colors.surface2
                                    : (tabMa.containsMouse ? Root.Colors.surface1 : "transparent")
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                Text {
                                    id: tabLbl
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 11
                                    font.bold: root.currentTab === index
                                    color: root.currentTab === index ? Root.Colors.text : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }

                                MouseArea {
                                    id: tabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = index
                                }
                            }
                        }
                    }
                }
            }

            // ── Divider ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
            }

            // ── Konten tab ─────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ══════ TAB 0: WI-FI ══════════════════════════════════════
                ColumnLayout {
                    id: wifiCol
                    anchors.fill: parent
                    spacing: 6
                    opacity: root.currentTab === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    // Toolbar: spacer + scan + toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        // Scan
                        Rectangle {
                            width: 26; height: 26; radius: 8
                            visible: root.wifiEnabled
                            color: root.wifiScanning ? Root.Colors.blue : Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                font.pixelSize: 13
                                color: root.wifiScanning ? Root.Colors.base : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                RotationAnimator on rotation {
                                    running: root.wifiScanning
                                    from: 0; to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.wifiScanning = true
                                    wifiScanProc.running = true
                                }
                            }
                        }

                        // Toggle Wi-Fi
                        Rectangle {
                            width: 44; height: 26; radius: 13
                            color: root.wifiEnabled ? Root.Colors.blue : Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                x: root.wifiEnabled ? parent.width - width - 4 : 4
                                y: 4; width: 18; height: 18; radius: 9
                                color: Root.Colors.base
                                Behavior on x { NumberAnimation { duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMove.type; easing.bezierCurve: Root.Appearance.animation.elementMove.bezierCurve } }
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wifiToggleProc.command = ["sh", "-c",
                                        root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
                                    ]
                                    wifiToggleProc.running = true
                                    root.wifiEnabled = !root.wifiEnabled
                                }
                            }
                        }
                    }

                    // Daftar jaringan
                    ScrollView {
                        id: wifiScrollArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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
                                Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                            background: Rectangle { color: "transparent" }
                        }

                        // Pesan Wi-Fi mati
                        Text {
                            visible: !root.wifiEnabled
                            width: wifiScrollArea.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Wi-Fi dimatikan"
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            topPadding: 12; bottomPadding: 12
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }

                        ColumnLayout {
                            visible: root.wifiEnabled
                            width: wifiScrollArea.width - 16
                            x: 8
                            spacing: 2

                            Repeater {
                                model: root.wifiNetworks

                                delegate: Rectangle {
                                    id: netItem
                                    Layout.fillWidth: true
                                    // tinggi normal 52, melebar saat input password muncul
                                    implicitHeight: pwRow.visible ? 52 + pwRow.implicitHeight + 8 : 52
                                    Behavior on implicitHeight { NumberAnimation { duration: Root.Appearance.animation.elementResize.duration; easing.type: Root.Appearance.animation.elementMove.type; easing.bezierCurve: Root.Appearance.animation.elementMove.bezierCurve } }

                                    readonly property bool isPending: root.pendingSsid === modelData.ssid

                                    radius: 12
                                    color: modelData.connected
                                           ? Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.15)
                                           : (hoverMa.containsMouse ? Root.Colors.surface0 : "transparent")
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                    // ── Baris utama ───────────────────────────────
                                    RowLayout {
                                        id: mainRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        height: 52
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
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                            }
                                            Text {
                                                visible: modelData.connected
                                                text: "Terhubung"
                                                font.pixelSize: 11
                                                color: Root.Colors.green
                                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                            }
                                        }

                                        // Ikon kunci
                                        Text {
                                            visible: modelData.secured
                                            text: "󰌾"
                                            font.pixelSize: 11
                                            color: Root.Colors.subtext
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                        }

                                        // Tombol connect / disconnect / batal
                                        Rectangle {
                                            visible: hoverMa.containsMouse || modelData.connected || netItem.isPending
                                            implicitWidth: connTxt.implicitWidth + 20
                                            implicitHeight: 28
                                            radius: 8
                                            color: (modelData.connected || netItem.isPending)
                                                   ? Root.Colors.surface1 : Root.Colors.blue
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                            Text {
                                                id: connTxt
                                                anchors.centerIn: parent
                                                text: modelData.connected ? "Putus"
                                                    : netItem.isPending    ? "Batal"
                                                    : "Hubung"
                                                font.pixelSize: 12
                                                color: (modelData.connected || netItem.isPending)
                                                       ? Root.Colors.text : Root.Colors.base
                                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.connected) {
                                                        // Putuskan koneksi
                                                        wifiDisconnectProc.command = ["sh", "-c",
                                                            "nmcli con down id '" + modelData.ssid + "'"
                                                        ]
                                                        wifiDisconnectProc.running = true
                                                        Qt.callLater(() => { wifiListProc.running = true })
                                                    } else if (netItem.isPending) {
                                                        // Batalkan input password
                                                        root.pendingSsid = ""
                                                        root.pendingPassword = ""
                                                    } else if (modelData.secured) {
                                                        // Jaringan ber-password: buka input inline
                                                        root.pendingSsid = modelData.ssid
                                                        root.pendingPassword = ""
                                                        Qt.callLater(() => pwField.forceActiveFocus())
                                                    } else {
                                                        // Jaringan terbuka: langsung konek
                                                        wifiConnectProc.connectTo(modelData.ssid, "")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── Baris input password (inline) ─────────────
                                    RowLayout {
                                        id: pwRow
                                        visible: netItem.isPending
                                        opacity: netItem.isPending ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: mainRow.bottom
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 0
                                        implicitHeight: 40
                                        spacing: 6

                                        // Field password
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 8
                                            color: Root.Colors.surface0
                                            border.color: pwField.activeFocus ? Root.Colors.blue : Root.Colors.surface2
                                            border.width: 1
                                            Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 6
                                                spacing: 6

                                                TextInput {
                                                    id: pwField
                                                    Layout.fillWidth: true
                                                    echoMode: showPw ? TextInput.Normal : TextInput.Password
                                                    color: Root.Colors.text
                                                    font.pixelSize: 13
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    clip: true
                                                    selectByMouse: true

                                                    property bool showPw: false

                                                    // Sync ke pendingPassword
                                                    onTextChanged: root.pendingPassword = text

                                                    // Enter = sambung
                                                    Keys.onReturnPressed:  connectBtn.doConnect()
                                                    Keys.onEnterPressed:   connectBtn.doConnect()
                                                    // Escape = batal
                                                    Keys.onEscapePressed: {
                                                        root.pendingSsid = ""
                                                        root.pendingPassword = ""
                                                    }

                                                    // placeholder
                                                    Text {
                                                        visible: pwField.text.length === 0 && !pwField.activeFocus
                                                        anchors.fill: parent
                                                        text: "Kata sandi…"
                                                        font.pixelSize: 13
                                                        color: Root.Colors.overlay0
                                                        verticalAlignment: Text.AlignVCenter
                                                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                                    }

                                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                                }

                                                // Toggle tampilkan/sembunyikan password
                                                Text {
                                                    text: pwField.showPw ? "󰛑" : "󰛐"
                                                    font.pixelSize: 14
                                                    color: Root.Colors.subtext
                                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: pwField.showPw = !pwField.showPw
                                                    }
                                                }
                                            }
                                        }

                                        // Tombol sambung
                                        Rectangle {
                                            id: connectBtn
                                            implicitWidth: sambTxt.implicitWidth + 20
                                            height: 32
                                            radius: 8
                                            color: root.pendingPassword.length >= 8
                                                   ? Root.Colors.blue : Root.Colors.surface1
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                            function doConnect() {
                                                if (root.pendingPassword.length < 1) return
                                                wifiConnectProc.connectTo(root.pendingSsid, root.pendingPassword)
                                                root.pendingSsid = ""
                                                root.pendingPassword = ""
                                            }

                                            Text {
                                                id: sambTxt
                                                anchors.centerIn: parent
                                                text: "Sambung"
                                                font.pixelSize: 12
                                                color: root.pendingPassword.length >= 8
                                                       ? Root.Colors.base : Root.Colors.subtext
                                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: connectBtn.doConnect()
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
                                visible: root.wifiEnabled && root.wifiNetworks.length === 0 && !root.wifiScanning
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: "Tidak ada jaringan ditemukan"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                topPadding: 8; bottomPadding: 8
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            // Pesan saat scanning
                            Text {
                                visible: root.wifiScanning
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: "Sedang scan…"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                topPadding: 4; bottomPadding: 4
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                        }
                    }
                }

                // ══════ TAB 1: BLUETOOTH ══════════════════════════════════
                ColumnLayout {
                    id: btCol
                    anchors.fill: parent
                    spacing: 6
                    opacity: root.currentTab === 1 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    // Toolbar: spacer + scan + toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        // Scan
                        Rectangle {
                            width: 26; height: 26; radius: 8
                            visible: root.btEnabled
                            color: root.btScanning ? Root.Colors.blue : Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                font.pixelSize: 13
                                color: root.btScanning ? Root.Colors.base : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                RotationAnimator on rotation {
                                    running: root.btScanning
                                    from: 0; to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.btScanning = true
                                    btScanProc.running = true
                                }
                            }
                        }

                        // Toggle BT
                        Rectangle {
                            width: 44; height: 26; radius: 13
                            color: root.btEnabled ? Root.Colors.blue : Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                x: root.btEnabled ? parent.width - width - 4 : 4
                                y: 4; width: 18; height: 18; radius: 9
                                color: Root.Colors.base
                                Behavior on x { NumberAnimation { duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMove.type; easing.bezierCurve: Root.Appearance.animation.elementMove.bezierCurve } }
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    btToggleProc.command = ["sh", "-c",
                                        root.btEnabled ? "bluetoothctl power off" : "bluetoothctl power on"
                                    ]
                                    btToggleProc.running = true
                                    root.btEnabled = !root.btEnabled
                                }
                            }
                        }
                    }

                    // Daftar perangkat
                    ScrollView {
                        id: btScrollArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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
                                Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                            background: Rectangle { color: "transparent" }
                        }

                        // Pesan BT mati
                        Text {
                            visible: !root.btEnabled
                            width: btScrollArea.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Bluetooth dimatikan"
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            topPadding: 12; bottomPadding: 12
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }

                        ColumnLayout {
                            visible: root.btEnabled
                            width: btScrollArea.width - 16
                            x: 8
                            spacing: 2

                            // Sub-header: Terpasang
                            Text {
                                visible: root.btDevices.some(d => d.paired)
                                text: "TERPASANG"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Root.Colors.subtext
                                leftPadding: 4
                                topPadding: 2
                                bottomPadding: 2
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            Repeater {
                                model: root.btDevices.filter(d => d.paired)
                                delegate: BtDeviceRow {
                                    Layout.fillWidth: true
                                    deviceData: modelData
                                    onConnectRequested:    addr => btConnectProc.connectDevice(addr)
                                    onDisconnectRequested: addr => btDisconnectProc.disconnectDevice(addr)
                                    onRemoveRequested:     addr => btRemoveProc.removeDevice(addr)
                                }
                            }

                            // Sub-header: Tersedia
                            Text {
                                visible: root.btDevices.some(d => !d.paired)
                                text: "TERSEDIA"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Root.Colors.subtext
                                leftPadding: 4
                                topPadding: 6
                                bottomPadding: 2
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            Repeater {
                                model: root.btDevices.filter(d => !d.paired)
                                delegate: BtDeviceRow {
                                    Layout.fillWidth: true
                                    deviceData: modelData
                                    onConnectRequested:    addr => btConnectProc.connectDevice(addr)
                                    onDisconnectRequested: addr => btDisconnectProc.disconnectDevice(addr)
                                    onRemoveRequested:     addr => btRemoveProc.removeDevice(addr)
                                }
                            }

                            // Pesan kosong
                            Text {
                                visible: root.btEnabled && root.btDevices.length === 0 && !root.btScanning
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: "Tidak ada perangkat\nKlik  untuk scan"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                topPadding: 8; bottomPadding: 8
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }

                            // Pesan saat scanning
                            Text {
                                visible: root.btScanning
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: "Sedang scan…"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                                topPadding: 4; bottomPadding: 4
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Komponen baris perangkat bluetooth ────────────────────────────────
    component BtDeviceRow: Rectangle {
        id: devRow

        property var deviceData: ({})
        signal connectRequested(string addr)
        signal disconnectRequested(string addr)
        signal removeRequested(string addr)

        implicitHeight: 54
        radius: 12
        color: deviceData.connected
               ? Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.15)
               : (rowHover.containsMouse ? Root.Colors.surface0 : "transparent")
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Ikon tipe perangkat
            Text {
                text: {
                    const n = (deviceData.name || "").toLowerCase()
                    if (n.includes("headphone") || n.includes("earphone") || n.includes("buds"))
                        return "󰋋"
                    if (n.includes("keyboard")) return "󰌌"
                    if (n.includes("mouse"))    return "󰍽"
                    if (n.includes("speaker") || n.includes("sound")) return "󰓃"
                    if (n.includes("phone"))    return "󰏲"
                    if (n.includes("watch"))    return "󱑔"
                    return "󰂯"
                }
                font.pixelSize: 22
                color: deviceData.connected ? Root.Colors.blue : Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: deviceData.name || deviceData.address || "Unknown"
                    font.pixelSize: 13
                    font.bold: deviceData.connected
                    color: deviceData.connected ? Root.Colors.blue : Root.Colors.text
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }
                Text {
                    visible: deviceData.connected
                    text: "Terhubung"
                    font.pixelSize: 11
                    color: Root.Colors.green
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }
            }

            // Tombol aksi (muncul saat hover atau connected)
            RowLayout {
                visible: rowHover.containsMouse || deviceData.connected
                spacing: 4

                Rectangle {
                    implicitWidth: actTxt.implicitWidth + 20
                    implicitHeight: 28
                    radius: 8
                    color: deviceData.connected ? Root.Colors.surface1 : Root.Colors.blue
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    Text {
                        id: actTxt
                        anchors.centerIn: parent
                        text: deviceData.connected ? "Putus" : "Hubung"
                        font.pixelSize: 12
                        color: deviceData.connected ? Root.Colors.text : Root.Colors.base
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (deviceData.connected)
                                devRow.disconnectRequested(deviceData.address)
                            else
                                devRow.connectRequested(deviceData.address)
                        }
                    }
                }

                // Hapus (unpair)
                Rectangle {
                    visible: deviceData.paired && rowHover.containsMouse
                    width: 24; height: 24; radius: 7
                    color: Root.Colors.surface1
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        font.pixelSize: 12
                        color: Root.Colors.red
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: devRow.removeRequested(deviceData.address)
                    }
                }
            }
        }

        MouseArea {
            id: rowHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    // ── Proses Wi-Fi ──────────────────────────────────────────────────────
    Process { id: wifiToggleProc }

    Process {
        id: wifiConnectProc
        // Hubungkan ke SSID dengan atau tanpa password
        function connectTo(ssid, password) {
            if (password.length > 0) {
                command = ["sh", "-c",
                    "nmcli dev wifi connect '" + ssid + "' password '" + password + "' 2>/dev/null"
                ]
            } else {
                command = ["sh", "-c",
                    "nmcli dev wifi connect '" + ssid + "' 2>/dev/null"
                ]
            }
            running = true
        }
        onRunningChanged: if (!running) wifiListProc.running = true
    }

    Process { id: wifiDisconnectProc; onRunningChanged: if (!running) wifiListProc.running = true }

    Process {
        id: wifiScanProc
        command: ["sh", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 2"]
        onRunningChanged: {
            if (!running) {
                root.wifiScanning = false
                wifiListProc.running = true
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["sh", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiListProc
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
                root.wifiNetworks = result
                const conn = result.find(n => n.connected)
                root.connectedSsid = conn ? conn.ssid : ""
            }
        }
    }

    // ── Proses Bluetooth ──────────────────────────────────────────────────

    // Nama perangkat terakhir yang diaksi (untuk notifikasi)
    property string _lastDeviceName: ""

    Process {
        id: btToggleProc
        onRunningChanged: {
            if (!running) {
                btStatusProc.running = true
                btNotifyProc.command = root.btEnabled
                    ? ["notify-send", "-a", "Bluetooth", "-i", "bluetooth-active-symbolic", "-t", "3000", "Bluetooth aktif", "Bluetooth telah dinyalakan."]
                    : ["notify-send", "-a", "Bluetooth", "-i", "bluetooth-disabled-symbolic", "-t", "3000", "Bluetooth nonaktif", "Bluetooth telah dimatikan."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: btScanProc
        command: ["sh", "-c", "bluetoothctl --timeout 8 scan on 2>/dev/null; echo done"]
        onRunningChanged: {
            if (!running) {
                root.btScanning = false
                btListProc.running = true
            }
        }
    }

    Process {
        id: btConnectProc
        function connectDevice(addr) {
            root._lastDeviceName = (root.btDevices.find(d => d.address === addr) || {}).name || addr
            command = ["sh", "-c", [
                "timeout 6 bluetoothctl pair " + addr + " 2>/dev/null;",
                "timeout 5 bluetoothctl trust " + addr + " 2>/dev/null;",
                "timeout 20 bluetoothctl connect " + addr + " 2>/dev/null;",
                "echo done"
            ].join(" ")]
            running = true
        }
        onRunningChanged: {
            if (!running) {
                btListProc.running = true
                btNotifyProc.command = ["notify-send", "-a", "Bluetooth",
                    "-i", "bluetooth-active-symbolic", "-t", "3000",
                    "Terhubung", root._lastDeviceName + " berhasil dihubungkan."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: btDisconnectProc
        function disconnectDevice(addr) {
            root._lastDeviceName = (root.btDevices.find(d => d.address === addr) || {}).name || addr
            // Tandai agar auto-connect tidak menghubungkan ulang selama 5 menit
            command = ["sh", "-c",
                "echo '" + addr + " '\"$(date +%s)\" >> \"${XDG_RUNTIME_DIR:-/tmp}/qs-bt-autoconnect.skip\"; " +
                "bluetoothctl disconnect " + addr]
            running = true
        }
        onRunningChanged: {
            if (!running) {
                btListProc.running = true
                btNotifyProc.command = ["notify-send", "-a", "Bluetooth",
                    "-i", "bluetooth-disabled-symbolic", "-t", "3000",
                    "Terputus", root._lastDeviceName + " telah diputus."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: btRemoveProc
        function removeDevice(addr) {
            root._lastDeviceName = (root.btDevices.find(d => d.address === addr) || {}).name || addr
            command = ["sh", "-c", "bluetoothctl remove " + addr]
            running = true
        }
        onRunningChanged: {
            if (!running) {
                btListProc.running = true
                btNotifyProc.command = ["notify-send", "-a", "Bluetooth",
                    "-i", "bluetooth-disabled-symbolic", "-t", "3000",
                    "Perangkat dihapus", root._lastDeviceName + " telah di-unpair."]
                btNotifyProc.running = true
            }
        }
    }

    // Proses notifikasi bersama
    Process { id: btNotifyProc }

    Process {
        id: btStatusProc
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = text.includes("yes")
        }
    }

    Process {
        id: btListProc
        command: ["sh", "-c", [
            "bluetoothctl devices Paired 2>/dev/null | while read -r line; do",
            "  addr=$(echo \"$line\" | awk '{print $2}');",
            "  name=$(echo \"$line\" | awk '{ $1=\"\"; $2=\"\"; sub(/^  */, \"\"); print }');",
            "  connected=$(bluetoothctl info $addr 2>/dev/null | grep -q 'Connected: yes' && echo 1 || echo 0);",
            "  echo \"PAIRED|$connected|$addr|$name\";",
            "done;",
            "bluetoothctl devices 2>/dev/null | while read -r line; do",
            "  addr=$(echo \"$line\" | awk '{print $2}');",
            "  name=$(echo \"$line\" | awk '{ $1=\"\"; $2=\"\"; sub(/^  */, \"\"); print }');",
            "  [ -n \"$addr\" ] || continue;",
            "  paired=$(bluetoothctl info $addr 2>/dev/null | grep -q 'Paired: yes' && echo 1 || echo 0);",
            "  if [ $paired -eq 0 ]; then echo \"AVAIL|0|$addr|$name\"; fi;",
            "done"
        ].join(" ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.includes("|"))
                const result = []
                for (const line of lines) {
                    const parts = line.split("|")
                    if (parts.length < 4) continue
                    const type      = parts[0]
                    const connected = parts[1] === "1"
                    const address   = parts[2]
                    const name      = parts.slice(3).join("|").trim()
                    if (!address) continue
                    result.push({
                        name:      name || address,
                        address:   address,
                        connected: connected,
                        paired:    type === "PAIRED"
                    })
                }
                result.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    if (a.paired    !== b.paired)    return a.paired    ? -1 : 1
                    return (a.name || "").localeCompare(b.name || "")
                })
                root.btDevices = result
            }
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────
    Timer {
        interval: 8000
        running: root.open
        repeat: true
        onTriggered: {
            if (root.wifiEnabled) wifiListProc.running = true
            if (root.btEnabled)   btListProc.running = true
        }
    }
}
