pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

// Widget catatan/todo sederhana — disimpan ke ~/.config/quickshell/todo.txt
// Format satu baris per item, baris diawali "[ ] " atau "[x] "
Item {
    id: root

    // Kalau false, header "Catatan" disembunyikan (dipakai di ClipboardPanel
    // yang sudah punya tab bar sendiri).
    property bool showHeader: true

    // ── State ──────────────────────────────────────────────────────────────
    property var items: []    // [{text, done}]
    property string _draft: ""

    // ── Baca dari file ─────────────────────────────────────────────────────
    Process {
        id: loadProc
        command: ["sh", "-c",
            "cat ~/.config/quickshell/todo.txt 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "")
                root.items = lines.map(l => {
                    if (l.startsWith("[x] "))
                        return { text: l.slice(4), done: true }
                    if (l.startsWith("[ ] "))
                        return { text: l.slice(4), done: false }
                    return { text: l, done: false }
                })
            }
        }
    }

    Component.onCompleted: loadProc.running = true

    // ── Simpan ke file ─────────────────────────────────────────────────────
    Process {
        id: saveProc
    }

    function _save() {
        const content = root.items.map(it =>
            (it.done ? "[x] " : "[ ] ") + it.text
        ).join("\n") + (root.items.length > 0 ? "\n" : "")
        saveProc.command = ["sh", "-c",
            "printf '%s' " + JSON.stringify(content) +
            " > ~/.config/quickshell/todo.txt"]
        saveProc.running = true
    }

    function _addItem(text) {
        const t = text.trim()
        if (t === "") return
        const arr = root.items.slice()
        arr.push({ text: t, done: false })
        root.items = arr
        root._save()
        root._draft = ""
    }

    function _toggleItem(idx) {
        const arr = root.items.map((it, i) =>
            i === idx ? { text: it.text, done: !it.done } : it
        )
        root.items = arr
        root._save()
    }

    function _deleteItem(idx) {
        const arr = root.items.slice()
        arr.splice(idx, 1)
        root.items = arr
        root._save()
    }

    function _clearDone() {
        root.items = root.items.filter(it => !it.done)
        root._save()
    }

    // ── UI ─────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 0
        spacing: 6

        // ── Header ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            visible: root.showHeader

            Text {
                text: "󰸕  Catatan"
                font.pixelSize: 13; font.weight: Font.SemiBold
                color: Root.Colors.lavender
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }

            Item { Layout.fillWidth: true }

            // Hapus selesai
            Rectangle {
                visible: root.items.some(it => it.done)
                width: doneTxt.implicitWidth + 12; height: 22; radius: 7
                color: doneMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
                Text {
                    id: doneTxt
                    anchors.centerIn: parent
                    text: "Bersihkan selesai"; font.pixelSize: 10
                    color: Root.Colors.subtext
                }
                MouseArea {
                    id: doneMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root._clearDone()
                }
            }
        }

        // ── Input tambah item baru ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            height: 32; radius: 8
            color: Root.Colors.surface0
            border.color: todoInput.activeFocus ? Root.Colors.lavender : Root.Colors.surface1
            border.width: 1
            Behavior on border.color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰐕"; font.pixelSize: 13
                    color: todoInput.activeFocus ? Root.Colors.lavender : Root.Colors.surface2
                    Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
                }

                TextInput {
                    id: todoInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 30
                    color: Root.Colors.text
                    font.pixelSize: 12
                    clip: true
                    text: root._draft
                    onTextChanged: root._draft = text

                    Keys.onReturnPressed: {
                        root._addItem(text)
                        todoInput.text = ""
                    }
                    Keys.onEscapePressed: { todoInput.text = ""; root._draft = "" }
                }
            }
        }

        // ── List item ──────────────────────────────────────────────────────
        // Kosong state
        Item {
            visible: root.items.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "Belum ada catatan"
                font.pixelSize: 11; color: Root.Colors.surface2
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length > 0
            contentWidth: width
            contentHeight: todoCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: todoCol
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.items

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: todoCol.width
                        height: 34; radius: 8
                        color: rowHover.containsMouse ? Root.Colors.surface0 : "transparent"
                        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6

                            // Checkbox
                            Rectangle {
                                width: 18; height: 18; radius: 5
                                color: modelData.done
                                       ? Root.Colors.lavender
                                       : Root.Colors.surface1
                                border.color: modelData.done ? Root.Colors.lavender : Root.Colors.surface2
                                border.width: 1
                                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.done
                                    text: "󰄴"; font.pixelSize: 11
                                    color: Root.Colors.base
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root._toggleItem(index)
                                }
                            }

                            // Teks item
                            Text {
                                Layout.fillWidth: true
                                text: modelData.text
                                font.pixelSize: 12
                                color: modelData.done ? Root.Colors.subtext : Root.Colors.text
                                font.strikeout: modelData.done
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
                            }

                            // Tombol hapus (hanya muncul hover)
                            Rectangle {
                                visible: rowHover.containsMouse
                                width: 20; height: 20; radius: 5
                                color: delMa2.containsMouse
                                       ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.2)
                                       : "transparent"
                                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"; font.pixelSize: 10
                                    color: delMa2.containsMouse ? Root.Colors.red : Root.Colors.subtext
                                }
                                MouseArea {
                                    id: delMa2; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root._deleteItem(index)
                                }
                            }
                        }

                        HoverHandler { id: rowHover }
                    }
                }
            }
        }
    }
}
