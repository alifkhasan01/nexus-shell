pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../" as Root
import "./" as Dash

// Tab Info di Dashboard — system info dengan sparkline + cuaca.
// Membungkus dashboard/SystemInfo.qml.

Item {
    id: info

    signal setFaceRequested()

    Dash.SystemInfo {
        anchors.fill: parent
        onSetFaceRequested: info.setFaceRequested()
    }
}