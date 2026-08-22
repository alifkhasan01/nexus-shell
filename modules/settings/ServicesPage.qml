import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../" as Root

// ── Halaman Layanan ───────────────────────────────────────────────────────────
// Status layanan system yang dipakai shell: cek apakah binary tersedia.

ScrollView {
    id: root
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    readonly property var anim: Root.Appearance.animation.elementMoveFast

    // Service check results
    property var serviceStatus: ({})

    Component.onCompleted: checkAllServices()

    function checkAllServices() {
        const services = [
            "hyprctl", "wpctl", "brightnessctl", "bluetoothctl",
            "grimblast", "cliphist", "cava", "playerctl",
            "swww", "awww", "notify-send"
        ]
        for (const svc of services) {
            checkProc.check(svc)
        }
    }

    // Service checker
    QtObject {
        id: checkProc

        function check(name) {
            const p = Qt.createQmlObject(
                'import Quickshell.Io; Process { }',
                root, "dynProc"
            )
            p.command = ["sh", "-c", `which ${name} >/dev/null 2>&1 && echo ok || echo missing`]
            p.stdout = Qt.createQmlObject(
                'import Quickshell.Io; StdioCollector { }',
                p, "dynCol"
            )
            const capturedName = name
            p.stdout.onStreamFinished.connect(function() {
                const result = p.stdout.text.trim()
                const status = result === "ok"
                root.serviceStatus = Object.assign({}, root.serviceStatus, { [capturedName]: status })
                p.destroy()
            })
            p.running = true
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        // ── Section: Audio & Media ────────────────────────────────────────
        SectionHeader { text: "Audio & Media" }

        Repeater {
            model: [
                { icon: "󰕾", name: "wpctl",      label: "PipeWire / WirePlumber", desc: "Volume & audio routing"      },
                { icon: "󰎈", name: "playerctl",  label: "Playerctl",              desc: "MPRIS media player control" },
                { icon: "󱎔", name: "cava",        label: "Cava",                   desc: "Audio visualizer"           }
            ]
            delegate: ServiceCard {
                required property var modelData
                icon:    modelData.icon
                service: modelData.name
                label:   modelData.label
                desc:    modelData.desc
                status:  root.serviceStatus[modelData.name]
            }
        }

        SectionSpacer {}

        // ── Section: Display & Input ──────────────────────────────────────
        SectionHeader { text: "Display & Input" }

        Repeater {
            model: [
                { icon: "󰃟", name: "brightnessctl", label: "Brightnessctl", desc: "Kontrol kecerahan layar" },
                { icon: "󰸉", name: "swww",          label: "swww / awww",   desc: "Wallpaper daemon"        }
            ]
            delegate: ServiceCard {
                required property var modelData
                icon:    modelData.icon
                service: modelData.name
                label:   modelData.label
                desc:    modelData.desc
                status:  root.serviceStatus[modelData.name]
            }
        }

        SectionSpacer {}

        // ── Section: Wayland / Hyprland ───────────────────────────────────
        SectionHeader { text: "Wayland & Compositor" }

        Repeater {
            model: [
                { icon: "󱎴", name: "hyprctl",   label: "Hyprctl",    desc: "Hyprland IPC"             },
                { icon: "󰄜", name: "grimblast", label: "Grimblast",  desc: "Screenshot tool"          }
            ]
            delegate: ServiceCard {
                required property var modelData
                icon:    modelData.icon
                service: modelData.name
                label:   modelData.label
                desc:    modelData.desc
                status:  root.serviceStatus[modelData.name]
            }
        }

        SectionSpacer {}

        // ── Section: Utilitas ─────────────────────────────────────────────
        SectionHeader { text: "Utilitas" }

        Repeater {
            model: [
                { icon: "󰅍", name: "cliphist",    label: "Cliphist",    desc: "Clipboard history manager" },
                { icon: "󰂜", name: "bluetoothctl", label: "Bluetoothctl", desc: "Manajemen Bluetooth"       },
                { icon: "󰵗", name: "notify-send",  label: "Notify-send", desc: "Desktop notifications"     }
            ]
            delegate: ServiceCard {
                required property var modelData
                icon:    modelData.icon
                service: modelData.name
                label:   modelData.label
                desc:    modelData.desc
                status:  root.serviceStatus[modelData.name]
            }
        }

        // ── Re-check button ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin:  20
            Layout.rightMargin: 20
            Layout.topMargin: 20
            implicitHeight: 44
            radius: Root.Appearance.rounding.normal
            color: recheckMa.containsMouse
                ? Root.Appearance.colors.colPrimaryContainer
                : Root.Appearance.colors.colLayer1
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "󰑭"
                    font.family: Root.Appearance.font.family.iconNerd
                    font.pixelSize: 16
                    color: Root.Colors.lavender
                }
                Text {
                    text: "Cek Ulang Semua Layanan"
                    font.family: Root.Appearance.font.family.main
                    font.pixelSize: 13
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
            }
            MouseArea {
                id: recheckMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.serviceStatus = {}
                    root.checkAllServices()
                }
            }
        }

        Item { implicitHeight: 24 }
    }

    // ── Inline components ─────────────────────────────────────────────────

    component SectionHeader: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 24
        Layout.topMargin: 20
        Layout.bottomMargin: 8
        font.family: Root.Appearance.font.family.main
        font.pixelSize: 11
        font.weight: Font.Medium
        color: Root.Colors.lavender
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
    }

    component SectionSpacer: Item { implicitHeight: 8 }

    component ServiceCard: Rectangle {
        id: svc
        property string icon: ""
        property string service: ""
        property string label: ""
        property string desc: ""
        property var    status: undefined   // undefined=checking, true=ok, false=missing

        Layout.fillWidth: true
        Layout.leftMargin:  20
        Layout.rightMargin: 20
        Layout.topMargin: 4
        implicitHeight: svcRow.implicitHeight + 20
        radius: Root.Appearance.rounding.normal
        color: Root.Appearance.colors.colLayer1
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }

        RowLayout {
            id: svcRow
            anchors {
                left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                leftMargin: 16; rightMargin: 16
            }
            spacing: 14

            // Service icon
            Text {
                text: svc.icon
                font.family: Root.Appearance.font.family.iconNerd
                font.pixelSize: 20
                color: Root.Colors.lavender
                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
            }

            // Name + description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: svc.label
                    font.family: Root.Appearance.font.family.main
                    font.pixelSize: 13
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
                Text {
                    text: svc.desc
                    font.family: Root.Appearance.font.family.main
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration } }
                }
            }

            // Status badge
            Rectangle {
                implicitWidth: statusLabel.implicitWidth + 16
                implicitHeight: 22
                radius: 6
                color: {
                    if (svc.status === undefined) return Qt.alpha(Root.Colors.subtext, 0.15)
                    return svc.status
                        ? Qt.alpha(Root.Colors.green, 0.18)
                        : Qt.alpha(Root.Colors.red, 0.18)
                }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: {
                        if (svc.status === undefined) return "Cek..."
                        return svc.status ? "Tersedia" : "Tidak ada"
                    }
                    font.family: Root.Appearance.font.family.main
                    font.pixelSize: 11
                    color: {
                        if (svc.status === undefined) return Root.Colors.subtext
                        return svc.status ? Root.Colors.green : Root.Colors.red
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
