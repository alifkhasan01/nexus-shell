pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../" as Root
import "./" as Dash

// Tab Clipboard di Dashboard — riwayat clipboard (cliphist) + catatan (todo).
// Content dipindah dari panels/ClipboardPanel.qml (PanelWindow → tab).

Item {
    id: ct

    property bool active: false
    signal closeRequested()

    property int currentTab: 0  // 0 = Clipboard, 1 = Catatan

    onActiveChanged: if (active) ct._refresh()

    // ── State Clipboard ───────────────────────────────────────────────────
    property var entries: []
    property string query: ""

    property var filteredEntries: {
        const q = ct.query.toLowerCase().trim()
        if (q === "") return ct.entries
        return ct.entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    // ── Proses Clipboard ──────────────────────────────────────────────────
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "")
                ct.entries = lines.map(line => {
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
        onRunningChanged: if (!running) ct._refresh()
    }

    function _refresh() {
        listProc.running = false
        listProc.running = true
    }

    function _copyEntry(id) {
        decodeProc.command = ["cliphist", "decode", id]
        decodeProc.running = true
        ct.closeRequested()
    }

    function _deleteEntry(id) {
        deleteProc.command = ["cliphist", "delete", "--", id]
        deleteProc.running = true
    }

    function _clearAll() {
        deleteProc.command = ["cliphist", "wipe"]
        deleteProc.running = true
        ct.entries = []
    }

    // ── Layout utama ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header: judul + tombol aksi + tab bar ─────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 6

            // Judul tab aktif
            Text {
                text: ct.currentTab === 0 ? "  Clipboard" : "  Catatan"
                font.pixelSize: 15
                font.bold: true
                color: Root.Colors.text
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item { Layout.fillWidth: true }

            // Tombol "Hapus semua" — hanya di tab Clipboard, ada isi
            Rectangle {
                visible: ct.currentTab === 0 && ct.entries.length > 0
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
                    onClicked: ct._clearAll()
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
                            color: ct.currentTab === index
                                ? Root.Colors.surface2
                                : (tabMa.containsMouse ? Root.Colors.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: tabLbl
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 11
                                font.bold: ct.currentTab === index
                                color: ct.currentTab === index ? Root.Colors.text : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ct.currentTab = index
                            }
                        }
                    }
                }
            }
        }

        // ── Divider ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            color: Root.Colors.surface1
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // ── Konten tab ─────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── TAB 0: CLIPBOARD ──────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                opacity: ct.currentTab === 0 ? 1 : 0
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
                                onTextChanged: ct.query = text
                                Keys.onEscapePressed: ct.closeRequested()
                            }
                        }
                    }
                }

                // Kosong state
                Item {
                    visible: ct.filteredEntries.length === 0
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
                            text: ct.query !== "" ? "Tidak ada hasil" : "Clipboard kosong"
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                        }
                    }
                }

                // List clipboard
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: ct.filteredEntries.length > 0
                    contentWidth: width
                    contentHeight: clipCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: clipCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: ct.filteredEntries

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
                                            onClicked: ct._deleteEntry(modelData.id)
                                        }
                                    }
                                }

                                HoverHandler { id: clipHover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ct._copyEntry(modelData.id)
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
                opacity: ct.currentTab === 1 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}