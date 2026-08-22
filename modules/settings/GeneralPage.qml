import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../" as Root

ScrollView {
    id: root
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    readonly property var anim: Root.Appearance.animation.elementMoveFast

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        // ── Section: Bar ──────────────────────────────────────────────────
        SectionLabel { text: "Bar" }

        SettingRow {
            icon:     "󱇝"
            title:    "Verbose Mode"
            subtitle: "Tampilkan label teks di samping ikon di bar"
            ToggleSwitch {
                checked: Root.Config.options.bar.verbose
                onToggled: (v) => Root.Config.options.bar.verbose = v
            }
        }

        SectionSpacer {}

        // ── Section: Tampilan Tambahan ────────────────────────────────────
        SectionLabel { text: "Tampilan" }

        SettingRow {
            icon:     "󰌟"
            title:    "Extra Background Tint"
            subtitle: "Tambahkan sedikit warna aksen ke background"
            ToggleSwitch {
                checked: Root.Config.options.appearance.extraBackgroundTint
                onToggled: (v) => Root.Config.options.appearance.extraBackgroundTint = v
            }
        }

        SectionSpacer {}

        // ── Section: Aksi ─────────────────────────────────────────────────
        SectionLabel { text: "Aksi" }

        ActionRow {
            icon:      "󰑭"
            iconColor: Root.Colors.blue
            title:     "Muat Ulang Shell"
            subtitle:  "Restart quickshell tanpa log out"
            onClicked: reloadProc.running = true
        }

        ActionRow {
            icon:      "󰐥"
            iconColor: Root.Colors.red
            title:     "Matikan Shell"
            subtitle:  "Hentikan proses quickshell"
            onClicked: killProc.running = true
        }

        SectionSpacer {}

        // ── Section: Informasi ────────────────────────────────────────────
        SectionLabel { text: "Informasi Sistem" }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20; Layout.rightMargin: 20
            implicitHeight: sysCol.implicitHeight + 24
            radius: Root.Appearance.rounding.normal
            color: Root.Appearance.colors.colLayer1
            Behavior on color { ColorAnimation { duration: root.anim.duration } }

            ColumnLayout {
                id: sysCol
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 20; rightMargin: 20 }
                spacing: 10

                SysInfoRow { label: "Quickshell"; value: Quickshell.version ?? "unknown" }
                SysInfoRow { label: "Config";     value: "~/.config/quickshell" }
                SysInfoRow {
                    label: "Tema"
                    value: Root.Colors.currentTheme === "light" ? "Ayu Light" : "Ayu Dark"
                }
            }
        }

        Item { implicitHeight: 24 }
    }

    // ── Processes ─────────────────────────────────────────────────────────
    Process {
        id: reloadProc
        command: ["sh", "-c", "quickshell reload 2>/dev/null || qs reload 2>/dev/null &"]
    }
    Process {
        id: killProc
        command: ["sh", "-c", "pkill -f 'quickshell -p settings.qml'; pkill -f quickshell"]
    }

    // ── Inline components ─────────────────────────────────────────────────

    component SectionLabel: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 24; Layout.topMargin: 20; Layout.bottomMargin: 8
        font.family: Root.Appearance.font.family.main
        font.pixelSize: 11; font.weight: Font.Medium
        color: Root.Colors.lavender
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
    }

    component SectionSpacer: Item { implicitHeight: 8 }

    component SettingRow: Rectangle {
        id: sr
        property string icon:     ""
        property string title:    ""
        property string subtitle: ""
        default property alias controlSlot: ctrlBox.data

        Layout.fillWidth: true
        Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 4
        implicitHeight: srRow.implicitHeight + 24
        radius: Root.Appearance.rounding.normal
        color: Root.Appearance.colors.colLayer1
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

        RowLayout {
            id: srRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
            spacing: 14
            Text {
                text: sr.icon
                font.family: Root.Appearance.font.family.iconNerd; font.pixelSize: 18
                color: Root.Colors.lavender
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                    Layout.fillWidth: true; text: sr.title
                    font.family: Root.Appearance.font.family.main; font.pixelSize: 13
                    color: Root.Colors.text; elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
                Text {
                    Layout.fillWidth: true; text: sr.subtitle
                    font.family: Root.Appearance.font.family.main; font.pixelSize: 11
                    color: Root.Colors.subtext; elide: Text.ElideRight; visible: text.length > 0
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
            }
            Item {
                id: ctrlBox
                implicitWidth: childrenRect.width
                implicitHeight: childrenRect.height
            }
        }
    }

    component ActionRow: Rectangle {
        id: ar
        property string icon:      ""
        property color  iconColor: Root.Colors.blue
        property string title:     ""
        property string subtitle:  ""
        signal clicked()

        Layout.fillWidth: true
        Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 4
        implicitHeight: arRow.implicitHeight + 24
        radius: Root.Appearance.rounding.normal
        color: arMa.containsMouse ? Root.Appearance.colors.colLayer2 : Root.Appearance.colors.colLayer1
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            id: arRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
            spacing: 14

            Rectangle {
                width: 36; height: 36; radius: 10
                color: Qt.alpha(ar.iconColor, 0.15)
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                Text {
                    anchors.centerIn: parent; text: ar.icon
                    font.family: Root.Appearance.font.family.iconNerd; font.pixelSize: 18
                    color: ar.iconColor
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                    Layout.fillWidth: true; text: ar.title
                    font.family: Root.Appearance.font.family.main; font.pixelSize: 13
                    color: Root.Colors.text; elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
                Text {
                    Layout.fillWidth: true; text: ar.subtitle
                    font.family: Root.Appearance.font.family.main; font.pixelSize: 11
                    color: Root.Colors.subtext; elide: Text.ElideRight; visible: text.length > 0
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
            }
            Text {
                text: "󰅂"
                font.family: Root.Appearance.font.family.iconNerd; font.pixelSize: 14
                color: Root.Colors.subtext
            }
        }
        MouseArea {
            id: arMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: ar.clicked()
        }
    }

    component SysInfoRow: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        Text {
            text: parent.label
            font.family: Root.Appearance.font.family.main; font.pixelSize: 12
            color: Root.Colors.subtext
            Layout.preferredWidth: 110
            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
        }
        Text {
            text: parent.value
            font.family: Root.Appearance.font.family.monospace; font.pixelSize: 12
            color: Root.Colors.text
            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
        }
    }

    component ToggleSwitch: Rectangle {
        id: ts
        property bool checked: false
        signal toggled(bool v)

        implicitWidth: 44; implicitHeight: 24; radius: 12
        color: ts.checked ? Root.Colors.lavender : Root.Colors.surface2
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            x: ts.checked ? parent.width - width - 3 : 3
            y: 3; width: 18; height: 18; radius: 9
            color: Root.Colors.base
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { ts.checked = !ts.checked; ts.toggled(ts.checked) }
        }
    }
}
