import QtQuick
import QtQuick.Controls
import "../" as Root

// Slider generik dengan label icon di kiri, dipakai buat volume & brightness.
// Pattern dragging guard: saat user drag, jangan biarkan nilai dari luar
// (Pipewire/MPRIS reactive binding) overwrite posisi thumb.
Item {
    id: root

    property string icon: ""
    property real value: 0     // nilai dari luar (0..1), binding ke Pipewire/MPRIS
    property real scrollStep: 0.05
    signal moved(real value)   // emit saat nilai berubah karena interaksi user

    height: 34

    // Ikon di kiri
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

        // Guard flag — saat true, binding dari luar diputus
        property bool dragging: false

        // Pattern dari VolumePanel.qml:
        // Saat dragging = true:  pakai nilai internal slider (freeze)
        // Saat dragging = false: pakai nilai dari luar (reactive binding)
        value: dragging ? slider.value : root.value

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

        // Emit saat thumb digeser
        onMoved: root.moved(slider.value)

        // Toggle dragging guard saat pressed/released
        onPressedChanged: {
            slider.dragging = pressed
            // Kirim nilai final saat jari/mouse dilepas
            if (!pressed) root.moved(slider.value)
        }
    }

    // Scroll handler — increment/decrement via scroll wheel
    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = root.scrollStep
            const delta = event.angleDelta.y > 0 ? step : -step
            // Basis dari root.value (nilai Pipewire), bukan slider.value
            const newVal = Math.max(0, Math.min(1, root.value + delta))
            slider.value = newVal
            root.moved(newVal)
        }
    }
}
