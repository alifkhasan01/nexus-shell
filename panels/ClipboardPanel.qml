import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root
import "../dashboard" as Dash

// Panel dua tab — Clipboard & Catatan
//   Tab "Clipboard" : riwayat clipboard via cliphist + wl-copy
//   Tab "Catatan"   : todo sederhana, disimpan ke ~/.config/quickshell/todo.txt
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    property int currentTab: 0  // 0 = Clipboard, 1 = Catatan

    onOpenChanged: {
        if (open) {
            showPanel = true
            root._refresh()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.exclusiveZone: 0

    // ── State Clipboard ───────────────────────────────────────────────────
    property var entries: []
    property string query: ""

    property var filteredEntries: {
        const q = root.query.toLowerCase().trim()
        if (q === "") return root.entries
        return root.entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    // ── Proses Clipboard ──────────────────────────────────────────────────
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "")
                root.entries = lines.map(line => {
                    const tab = line.indexOf("\t")
                    if (tab < 0) return { id: line, preview: line }
                    return {
                        id:      line.slice(0, tab),
                        preview: line.slice(tab + 1).slice(0, 120)
                    }
                })
            }
        }
    }

    Process {
        id: decodeProc
        stdout: StdioCollector {
            onStreamFinished: {
                copyProc.command = ["wl-copy", "--", text]
                copyProc.running = true
            }
        }
    }

    Process { id: copyProc }

    Process {
        id: deleteProc
        onRunningChanged: if (!running) root._refresh()
    }

    function _refresh() {
        listProc.running = false
        listProc.running = true
    }

    function _copyEntry(id) {
        decodeProc.command = ["cliphist", "decode", id]
        decodeProc.running = true
        root.closeRequested()
    }

    function _deleteEntry(id) {
        deleteProc.command = ["cliphist", "delete", "--", id]
        deleteProc.running = true
    }

    function _clearAll() {
        deleteProc.command = ["cliphist", "wipe"]
        deleteProc.running = true
        root.entries = []
    }

    // ── Klik luar untuk tutup ─────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Kartu utama ───────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 420
        height: Math.min(Math.max(480, root.height - 20), root.height - 20)

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

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
                    NumberAnimation { target: cardTranslate; property: "y"; duration: 220; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
                    OpacityAnimator { target: card; duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: 160; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                        OpacityAnimator { target: card; duration: 150; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Layout utama ──────────────────────────────────────────────────
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header: judul + tombol aksi + tab bar ─────────────────────
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 28
                spacing: 6

                // Judul tab aktif
                Text {
                    text: root.currentTab === 0 ? "  Clipboard" : "  Catatan"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                // Tombol "Hapus semua" — hanya di tab Clipboard, ada isi
                Rectangle {
                    visible: root.currentTab === 0 && root.entries.length > 0
                    width: clearLbl.implicitWidth + 14
                    height: 24
                    radius: 7
                    color: clearMa.containsMouse
                           ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                           : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: clearLbl
                        anchors.centerIn: parent
                        text: "\u{f00c2}  Hapus semua"
                        font.pixelSize: 10
                        color: clearMa.containsMouse ? Root.Colors.red : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._clearAll()
                    }
                }

                // Tab bar
                Rectangle {
                    implicitWidth: tabRow.implicitWidth + 6
                    height: 28
                    radius: 8
                    color: Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: ["Clipboard", "Catatan"]

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: tabLbl.implicitWidth + 16
                                height: 22
                                radius: 6
                                color: root.currentTab === index
                                    ? Root.Colors.surface2
                                    : (tabMa.containsMouse ? Root.Colors.surface1 : "transparent")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: tabLbl
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 11
                                    font.bold: root.currentTab === index
                                    color: root.currentTab === index ? Root.Colors.text : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: 100 } }
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

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ── Konten tab (stack, keduanya di atas Item yang sama) ────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ── TAB 0: CLIPBOARD ──────────────────────────────────────
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    opacity: root.currentTab === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Search box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 10
                        color: Root.Colors.surface0
                        border.color: clipInput.activeFocus ? Root.Colors.blue : Root.Colors.surface2
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{f0349}"
                                font.pixelSize: 13
                                color: Root.Colors.subtext
                            }

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                height: clipInput.implicitHeight

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: clipInput.text.length === 0
                                    text: "Cari..."
                                    font.pixelSize: 12
                                    color: Root.Colors.surface2
                                }

                                TextInput {
                                    id: clipInput
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    color: Root.Colors.text
                                    font.pixelSize: 12
                                    clip: true
                                    onTextChanged: root.query = text
                                    Keys.onEscapePressed: root.closeRequested()
                                }
                            }
                        }
                    }

                    // Kosong state
                    Item {
                        visible: root.filteredEntries.length === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\u{f0b4d}"
                                font.pixelSize: 28
                                color: Root.Colors.surface2
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.query !== "" ? "Tidak ada hasil" : "Clipboard kosong"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                            }
                        }
                    }

                    // List clipboard
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.filteredEntries.length > 0
                        contentWidth: width
                        contentHeight: clipCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: clipCol
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: root.filteredEntries

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index

                                    width: clipCol.width
                                    implicitHeight: clipRow.implicitHeight + 14
                                    radius: 10
                                    color: clipHover.hovered ? Root.Colors.surface0 : Root.Colors.base
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        id: clipRow
                                        anchors {
                                            left: parent.left; right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: 10; rightMargin: 8
                                        }
                                        spacing: 8

                                        Text {
                                            text: index + 1
                                            font.pixelSize: 10
                                            color: Root.Colors.surface2
                                            Layout.minimumWidth: 16
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.preview
                                            font.pixelSize: 12
                                            color: Root.Colors.text
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                        }

                                        // Tombol hapus entry (muncul saat hover)
                                        Rectangle {
                                            visible: clipHover.hovered
                                            width: 22; height: 22; radius: 6
                                            color: delMa.containsMouse
                                                   ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.22)
                                                   : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\u{f0156}"
                                                font.pixelSize: 11
                                                color: delMa.containsMouse ? Root.Colors.red : Root.Colors.subtext
                                            }
                                            MouseArea {
                                                id: delMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root._deleteEntry(modelData.id)
                                            }
                                        }
                                    }

                                    HoverHandler { id: clipHover }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root._copyEntry(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── TAB 1: CATATAN ────────────────────────────────────────
                Dash.TodoWidget {
                    anchors.fill: parent
                    showHeader: false
                    opacity: root.currentTab === 1 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
