//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Window
import Quickshell
import "../../" as Root

// ──────────────────────────────────────────────────────────────────────────────
// Settings App — Caelestia-inspired design
//
// Layout:
//   ┌─────────────────────────────────────────────┐
//   │  ╔═══════════════════════════════════════╗  │
//   │  ║  Title bar (icon + name + close btn) ║  │
//   │  ╠═══════════════════════════════════════╣  │
//   │  ║  Tab bar: [Tampilan] [Umum] [Tentang]║  │
//   │  ║  ─── indicator bar ──────────────────║  │
//   │  ╠═══════════════════════════════════════╣  │
//   │  ║  Page content (scrollable)           ║  │
//   │  ╚═══════════════════════════════════════╝  │
//   └─────────────────────────────────────────────┘
// ──────────────────────────────────────────────────────────────────────────────

ApplicationWindow {
    id: root

    title: "Pengaturan"
    minimumWidth:  700
    minimumHeight: 500
    visible: true

    color: Root.Colors.base

    // Active tab index
    property int currentTab: 0

    // Tab model
    readonly property var tabs: [
        { icon: "󰕮", label: "Tampilan",  component: appearanceComp },
        { icon: "󰒓", label: "Umum",       component: generalComp    },
        { icon: "󰘥", label: "Layanan",    component: servicesComp   },
        { icon: "󰋗", label: "Tentang",    component: aboutComp      }
    ]

    // ── Smooth background color transition on theme change ────────────────
    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Title bar ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            color: Root.Colors.mantle

            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

            // Drag to move window
            DragHandler {
                target: null
                onActiveChanged: if (active) root.startSystemMove()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 12
                spacing: 10

                // App icon
                Text {
                    text: "󰒓"
                    font.family: Root.Appearance.font.family.iconNerd
                    font.pixelSize: 20
                    color: Root.Colors.lavender
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }

                // App title
                Text {
                    text: "Pengaturan"
                    font.family: Root.Appearance.font.family.main
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }

                Item { Layout.fillWidth: true }

                // Window controls
                Repeater {
                    model: ListModel {
                        ListElement { btnIcon: "󰖰"; action: "minimize" }
                        ListElement { btnIcon: "󰖯"; action: "maximize" }
                        ListElement { btnIcon: "󰅖"; action: "close"    }
                    }
                    delegate: Rectangle {
                        required property var  modelData
                        required property int  index

                        readonly property color hoverColor: {
                            if (index === 0) return Root.Colors.yellow
                            if (index === 1) return Root.Colors.green
                            return Root.Colors.red
                        }

                        width: 28; height: 28; radius: 8
                        color: winBtnMa.containsMouse
                            ? Qt.alpha(hoverColor, 0.25)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.btnIcon
                            font.family: Root.Appearance.font.family.iconNerd
                            font.pixelSize: 13
                            color: winBtnMa.containsMouse
                                ? parent.hoverColor
                                : Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: winBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "close")         root.close()
                                else if (modelData.action === "minimize") root.showMinimized()
                                else if (modelData.action === "maximize") {
                                    root.visibility === Window.Maximized
                                        ? root.showNormal()
                                        : root.showMaximized()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Tab bar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tabRow.implicitHeight + 16
            color: Root.Colors.mantle

            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

            // Bottom border / separator
            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Root.Colors.surface1
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }

            // Active tab sliding indicator
            Rectangle {
                id: tabIndicator
                anchors.bottom: parent.bottom
                height: 3
                radius: 2
                color: Root.Colors.lavender

                readonly property real tabWidth: tabRow.width / root.tabs.length
                x: root.currentTab * tabWidth + tabWidth * 0.15
                width: tabWidth * 0.7

                Behavior on x     { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                Behavior on width { NumberAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                Behavior on color { ColorAnimation  { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }

            Row {
                id: tabRow
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                Repeater {
                    model: root.tabs
                    delegate: Item {
                        required property var  modelData
                        required property int  index

                        width:  tabRow.width / root.tabs.length
                        height: tabRow.implicitHeight

                        readonly property bool active: root.currentTab === index

                        implicitHeight: tabColLayout.implicitHeight + 12

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }

                        // Hover ripple
                        Rectangle {
                            anchors.fill: parent
                            color: tabMa.containsMouse && !parent.active
                                ? Qt.alpha(Root.Colors.text, 0.05)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        ColumnLayout {
                            id: tabColLayout
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.family: Root.Appearance.font.family.iconNerd
                                font.pixelSize: 18
                                color: parent.parent.active ? Root.Colors.lavender : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                font.family: Root.Appearance.font.family.main
                                font.pixelSize: 11
                                font.weight: parent.parent.active ? Font.Medium : Font.Normal
                                color: parent.parent.active ? Root.Colors.lavender : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                            }
                        }
                    }
                }
            }
        }

        // ── Page content area ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Pages stack — all loaded, only visible one is shown
            Repeater {
                model: root.tabs
                delegate: Loader {
                    required property var modelData
                    required property int index

                    anchors.fill: parent
                    sourceComponent: modelData.component
                    active: true

                    // Fade in/out on tab switch
                    opacity: root.currentTab === index ? 1.0 : 0.0
                    visible: root.currentTab === index

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // ── Page components ───────────────────────────────────────────────────
    Component { id: appearanceComp; AppearancePage {} }
    Component { id: generalComp;    GeneralPage    {} }
    Component { id: servicesComp;   ServicesPage   {} }
    Component { id: aboutComp;      AboutPage      {} }
}
