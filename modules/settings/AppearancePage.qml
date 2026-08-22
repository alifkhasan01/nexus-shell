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

        // ── Section: Tema ─────────────────────────────────────────────────
        SectionLabel { text: "Tema" }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20; Layout.rightMargin: 20
            implicitHeight: themeRow.implicitHeight + 32
            radius: Root.Appearance.rounding.normal
            color: Root.Appearance.colors.colLayer1
            Behavior on color { ColorAnimation { duration: root.anim.duration } }

            RowLayout {
                id: themeRow
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20; rightMargin: 20
                }
                spacing: 16

                // Light theme card
                ThemePreviewCard {
                    themeId:  "light"
                    label:    "Ayu Light"
                    bgColor:  "#fafafa"
                    sfColor:  "#e7e8e9"
                    txtColor: "#575f66"
                    acColor:  "#a37acc"
                }

                // Dark theme card
                ThemePreviewCard {
                    themeId:  "dark"
                    label:    "Ayu Dark"
                    bgColor:  "#0d1017"
                    sfColor:  "#131721"
                    txtColor: "#bfbdb6"
                    acColor:  "#d2a6ff"
                }
            }
        }

        SectionSpacer {}

        // ── Section: Transparansi ─────────────────────────────────────────
        SectionLabel { text: "Transparansi" }

        // Enable transparency toggle
        SettingRow {
            icon:     "󰆏"
            title:    "Aktifkan Transparansi"
            subtitle: "Background panel & dashboard menjadi tembus pandang"

            ToggleSwitch {
                checked: Root.Config.options.appearance.transparency.enable
                onToggled: (v) => Root.Config.options.appearance.transparency.enable = v
            }
        }

        // Automatic toggle (greyed out when transparency disabled)
        SettingRow {
            icon:     "󰋙"
            title:    "Transparansi Otomatis"
            subtitle: "Dihitung otomatis dari warna wallpaper"
            dimmed:   !Root.Config.options.appearance.transparency.enable

            ToggleSwitch {
                checked: Root.Config.options.appearance.transparency.automatic
                enabled: Root.Config.options.appearance.transparency.enable
                onToggled: (v) => Root.Config.options.appearance.transparency.automatic = v
            }
        }

        // Manual slider
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 4
            implicitHeight: sliderCol.implicitHeight + 24
            radius: Root.Appearance.rounding.normal
            color: Root.Appearance.colors.colLayer1
            visible: Root.Config.options.appearance.transparency.enable
            opacity: Root.Config.options.appearance.transparency.automatic ? 0.4 : 1.0
            Behavior on color   { ColorAnimation { duration: root.anim.duration } }
            Behavior on opacity { NumberAnimation { duration: root.anim.duration } }

            ColumnLayout {
                id: sliderCol
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20; rightMargin: 20
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Tingkat Transparansi"
                        font.family: Root.Appearance.font.family.main
                        font.pixelSize: 13
                        color: Root.Colors.text
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(bgSlider.value * 100) + "%"
                        font.family: Root.Appearance.font.family.main
                        font.pixelSize: 12
                        color: Root.Colors.lavender
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                    }
                }

                Slider {
                    id: bgSlider
                    Layout.fillWidth: true
                    from: 0; to: 0.5; stepSize: 0.01
                    value: Root.Config.options.appearance.transparency.backgroundTransparency
                    enabled: Root.Config.options.appearance.transparency.enable
                             && !Root.Config.options.appearance.transparency.automatic
                    onMoved: Root.Config.options.appearance.transparency.backgroundTransparency = value

                    background: Rectangle {
                        x: bgSlider.leftPadding
                        y: bgSlider.topPadding + bgSlider.availableHeight / 2 - height / 2
                        width: bgSlider.availableWidth; height: 4; radius: 2
                        color: Root.Colors.surface2
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        Rectangle {
                            width: bgSlider.visualPosition * parent.width
                            height: parent.height; radius: parent.radius
                            color: Root.Colors.lavender
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }
                    handle: Rectangle {
                        x: bgSlider.leftPadding + bgSlider.visualPosition * bgSlider.availableWidth - width / 2
                        y: bgSlider.topPadding + bgSlider.availableHeight / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: bgSlider.pressed ? Root.Colors.lavender : Root.Colors.mantle
                        border.color: Root.Colors.lavender; border.width: 2
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }
        }

        SectionSpacer {}

        // ── Section: Warna Aksen ──────────────────────────────────────────
        SectionLabel { text: "Pratinjau Warna Aksen" }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20; Layout.rightMargin: 20
            implicitHeight: accentGrid.implicitHeight + 28
            radius: Root.Appearance.rounding.normal
            color: Root.Appearance.colors.colLayer1
            Behavior on color { ColorAnimation { duration: root.anim.duration } }

            GridLayout {
                id: accentGrid
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20; rightMargin: 20
                }
                columns: 8; columnSpacing: 10; rowSpacing: 10

                Repeater {
                    // Plain strings — no Root.Colors in model literal
                    model: ["lavender","blue","green","yellow","peach","red","mauve","text"]
                    delegate: ColumnLayout {
                        required property string modelData
                        spacing: 4
                        Rectangle {
                            width: 30; height: 30; radius: 8
                            color: Root.Colors[parent.modelData] ?? "transparent"
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                        Text {
                            text: parent.modelData.charAt(0).toUpperCase() + parent.modelData.slice(1)
                            font.family: Root.Appearance.font.family.main
                            font.pixelSize: 9
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }
                }
            }
        }

        SectionSpacer {}

        // ── Section: Font ─────────────────────────────────────────────────
        SectionLabel { text: "Font" }

        InfoRow { icon: "󰊄"; title: "Font Utama";     value: Root.Config.options.appearance.fonts.main      }
        InfoRow { icon: "󰘦"; title: "Font Monospace";  value: Root.Config.options.appearance.fonts.monospace }

        Item { implicitHeight: 24 }
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

    // Theme preview card — plain properties, no Root.Colors in the model
    component ThemePreviewCard: Rectangle {
        property string themeId:  ""
        property string label:    ""
        property string bgColor:  "#000000"
        property string sfColor:  "#111111"
        property string txtColor: "#ffffff"
        property string acColor:  "#888888"

        readonly property bool selected: Root.Colors.currentTheme === themeId

        Layout.fillWidth: true
        implicitHeight: 90
        radius: Root.Appearance.rounding.small
        color: bgColor
        border.width: selected ? 2 : 1
        border.color: selected ? Root.Colors.lavender : Root.Colors.overlay0
        Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.Colors.currentTheme = parent.themeId
        }

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 6

            Rectangle {
                Layout.fillWidth: true; height: 18; radius: 5
                color: parent.parent.sfColor
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 6 }
                    spacing: 4
                    Repeater {
                        model: 3
                        Rectangle { width: 6; height: 6; radius: 3; color: parent.parent.parent.parent.acColor }
                    }
                }
            }
            Text {
                text: parent.parent.label
                font.family: Root.Appearance.font.family.main
                font.pixelSize: 12
                font.weight: parent.parent.selected ? Font.Medium : Font.Normal
                color: parent.parent.txtColor
            }
        }

        Rectangle {
            visible: parent.selected
            anchors { right: parent.right; top: parent.top; margins: 8 }
            width: 20; height: 20; radius: 10
            color: Root.Colors.lavender
            Text {
                anchors.centerIn: parent
                text: "󰄬"
                font.family: Root.Appearance.font.family.iconNerd
                font.pixelSize: 12
                color: Root.Colors.base
            }
        }
    }

    // Setting row with inline control slot (no property Item)
    component SettingRow: Rectangle {
        id: sr
        property string icon:     ""
        property string title:    ""
        property string subtitle: ""
        property bool   dimmed:   false
        default property alias controlSlot: controlContainer.data

        Layout.fillWidth: true
        Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 4
        implicitHeight: srRow.implicitHeight + 24
        radius: Root.Appearance.rounding.normal
        color: Root.Appearance.colors.colLayer1
        opacity: sr.dimmed ? 0.45 : 1.0
        Behavior on color   { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
        Behavior on opacity { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

        RowLayout {
            id: srRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
            spacing: 14

            Text {
                text: sr.icon
                font.family: Root.Appearance.font.family.iconNerd
                font.pixelSize: 18
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
                id: controlContainer
                implicitWidth:  childrenRect.width
                implicitHeight: childrenRect.height
            }
        }
    }

    component InfoRow: Rectangle {
        property string icon:  ""
        property string title: ""
        property string value: ""

        Layout.fillWidth: true
        Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.topMargin: 4
        implicitHeight: irRow.implicitHeight + 24
        radius: Root.Appearance.rounding.normal
        color: Root.Appearance.colors.colLayer1
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

        RowLayout {
            id: irRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
            spacing: 14
            Text {
                text: parent.parent.icon
                font.family: Root.Appearance.font.family.iconNerd; font.pixelSize: 18
                color: Root.Colors.lavender
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }
            Text {
                Layout.fillWidth: true; text: parent.parent.title
                font.family: Root.Appearance.font.family.main; font.pixelSize: 13
                color: Root.Colors.text
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }
            Text {
                text: parent.parent.value
                font.family: Root.Appearance.font.family.monospace; font.pixelSize: 11
                color: Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }
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
