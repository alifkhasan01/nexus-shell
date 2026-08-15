import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../" as Root

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property var command: []
    property color accentColor: Root.Colors.blue
    property bool highlighted: false
    property string notifyTitle: ""
    property string notifyBody: ""

    signal triggered()

    implicitWidth: 170
    implicitHeight: 140
    radius: 16
    
    color: highlighted 
        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
        : (ma.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)
    
    border.width: highlighted ? 2 : 1
    border.color: highlighted 
        ? accentColor
        : (ma.containsMouse ? Root.Colors.surface2 : "transparent")
    
    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    
    scale: ma.pressed ? 0.95 : (ma.containsMouse || highlighted ? 1.02 : 1.0)

    // Gradient overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        opacity: ma.containsMouse || highlighted ? 0.05 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.accentColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        width: parent.width - 24

        // Icon circle
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: 32
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 
                          ma.containsMouse || highlighted ? 0.2 : 0.1)
            border.width: 2
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b,
                                 ma.containsMouse || highlighted ? 0.4 : 0.2)
            
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 32
                color: ma.containsMouse || highlighted ? root.accentColor : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.8)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Text {
            text: root.label
            font.pixelSize: 14
            font.weight: Font.Medium
            color: ma.containsMouse || highlighted ? Root.Colors.text : Root.Colors.subtext
            Layout.alignment: Qt.AlignHCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root._doActivate()
    }

    Process { 
        id: proc
        command: root.command 
    }
    
    Process {
        id: notifyProc
    }

    function _doActivate() {
        root.triggered()
        if (root.command.length === 0) return
        if (root.notifyTitle !== "") {
            notifyProc.command = ["notify-send",
                "-a", "Power",
                "-i", "system-shutdown-symbolic",
                "-t", "3000",
                "-u", "normal",
                root.notifyTitle,
                root.notifyBody
            ]
            notifyProc.startDetached()
        }
        proc.startDetached()
    }

    function activate() {
        root._doActivate()
    }
}
