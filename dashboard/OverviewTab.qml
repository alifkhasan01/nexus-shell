pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../" as Root
import "./" as Dash

// Tab Overview di Dashboard — quick toggles + system stats + settings.
// Content dipindah dari kolom kiri Dashboard.qml (tanpa header jam).

Item {
    id: over

    // Shim agar QuickToggles bisa memanggil aksi dashboard
    property bool dndActive: false

    signal screenshotRequested()
    signal grimRequested()
    signal recorderToggleRequested()
    signal recorderMicToggleRequested()
    signal dndToggleRequested()
    signal notifyRequested(string icon, string summary, string body)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Quick toggles
        Dash.QuickToggles {
            Layout.fillWidth: true
            dashboardRoot: over
        }

        // System stats
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 10
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            Dash.SystemStats {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
            }
        }

        // Settings
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Root.Colors.base
            Behavior on color { ColorAnimation { duration: 200 } }

            Dash.SettingsTab {
                id: settingsContent
                anchors.top:    parent.top
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.margins: 10
            }
        }
    }
}