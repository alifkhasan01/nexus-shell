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

    // Daftar paket dari luar (diisi oleh SystemUpdate)
    property var packages: []   // [{name, version}]
    property int pending: -1

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    // Tetap visible selama animasi tutup belum selesai
    property bool showPanel: false
    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-update"
    WlrLayershell.exclusiveZone: 0

    // ── State internal ────────────────────────────────────────────────────
    property bool updating: false
    property bool updateDone: false
    property bool refreshing: false
    property string logText: ""

    // ── Kartu ─────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        // Center di layar
        anchors.centerIn: parent

        width: 580
        height: Math.min(720, root.height - 80)

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

        // Block klik di dalam
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Header ────────────────────────────────────────────────────────
        ColumnLayout {
            id: headerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 14
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰚰  Update Sistem"
                    font.pixelSize: 16
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Badge jumlah paket
                Rectangle {
                    visible: root.pending > 0 && !root.updating && !root.updateDone
                    implicitWidth: Math.max(22, cntTxt.implicitWidth + 10)
                    height: 20
                    radius: 10
                    color: Root.Colors.yellow

                    Text {
                        id: cntTxt
                        anchors.centerIn: parent
                        text: root.pending
                        font.pixelSize: 10
                        font.bold: true
                        color: Root.Colors.base
                    }
                }

                Text {
                    visible: root.updateDone
                    text: "Selesai"
                    font.pixelSize: 11
                    color: Root.Colors.green
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Tombol close — selalu tersedia (termasuk saat update).
                // Hanya menutup panel, proses update tidak ikut terhenti.
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 8
                    color: headerCloseHover.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: headerCloseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.updateDone = false
                            root.logText = ""
                            root.closeRequested()
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

        // ── Area tengah: daftar paket atau log ────────────────────────────
        Item {
            id: listArea
            anchors {
                top: headerCol.bottom
                topMargin: 6
                left: parent.left
                right: parent.right
                bottom: footerRow.top
                bottomMargin: 8
            }

            // ── Daftar paket (saat belum update) ──────────────────────────
            ScrollView {
                anchors.fill: parent
                visible: !root.updating && !root.updateDone
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ScrollBar.vertical: ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        radius: 2
                        color: Root.Colors.surface2
                        opacity: parent.active ? 1.0 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    background: Rectangle { color: "transparent" }
                }

                ColumnLayout {
                    width: listArea.width - 16
                    x: 8
                    spacing: 2

                    // Status pengecekan / refresh — supaya tidak terlihat kosong
                    RowLayout {
                        visible: root.refreshing
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Memeriksa update"
                            font.pixelSize: 13
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Titik beranimasi saat pengecekan
                        Row {
                            id: dotsRow
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter

                            property int dotIndex: 0

                            Timer {
                                interval: 350
                                running: root.refreshing
                                repeat: true
                                onTriggered: dotsRow.dotIndex = (dotsRow.dotIndex + 1) % 3
                            }

                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 4
                                    color: Root.Colors.subtext
                                    anchors.verticalCenter: parent.verticalCenter

                                    opacity: dotsRow.dotIndex === index ? 1.0 : 0.25
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Up to date
                    Item {
                        visible: root.pending === 0
                        Layout.fillWidth: true
                        implicitHeight: 48

                        Text {
                            anchors.centerIn: parent
                            text: "󰸞  Sistem sudah up to date"
                            font.pixelSize: 14
                            color: Root.Colors.green
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Belum pernah dicek
                    Text {
                        visible: root.pending < 0
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Belum ada data"
                        font.pixelSize: 12
                        color: Root.Colors.subtext
                        topPadding: 12
                        bottomPadding: 12
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // List paket
                    Repeater {
                        model: root.packages
                        visible: root.pending > 0

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: 10
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰏖"
                                    font.pixelSize: 18
                                    color: Root.Colors.blue
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: 13
                                    color: Root.Colors.text
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    text: modelData.version
                                    font.pixelSize: 11
                                    color: Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                height: 1
                                color: Root.Colors.surface0
                                visible: index < root.packages.length - 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }
            }

            // ── Log output (saat update berjalan / selesai) ───────────────
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                visible: root.updating || root.updateDone
                color: Root.Colors.base
                radius: 10
                border.color: Root.Colors.surface0
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                ScrollView {
                    id: logScroll
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            radius: 2
                            color: Root.Colors.surface2
                            opacity: parent.active ? 1.0 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    Text {
                        id: logOutput
                        width: logScroll.width - 8
                        text: root.logText || " "
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: Root.Colors.text
                        wrapMode: Text.WrapAnywhere
                        Behavior on color { ColorAnimation { duration: 150 } }

                        onTextChanged: {
                            // Auto-scroll ke bawah saat ada log baru
                            Qt.callLater(() => {
                                logScroll.ScrollBar.vertical.position =
                                    Math.max(0, 1.0 - logScroll.ScrollBar.vertical.size)
                            })
                        }
                    }
                }

                // Placeholder saat update baru dimulai dan log masih kosong
                Text {
                    anchors.centerIn: parent
                    visible: root.updating && root.logText.length === 0
                    text: "Memulai update...\nMengunduh dan memasang paket."
                    font.pixelSize: 12
                    color: Root.Colors.subtext
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // ── Footer ────────────────────────────────────────────────────────
        RowLayout {
            id: footerRow
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 12
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 8

            // Tutup (hanya saat tidak update)
            Rectangle {
                visible: !root.updating
                implicitWidth: closeTxt.implicitWidth + 28
                implicitHeight: 38
                radius: 10
                color: closeHover.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: closeTxt
                    anchors.centerIn: parent
                    text: "Tutup"
                    font.pixelSize: 13
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.updateDone = false
                        root.logText = ""
                        root.closeRequested()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Tombol refresh
            Rectangle {
                visible: !root.updating && !root.updateDone
                implicitWidth: refreshTxt.implicitWidth + 28
                implicitHeight: 38
                radius: 10
                color: refreshHover.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: refreshTxt
                    anchors.centerIn: parent
                    text: "Refresh"
                    font.pixelSize: 13
                    color: Root.Colors.subtext
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: refreshHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.refreshing) {
                            root.refreshing = true
                            refreshProc.running = true
                        }
                    }
                }
            }

            // Tombol update
            Rectangle {
                visible: !root.updating && !root.updateDone && root.pending > 0
                implicitWidth: updateTxt.implicitWidth + 32
                implicitHeight: 38
                radius: 10
                color: updateHover.containsMouse ? Qt.lighter(Root.Colors.blue, 1.1) : Root.Colors.blue
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰚰"
                        font.pixelSize: 15
                        color: Root.Colors.base
                    }

                    Text {
                        id: updateTxt
                        text: "Update Semua"
                        font.pixelSize: 13
                        color: Root.Colors.base
                    }
                }

                MouseArea {
                    id: updateHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.logText = ""
                        root.updating = true
                        updateProc.running = true
                    }
                }
            }

            // Spinner saat update berjalan
            Row {
                visible: root.updating
                spacing: 8

                Text {
                    id: spinnerIcon
                    text: "󰑓"
                    font.pixelSize: 17
                    color: Root.Colors.blue
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RotationAnimation on rotation {
                        running: root.updating
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        direction: RotationAnimation.Counterclockwise
                    }
                }

                Text {
                    text: "Sedang update..."
                    font.pixelSize: 13
                    color: Root.Colors.subtext
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }

    // ── Proses refresh (cek ulang paket) ─────────────────────────────────
    Process {
        id: refreshProc
        command: ["sh", "-c", "yay -Qu 2>/dev/null || paru -Qu 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const pkgs = []
                for (const line of lines) {
                    const m = line.match(/^(\S+)\s+\S+\s+->\s+(\S+)/)
                    if (m) pkgs.push({ name: m[1], version: m[2] })
                    else if (line.trim()) pkgs.push({ name: line.trim(), version: "" })
                }
                root.packages = pkgs
                root.pending = pkgs.length
                root.refreshing = false
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                root.pending = 0
                root.packages = []
                root.refreshing = false
            }
        }
    }

    // ── Proses update ─────────────────────────────────────────────────────
    Process {
        id: updateProc
        command: ["sh", "-c", "yay -Syu --noconfirm 2>&1 || paru -Syu --noconfirm 2>&1"]
        stdout: SplitParser {
            onRead: data => {
                root.logText += data + "\n"
            }
        }
        onExited: (code, status) => {
            root.updating = false
            root.updateDone = true
            if (code === 0) {
                root.logText += "\n✓ Update selesai."
                root.pending = 0
                root.packages = []
            } else {
                root.logText += "\n✗ Update gagal (exit " + code + ")."
            }
        }
    }
}
