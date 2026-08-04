import QtQuick
import QtQuick.Controls
import "../" as Root

// Slider generik dengan label icon di kiri, dipakai buat volume & brightness.
Item {
    id: root

    property string icon: ""
    property real value: 0     // 0..1
    property real scrollStep: 0.05
    signal moved(real value)

    height: 34

    Item {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: 26
        height: 26
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: 15
            color: Root.Colors.subtext
        }
    }

    Slider {
        id: slider
        anchors.left: parent.left
        anchors.leftMargin: 30
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        from: 0
        to: 1
        value: root.value

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Root.Colors.surface0

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: Root.Colors.blue
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: Root.Colors.text
        }

        onMoved: root.moved(slider.value)
    }

    // Scroll handler — WheelHandler lebih reliable dari MouseArea.onWheel
    // di Qt 6 karena tidak konflik dengan Slider drag events.
    WheelHandler {
        target: null          // tangani manual, jangan forward ke Slider
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = root.scrollStep
            const delta = event.angleDelta.y > 0 ? step : -step
            const newVal = Math.max(0, Math.min(1, slider.value + delta))
            slider.value = newVal
            root.moved(newVal)
        }
    }
}
