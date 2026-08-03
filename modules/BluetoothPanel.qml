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
    WlrLayershell.namespace: "quickshell-bluetooth"
    WlrLayershell.exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── State ──────────────────────────────────────────────────────────────
    property bool btEnabled: false
    property bool scanning: false
    property var devices: []   // [{name, address, connected, paired}]

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
            if (!root.btEnabled) return minHeight - headerHeight - 32
            const count = root.devices.length
            if (count === 0) return minHeight - headerHeight - 32
            const paired   = root.devices.filter(d => d.paired).length
            const avail    = root.devices.filter(d => !d.paired).length
            let h = 0
            if (paired > 0) h += 28 + paired * 54 + 6
            if (avail  > 0) h += 28 + avail  * 54
            return Math.max(h, minHeight - headerHeight - 32)
        }

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        layer.enabled: true
        layer.effect: null

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
                    // Setelah animasi tutup selesai, sembunyikan panel
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Block clicks di dalam kartu dari overlay
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: col
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.topMargin: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰂯  Bluetooth"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Tombol scan perangkat
                Rectangle {
                    visible: root.btEnabled
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

                // Toggle BT on/off
                Rectangle {
                    width: 44; height: 26; radius: 13
                    color: root.btEnabled ? Root.Colors.blue : Root.Colors.surface1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        x: root.btEnabled ? parent.width - width - 4 : 4
                        y: 4; width: 18; height: 18; radius: 9
                        color: Root.Colors.base
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const cmd = root.btEnabled
                                ? "bluetoothctl power off"
                                : "bluetoothctl power on"
                            btToggleProc.command = ["sh", "-c", cmd]
                            btToggleProc.running = true
                            root.btEnabled = !root.btEnabled
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // ── Scrollable device list ─────────────────────────────────────────
        ScrollView {
            id: scrollArea
            anchors {
                top: col.bottom
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

            // Pesan BT mati
            Text {
                visible: !root.btEnabled
                width: scrollArea.width
                horizontalAlignment: Text.AlignHCenter
                text: "Bluetooth dimatikan"
                font.pixelSize: 12
                color: Root.Colors.subtext
                topPadding: 12; bottomPadding: 12
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Daftar perangkat
            ColumnLayout {
                visible: root.btEnabled
                width: scrollArea.width - 16
                x: 8
                spacing: 2

                // Sub-header: Terpasang
                Text {
                    visible: root.devices.some(d => d.paired)
                    text: "TERPASANG"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
                    color: Root.Colors.subtext
                    leftPadding: 4
                    topPadding: 2
                    bottomPadding: 2
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Repeater {
                    model: root.devices.filter(d => d.paired)
                    delegate: BtDeviceRow {
                        Layout.fillWidth: true
                        deviceData: modelData
                        onConnectRequested:    addr => connectProc.connectDevice(addr)
                        onDisconnectRequested: addr => disconnectProc.disconnectDevice(addr)
                        onRemoveRequested:     addr => removeProc.removeDevice(addr)
                    }
                }

                // Sub-header: Tersedia
                Text {
                    visible: root.devices.some(d => !d.paired)
                    text: "TERSEDIA"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
                    color: Root.Colors.subtext
                    leftPadding: 4
                    topPadding: 6
                    bottomPadding: 2
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Repeater {
                    model: root.devices.filter(d => !d.paired)
                    delegate: BtDeviceRow {
                        Layout.fillWidth: true
                        deviceData: modelData
                        onConnectRequested:    addr => connectProc.connectDevice(addr)
                        onDisconnectRequested: addr => disconnectProc.disconnectDevice(addr)
                        onRemoveRequested:     addr => removeProc.removeDevice(addr)
                    }
                }

                // Pesan kosong
                Text {
                    visible: root.btEnabled && root.devices.length === 0 && !root.scanning
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Tidak ada perangkat\nKlik  untuk scan"
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

    // ── Komponen baris perangkat ──────────────────────────────────────────
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
        Behavior on color { ColorAnimation { duration: 120 } }

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
                Behavior on color { ColorAnimation { duration: 150 } }
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
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    visible: deviceData.connected
                    text: "Terhubung"
                    font.pixelSize: 11
                    color: Root.Colors.green
                    Behavior on color { ColorAnimation { duration: 150 } }
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
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: actTxt
                        anchors.centerIn: parent
                        text: deviceData.connected ? "Putus" : "Hubung"
                        font.pixelSize: 12
                        color: deviceData.connected ? Root.Colors.text : Root.Colors.base
                        Behavior on color { ColorAnimation { duration: 120 } }
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
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        font.pixelSize: 12
                        color: Root.Colors.red
                        Behavior on color { ColorAnimation { duration: 120 } }
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

    // ── Proses ────────────────────────────────────────────────────────────

    // Nama perangkat terakhir yang diaksi (untuk notifikasi)
    property string _lastDeviceName: ""
    property bool   _lastWasConnect: false
    property bool   _lastWasRemove:  false

    Process {
        id: btToggleProc
        onRunningChanged: {
            if (!running) {
                statusProc.running = true
                btNotifyProc.command = root.btEnabled
                    ? ["notify-send", "-a", "Bluetooth", "-i", "bluetooth-active-symbolic", "-t", "3000", "Bluetooth aktif", "Bluetooth telah dinyalakan."]
                    : ["notify-send", "-a", "Bluetooth", "-i", "bluetooth-disabled-symbolic", "-t", "3000", "Bluetooth nonaktif", "Bluetooth telah dimatikan."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "bluetoothctl --timeout 8 scan on 2>/dev/null; echo done"]
        onRunningChanged: {
            if (!running) {
                root.scanning = false
                listProc.running = true
            }
        }
    }

    Process {
        id: connectProc
        function connectDevice(addr) {
            root._lastDeviceName = (root.devices.find(d => d.address === addr) || {}).name || addr
            root._lastWasConnect = true
            root._lastWasRemove  = false
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
                listProc.running = true
                btNotifyProc.command = ["notify-send", "-a", "Bluetooth",
                    "-i", "bluetooth-active-symbolic", "-t", "3000",
                    "Terhubung", root._lastDeviceName + " berhasil dihubungkan."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: disconnectProc
        function disconnectDevice(addr) {
            root._lastDeviceName = (root.devices.find(d => d.address === addr) || {}).name || addr
            root._lastWasConnect = false
            root._lastWasRemove  = false
            command = ["sh", "-c", "bluetoothctl disconnect " + addr]
            running = true
        }
        onRunningChanged: {
            if (!running) {
                listProc.running = true
                btNotifyProc.command = ["notify-send", "-a", "Bluetooth",
                    "-i", "bluetooth-disabled-symbolic", "-t", "3000",
                    "Terputus", root._lastDeviceName + " telah diputus."]
                btNotifyProc.running = true
            }
        }
    }

    Process {
        id: removeProc
        function removeDevice(addr) {
            root._lastDeviceName = (root.devices.find(d => d.address === addr) || {}).name || addr
            root._lastWasRemove  = true
            command = ["sh", "-c", "bluetoothctl remove " + addr]
            running = true
        }
        onRunningChanged: {
            if (!running) {
                listProc.running = true
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
        id: statusProc
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = text.includes("yes")
        }
    }

    Process {
        id: listProc
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
                root.devices = result
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
        interval: 10000
        running: root.open && root.btEnabled
        repeat: true
        onTriggered: listProc.running = true
    }
}
