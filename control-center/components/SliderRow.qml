pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Slider row dengan icon dinamis (berubah sesuai value, misal mute state)
// Usage:
//   SliderRow {
//       icon: value > 0 ? "󰕾" : "󰝟"
//       value: Pipewire.defaultAudioSink.audio.volume
//       onMoved: (v) => Pipewire.defaultAudioSink.audio.volume = v
//   }
Item {
    id: root

    property string icon: "󰕾"
    property real value: 0.5 // 0.0 - 1.0
    property bool disabled: false

    signal moved(real value)
    signal iconClicked()

    implicitHeight: 44
    implicitWidth: 260

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: "#cdd6f4"
            Layout.preferredWidth: 22

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: root.iconClicked()
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            value: root.value
            enabled: !root.disabled

            onMoved: root.moved(value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 6
                radius: 3
                color: "#313244"

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 3
                    color: root.disabled ? "#585b70" : "#89b4fa"
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16
                height: 16
                radius: 8
                color: "#cdd6f4"
                border.color: "#89b4fa"
                border.width: slider.pressed ? 2 : 0
            }
        }

        Text {
            text: Math.round(root.value * 100) + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#a6adc8"
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
        }
    }
}
