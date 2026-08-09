import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

// Panel riwayat clipboard — menggunakan cliphist + wl-copy.
// cliphist list          → list semua entry (format: <id>\t<preview>)
// cliphist decode <id>   → decode entry ke stdout
// wl-copy                → salin ke clipboard dari stdin
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
            root._refresh()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.exclusiveZone: 0

    // ── State ──────────────────────────────────────────────────────────────
    property var entries: []       // [{id, preview}]
    property string query: ""      // filter search

    property var filteredEntries: {
        const q = root.query.toLowerCase().trim()
        if (q === "") return root.entries
        return root.entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    // ── Proses ─────────────────────────────────────────────────────────────
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "")
                const parsed = lines.map(line => {
                    const tab = line.indexOf("\t")
                    if (tab < 0) return { id: line, preview: line }
                    return {
                        id: line.slice(0, tab),
                        preview: line.slice(tab + 1).slice(0, 120)
                    }
                })
                root.entries = parsed
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

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 10

        width: 420
        height: Math.min(Math.max(contentCol.implicitHeight + 40, 420), root.height - 20)

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
                NumberAnimation { target: cardTranslate; property: "y"; duration: 220; easing.type: Easing.OutCubic }
                OpacityAnimator { target: card; duration: 200; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: 160; easing.type: Easing.InCubic }
                        OpacityAnimator { target: card; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header ─────────────────────────────────────────────────────
            RowLayout {
                id: headerRow
                Layout.fillWidth: true

                Text {
                    text: "󰅍  Clipboard"
                    font.pixelSize: 15; font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: root.entries.length > 0
                    width: clearClipTxt.implicitWidth + 14
                    height: 24; radius: 8
                    color: clearClipMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        id: clearClipTxt
                        anchors.centerIn: parent
                        text: "Hapus semua"; font.pixelSize: 11
                        color: Root.Colors.subtext
                    }
                    MouseArea {
                        id: clearClipMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root._clearAll()
                    }
                }
            }

            // ── Search box ─────────────────────────────────────────────────
            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                height: 34; radius: 10
                color: Root.Colors.surface0
                border.color: searchInput.activeFocus ? Root.Colors.blue : Root.Colors.surface2
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"; font.pixelSize: 13
                        color: Root.Colors.subtext
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        height: searchInput.implicitHeight

                        // Placeholder teks
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "Cari..."
                            font.pixelSize: 12
                            color: Root.Colors.surface2
                        }

                        TextInput {
                            id: searchInput
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            color: Root.Colors.text
                            font.pixelSize: 12
                            clip: true
                            onTextChanged: root.query = text

                            // Fokus otomatis saat panel terbuka
                            Connections {
                                target: root
                                function onOpenChanged() {
                                    if (root.open) searchInput.forceActiveFocus()
                                    else { searchInput.text = ""; root.query = "" }
                                }
                            }

                            Keys.onEscapePressed: root.closeRequested()
                        }
                    }
                }
            }

            // ── Kosong state
            Item {
                visible: root.filteredEntries.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰅍"; font.pixelSize: 28
                        color: Root.Colors.surface2
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.query !== "" ? "Tidak ada hasil" : "Clipboard kosong"
                        font.pixelSize: 12; color: Root.Colors.subtext
                    }
                }
            }

            Flickable {
                id: listFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.filteredEntries.length > 0
                contentWidth: width
                contentHeight: clipCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: clipCol
                    width: listFlick.width
                    spacing: 4

                    Repeater {
                        model: root.filteredEntries

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: clipCol.width
                            implicitHeight: clipRow.implicitHeight + 14
                            radius: 10
                            color: clipHover.containsMouse ? Root.Colors.surface0 : Root.Colors.base
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                id: clipRow
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10; rightMargin: 8
                                }
                                spacing: 8

                                // Index badge
                                Text {
                                    text: index + 1
                                    font.pixelSize: 10
                                    color: Root.Colors.surface2
                                    Layout.minimumWidth: 16
                                }

                                // Preview teks
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

                                // Tombol hapus entry
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: delMa.containsMouse
                                           ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.2)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    visible: clipHover.containsMouse

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"; font.pixelSize: 11
                                        color: delMa.containsMouse ? Root.Colors.red : Root.Colors.subtext
                                    }
                                    MouseArea {
                                        id: delMa; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root._deleteEntry(modelData.id)
                                    }
                                }
                            }

                            HoverHandler { id: clipHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                // Hanya klik di area non-tombol yang copy
                                onClicked: root._copyEntry(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
