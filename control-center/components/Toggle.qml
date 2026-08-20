pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Reusable pill toggle button — dipake buat Wifi/Bluetooth/DND/dll
// Usage:
//   Toggle {
//       icon: "󰤨"
//       label: "Wi-Fi"
//       active: someService.enabled
//       onToggled: someService.toggle()
//   }
Rectangle {
    id: root

    property string icon: "󰀫"
    property string label: "Toggle"
    property string sublabel: ""
    property bool active: false
    property bool loading: false

    signal toggled()
    signal longPressed()

    implicitWidth: 150
    implicitHeight: 58
    radius: 16
    color: active ? "#89b4fa" : "#313244"
    border.width: 1
    border.color: active ? "#89b4fa" : "#45475a"

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 10

        Text {
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: root.active ? "#1e1e2e" : "#cdd6f4"

            RotationAnimator on rotation {
                running: root.loading
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                color: root.active ? "#1e1e2e" : "#cdd6f4"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.sublabel.length > 0
                text: root.sublabel
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: root.active ? "#313244" : "#a6adc8"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.longPressed()
            } else {
                root.toggled()
            }
        }
        onPressAndHold: root.longPressed()

        onEntered: root.scale = 1.02
        onExited: root.scale = 1.0
        hoverEnabled: true
    }

    Behavior on scale { NumberAnimation { duration: 100 } }
}
