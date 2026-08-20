import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../" as Root

// Panel pengaturan — layout ala aplikasi settings: sidebar kategori di kiri,
// halaman konten di kanan. Fitur: tema, transparansi, DND, buka settings
// lengkap, dan info. Mengikuti pola panel lain (slide dari kanan atas).
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()
    property var shellState: null

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    property int currentPage: 0

    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.exclusiveZone: 0

    // ── Klik luar untuk tutup ─────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Kartu ─────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 100

        width: 560
        height: Math.min(460, root.height - 20)

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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 28

                Text {
                    text: "󰒓  Settings"
                    font.pixelSize: 15
                    font.bold: true
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 26; height: 26; radius: 8
                    color: closeMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"; font.pixelSize: 11
                        color: Root.Colors.subtext
                    }
                    MouseArea {
                        id: closeMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
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

            // ── Isi: sidebar + konten ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // ── Sidebar kategori ─────────────────────────────────────
                ColumnLayout {
                    id: sidebar
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: [
                            { name: "Tampilan", icon: "󰕮", page: 0 },
                            { name: "Perilaku", icon: "󰅐", page: 1 },
                            { name: "Aksi",     icon: "󰕴", page: 2 },
                            { name: "Info",     icon: "󰋗", page: 3 }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 10
                            color: root.currentPage === modelData.page
                                ? Root.Colors.surface1
                                : (sideMa.containsMouse ? Root.Colors.surface0 : "transparent")
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 15
                                    color: root.currentPage === modelData.page
                                        ? Root.Colors.blue
                                        : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: 12
                                    font.bold: root.currentPage === modelData.page
                                    color: root.currentPage === modelData.page
                                        ? Root.Colors.text
                                        : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }
                            }

                            MouseArea {
                                id: sideMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentPage = modelData.page
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ── Divider vertikal ──────────────────────────────────────
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: Root.Colors.surface1
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }

                // ── Halaman konten ────────────────────────────────────────
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentPage

                    // ── Halaman Tampilan ─────────────────────────────────
                    ColumnLayout {
                        spacing: 8

                        PageHeader { text: "Tampilan" }

                        // Tema
                        SettingRow {
                            title: "Tema"
                            subtitle: Root.Colors.currentTheme === "light" ? "Ayu Light" : "Ayu Dark"
                            Layout.fillWidth: true
                            control: SwitchPill {
                                onState: Root.Colors.currentTheme === "dark"
                                onToggled: onState => Root.Colors.currentTheme = onState ? "dark" : "light"
                            }
                        }

                        // Transparansi
                        SettingRow {
                            title: "Transparansi"
                            subtitle: "Background transparan di panel & dashboard"
                            Layout.fillWidth: true
                            control: SwitchPill {
                                onState: Root.Config.options.appearance.transparency.enable
                                onToggled: onState => Root.Config.options.appearance.transparency.enable = onState
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Halaman Perilaku ─────────────────────────────────
                    ColumnLayout {
                        spacing: 8

                        PageHeader { text: "Perilaku" }

                        // DND
                        SettingRow {
                            title: "Do Not Disturb"
                            subtitle: "Tahan semua notifikasi"
                            Layout.fillWidth: true
                            control: SwitchPill {
                                onState: root.shellState ? root.shellState.dnd : false
                                onToggled: onState => { if (root.shellState) root.shellState.dnd = onState }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Halaman Aksi ─────────────────────────────────────
                    ColumnLayout {
                        spacing: 8

                        PageHeader { text: "Aksi" }

                        ActionRow {
                            icon: "󰕮"
                            title: "Buka Settings Lengkap"
                            subtitle: "Aplikasi settings dengan semua opsi"
                            Layout.fillWidth: true
                            onClicked: {
                                settingsProc.running = true
                                root.closeRequested()
                            }
                        }

                        ActionRow {
                            icon: "󰑭"
                            title: "Muatal Ulang Shell"
                            subtitle: "Restart quickshell"
                            Layout.fillWidth: true
                            onClicked: {
                                reloadProc.running = true
                                root.closeRequested()
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Halaman Info ─────────────────────────────────────
                    ColumnLayout {
                        spacing: 8

                        PageHeader { text: "Info" }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 10
                            color: Root.Colors.surface0
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: "Quickshell"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Root.Colors.text
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Quickshell.version
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    color: Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Personal desktop shell & dashboard untuk Linux, dibangun dengan Quickshell, Qt dan QML. Panel, widget, dan tema semuanya bisa dikustomisasi."
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                            wrapMode: Text.WordWrap
                            Layout.topMargin: 4
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    // ── Launcher settings app lengkap ─────────────────────────────────────
    Process {
        id: settingsProc
        command: ["sh", "-c", "cd ~/.config/quickshell && quickshell -p settings.qml &"]
    }

    Process {
        id: reloadProc
        command: ["sh", "-c", "quickshell --reload &"]
    }

    // ── Component: PageHeader ─────────────────────────────────────────────
    component PageHeader: Text {
        Layout.fillWidth: true
        font.pixelSize: 13
        font.bold: true
        color: Root.Colors.text
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
    }

    // ── Component: SettingRow ─────────────────────────────────────────────
    // Baris pengaturan: judul + subjudul di kiri, kontrol toggle di kanan.
    component SettingRow: RowLayout {
        id: settingRow

        property string title: ""
        property string subtitle: ""
        property Item control: null

        implicitHeight: 44
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: settingRow.title
                font.pixelSize: 12
                color: Root.Colors.text
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
            }
            Text {
                Layout.fillWidth: true
                text: settingRow.subtitle
                font.pixelSize: 10
                color: Root.Colors.subtext
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
            }
        }

        Item { Layout.fillWidth: true; width: 1 }

        Loader {
            sourceComponent: settingRow.control
        }
    }

    // ── Component: ActionRow ──────────────────────────────────────────────
    // Baris tombol aksi: ikon + judul + subjudul.
    component ActionRow: Rectangle {
        id: actionRow

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        signal clicked()

        implicitHeight: 48
        radius: 10
        color: actionMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: actionRow.icon
                font.pixelSize: 15
                color: Root.Colors.blue
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: actionRow.title
                    font.pixelSize: 12
                    color: Root.Colors.text
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }
                Text {
                    Layout.fillWidth: true
                    text: actionRow.subtitle
                    font.pixelSize: 10
                    color: Root.Colors.subtext
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                }
            }
            Text {
                text: "󰅂"
                font.pixelSize: 13
                color: Root.Colors.subtext
            }
        }

        MouseArea {
            id: actionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionRow.clicked()
        }
    }

    // ── Component: SwitchPill ─────────────────────────────────────────────
    // Toggle switch bergaya pill.
    component SwitchPill: Item {
        id: switchRoot

        property bool onState: false
        signal toggled(bool onState)

        width: 40
        height: 22

        Rectangle {
            anchors.fill: parent
            radius: 11
            color: switchRoot.onState ? Root.Colors.blue : Root.Colors.surface1
            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: Root.Colors.text
                x: switchRoot.onState ? switchRoot.width - width - 3 : 3
                y: (switchRoot.height - height) / 2
                Behavior on x { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: switchRoot.toggled(!switchRoot.onState)
            }
        }
    }
}