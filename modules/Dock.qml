import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../" as Root

// Dock — PanelWindow di bawah, mirip Bar di atas.
// Visibility dikontrol dari shell.qml via shellState.dockVisible.

PanelWindow {
    id: dock

    anchors { bottom: true; left: true; right: true }
    margins.bottom: 2
    margins.left:   4
    margins.right:  4
    color: "transparent"

    // Tinggi = ikon + padding atas-bawah + dot di bawah + margin bawah
    readonly property int pillHeight: Root.DockConfig.baseSize
                                    + Root.DockConfig.dockPadV * 2
                                    + 8   // ruang dot

    implicitHeight: pillHeight + margins.bottom

    WlrLayershell.layer:         WlrLayer.Bottom
    WlrLayershell.exclusiveZone: implicitHeight
    WlrLayershell.namespace:     "quickshell-dock"

    // ── Pill ─────────────────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     dock.margins.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        // Lebar pas dengan konten saja
        width:  row.width + Root.DockConfig.dockPadH * 2
        height: dock.pillHeight

        radius:       height / 2
        color:        Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled:          true
            shadowColor:            "#55000000"
            shadowBlur:             0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset:   4
        }
    }

    // ── Row ikon ─────────────────────────────────────────────────────────
    Row {
        id: row
        anchors.centerIn: pill
        spacing: Root.DockConfig.itemSpacing

        Repeater {
            model: Root.DockConfig.pinnedApps

            DockItem {
                required property var modelData

                appName: modelData.name
                appIcon: modelData.icon
                appCmd:  modelData.cmd
                appId:   modelData.appId ?? ""
            }
        }
    }
}
