import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../" as Root

// ── Halaman Tentang ───────────────────────────────────────────────────────────

ScrollView {
    id: root
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    readonly property var anim: Root.Appearance.animation.elementMoveFast

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        // ── Hero card ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 20
            implicitHeight: heroCol.implicitHeight + 40
            radius: Root.Appearance.rounding.large
            color: Root.Appearance.colors.colLayer1

            // Subtle gradient overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(Root.Colors.lavender, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Behavior on color { ColorAnimation { duration: root.anim.duration } }

            ColumnLayout {
                id: heroCol
                anchors {
                    left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                    leftMargin: 24; rightMargin: 24
                }
                spacing: 8

                // App icon + name row
                RowLayout {
                    spacing: 16

                    // Big icon
                    Rectangle {
                        width: 56; height: 56
                        radius: 16
                        color: Qt.alpha(Root.Colors.lavender, 0.18)
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            font.family: Root.Appearance.font.family.iconNerd
                            font.pixelSize: 28
                            color: Root.Colors.lavender
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: "Nexus Shell"
                            font.family: Root.Appearance.font.family.main
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                        Text {
                            text: "Desktop shell berbasis Quickshell"
                            font.family: Root.Appearance.font.family.main
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }
                }

                // Version badge
                RowLayout {
                    spacing: 8

                    Rectangle {
                        implicitWidth: verText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 6
                        color: Qt.alpha(Root.Colors.blue, 0.18)
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        Text {
                            id: verText
                            anchors.centerIn: parent
                            text: "QS " + (Quickshell.version ?? "dev")
                            font.family: Root.Appearance.font.family.monospace
                            font.pixelSize: 11
                            color: Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }

                    Rectangle {
                        implicitWidth: themeText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 6
                        color: Qt.alpha(Root.Colors.lavender, 0.18)
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        Text {
                            id: themeText
                            anchors.centerIn: parent
                            text: Root.Colors.currentTheme === "light" ? "Ayu Light" : "Ayu Dark"
                            font.family: Root.Appearance.font.family.main
                            font.pixelSize: 11
                            color: Root.Colors.lavender
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 12 }

        // ── Section: Stack Teknologi ──────────────────────────────────────
        SectionHeader { text: "Stack Teknologi" }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            implicitHeight: techGrid.implicitHeight + 24
            radius: Root.Appearance.rounding.normal
            color: Root.Appearance.colors.colLayer1
            Behavior on color { ColorAnimation { duration: root.anim.duration } }

            GridLayout {
                id: techGrid
                anchors {
                    left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                    leftMargin: 16; rightMargin: 16
                }
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                Repeater {
                    model: [
                        { icon: "󰘦", color: Root.Colors.blue,    label: "Quickshell",   desc: "Shell framework"     },
                        { icon: "󰘫", color: Root.Colors.green,   label: "Qt / QML",     desc: "UI toolkit"          },
                        { icon: "󱎴", color: Root.Colors.mauve,   label: "Hyprland",     desc: "Wayland compositor"  },
                        { icon: "󰌢", color: Root.Colors.peach,   label: "Wayland",      desc: "Display protocol"    },
                        { icon: "󰎈", color: Root.Colors.yellow,  label: "PipeWire",     desc: "Audio server"        },
                        { icon: "󰊠", color: Root.Colors.lavender,"label": "Ayu Theme",  desc: "Color palette"       }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        spacing: 10

                        Rectangle {
                            width: 34; height: 34; radius: 10
                            color: Qt.alpha(modelData.color, 0.15)
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: Root.Appearance.font.family.iconNerd
                                font.pixelSize: 16
                                color: modelData.color
                                Behavior on color { ColorAnimation { duration: root.anim.duration } }
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: modelData.label
                                font.family: Root.Appearance.font.family.main
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Root.Colors.text
                                Behavior on color { ColorAnimation { duration: root.anim.duration } }
                            }
                            Text {
                                text: modelData.desc
                                font.family: Root.Appearance.font.family.main
                                font.pixelSize: 10
                                color: Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: root.anim.duration } }
                            }
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 8 }

        // ── Section: Paths ────────────────────────────────────────────────
        SectionHeader { text: "Path Konfigurasi" }

        Repeater {
            model: [
                { icon: "󰉋", label: "Config",  path: "~/.config/quickshell"     },
                { icon: "󰆓", label: "Data",    path: "~/.config/quickshell/data" },
                { icon: "󰘓", label: "Cache",   path: "~/.cache/quickshell"       }
            ]
            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin:  20
                Layout.rightMargin: 20
                Layout.topMargin: 4
                implicitHeight: pathRow.implicitHeight + 20
                radius: Root.Appearance.rounding.normal
                color: Root.Appearance.colors.colLayer1
                Behavior on color { ColorAnimation { duration: root.anim.duration } }

                RowLayout {
                    id: pathRow
                    anchors {
                        left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                        leftMargin: 16; rightMargin: 16
                    }
                    spacing: 12

                    Text {
                        text: modelData.icon
                        font.family: Root.Appearance.font.family.iconNerd
                        font.pixelSize: 18
                        color: Root.Colors.lavender
                        Behavior on color { ColorAnimation { duration: root.anim.duration } }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.label
                            font.family: Root.Appearance.font.family.main
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                        Text {
                            text: modelData.path
                            font.family: Root.Appearance.font.family.monospace
                            font.pixelSize: 12
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: root.anim.duration } }
                        }
                    }

                    // Copy button
                    Rectangle {
                        implicitWidth: 28; implicitHeight: 28
                        radius: 8
                        color: copyMa.containsMouse
                            ? Root.Appearance.colors.colLayer2
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰆏"
                            font.family: Root.Appearance.font.family.iconNerd
                            font.pixelSize: 13
                            color: copyMa.containsMouse ? Root.Colors.blue : Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: copyMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            property string pathToCopy: parent.parent.parent.modelData.path
                            onClicked: {
                                copyProc.command = ["sh", "-c",
                                    `echo '${pathToCopy.replace("~", "$HOME")}' | wl-copy`]
                                copyProc.running = true
                            }
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 24 }
    }

    Process { id: copyProc }

    // ── Inline components ─────────────────────────────────────────────────
    component SectionHeader: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 24
        Layout.topMargin: 16
        Layout.bottomMargin: 8
        font.family: Root.Appearance.font.family.main
        font.pixelSize: 11
        font.weight: Font.Medium
        color: Root.Colors.lavender
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
    }
}
