import QtQuick
import Quickshell.Services.UPower
import "../" as Root

Item {
    id: root
    width: label.width
    height: 20

    property var device: UPower.displayDevice
    property int percent: device?.percentage ? Math.round(device.percentage * 100) : 0
    property bool charging: device?.state === UPowerDeviceState.Charging

    Text {
        id: label
        anchors.centerIn: parent
        color: root.percent <= 15 && !root.charging ? Root.Colors.red : Root.Colors.text
        font.pixelSize: 14
        text: {
            let icon
            if (root.charging) icon = "󰂄"
            else if (root.percent >= 90) icon = "󰁹"
            else if (root.percent >= 60) icon = "󰂀"
            else if (root.percent >= 35) icon = "󰁾"
            else if (root.percent >= 15) icon = "󰁻"
            else icon = "󰂃"
            return icon + " " + root.percent + "%"
        }
    }
}
