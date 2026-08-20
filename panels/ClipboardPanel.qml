import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
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
    property int currentTab: 2  // 0 = Clipboard, 1 = Catatan, 2 = Notifikasi
    property int openTab: 2     // tab yang aktif saat panel dibuka

    onOpenChanged: {
        if (open) {
            root.currentTab = root.openTab
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
        anchors.rightMargin: 100

        width: 420
        height: {
            // Kalkulasi tinggi berdasarkan konten
            const headerHeight = 60      // Header + divider
            const searchHeight = 42      // Search box (tab 0) atau padding
            const minContentHeight = 180 // Minimal content area
            const maxHeight = 650        // Maksimal tinggi panel
            
            // Untuk tab Clipboard
            if (root.currentTab === 0) {
                const itemCount = root.filteredEntries.length
                if (itemCount === 0) {
                    // Empty state: lebih kecil
                    return headerHeight + searchHeight + 160
                } else {
                    // Ada konten: sesuaikan dengan jumlah item (max ~8 items visible)
                    const itemHeight = 52  // Estimasi tinggi per item
                    const maxItems = 8
                    const visibleItems = Math.min(itemCount, maxItems)
                    const calculatedHeight = headerHeight + searchHeight + (visibleItems * itemHeight) + 20
                    return Math.min(calculatedHeight, maxHeight)
                }
            } else if (root.currentTab === 1) {
                // Tab Catatan: tinggi sedang
                return Math.min(480, maxHeight)
            } else {
                // Tab Notifikasi: tinggi menyesuaikan isi notifikasi agar
                // tidak terpotong (tiap item bisa lebih tinggi dari 60px).
                const itemCount = Root.NotificationService.historyModel.count
                if (itemCount === 0) {
                    return headerHeight + 160
                } else {
                    const contentHeight = Math.max(notifCol.implicitHeight, 140)
                    const calculatedHeight = headerHeight + contentHeight + 80
                    return Math.min(calculatedHeight, maxHeight)
                }
            }
        }

        radius: 16
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        
        Behavior on height { 
            NumberAnimation { 
                duration: 200
                easing.type: Easing.OutCubic 
            } 
        }

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
                    text: root.currentTab === 0 ? "  Clipboard" : root.currentTab === 1 ? "  Catatan" : "󰂞  Notifikasi"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    Text {
                        id: clearLbl
                        anchors.centerIn: parent
                        text: "\u{f00c2}  Hapus semua"
                        font.pixelSize: 10
                        color: clearMa.containsMouse ? Root.Colors.red : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: ["Clipboard", "Catatan", "Notifikasi"]

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

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    // Search box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 10
                        color: Root.Colors.surface0
                        border.color: clipInput.activeFocus ? Root.Colors.blue : Root.Colors.surface2
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

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
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

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
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                        }

                                        // Tombol hapus entry (muncul saat hover)
                                        Rectangle {
                                            visible: clipHover.hovered
                                            width: 22; height: 22; radius: 6
                                            color: delMa.containsMouse
                                                   ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.22)
                                                   : "transparent"
                                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

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
                    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }

                // ── TAB 2: NOTIFIKASI ─────────────────────────────────────
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    opacity: root.currentTab === 2 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    // Tombol hapus semua
                    RowLayout {
                        visible: Root.NotificationService.historyModel.count > 0
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: notifClearTxt.implicitWidth + 14
                            height: 24
                            radius: 7
                            color: notifClearMa.containsMouse
                                   ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.18)
                                   : Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            Text {
                                id: notifClearTxt
                                anchors.centerIn: parent
                                text: "Hapus semua"
                                font.pixelSize: 10
                                color: notifClearMa.containsMouse ? Root.Colors.red : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                            MouseArea {
                                id: notifClearMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Root.NotificationService.clearHistory()
                            }
                        }
                    }

                    // Kosong state
                    Item {
                        visible: Root.NotificationService.historyModel.count === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰂚"
                                font.pixelSize: 28
                                color: Root.Colors.surface2
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Tidak ada notifikasi"
                                font.pixelSize: 12
                                color: Root.Colors.subtext
                            }
                        }
                    }

                    // List notifikasi
                    Flickable {
                        id: notifFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: Root.NotificationService.historyModel.count > 0
                        contentWidth: width
                        contentHeight: notifCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: notifCol
                            width: notifFlick.width
                            spacing: 6

                            Repeater {
                                model: Root.NotificationService.historyModel

                                delegate: Rectangle {
                                    required property string appName
                                    required property string summary
                                    required property string body
                                    required property int urgency
                                    required property int index

                                    width: notifCol.width
                                    implicitHeight: notifItemCol.implicitHeight + 18
                                    radius: 10
                                    color: notifItemHover.containsMouse ? Root.Colors.surface0 : Root.Colors.base
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                    border.color: urgency === NotificationUrgency.Critical
                                        ? Root.Colors.red
                                        : Root.Colors.surface1
                                    border.width: 1

                                    ColumnLayout {
                                        id: notifItemCol
                                        anchors {
                                            top: parent.top; left: parent.left; right: parent.right
                                            margins: 10
                                        }
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: appName
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Root.Colors.subtext
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 18; height: 18; radius: 5
                                                color: notifXMa.containsMouse ? Root.Colors.surface1 : "transparent"
                                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰅖"; font.pixelSize: 10
                                                    color: Root.Colors.subtext
                                                }
                                                MouseArea {
                                                    id: notifXMa; anchors.fill: parent
                                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: Root.NotificationService.removeFromHistory(index)
                                                }
                                            }
                                        }

                                        Text {
                                            text: summary
                                            visible: text !== ""
                                            font.pixelSize: 12; font.bold: true
                                            color: Root.Colors.text
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: body
                                            visible: text !== ""
                                            font.pixelSize: 11
                                            color: Root.Colors.subtext
                                            wrapMode: Text.WordWrap
                                            textFormat: Text.PlainText
                                            Layout.fillWidth: true
                                        }
                                    }

                                    HoverHandler { id: notifItemHover }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
