import QtQuick
import QtQuick.Controls
import "../../.." as Root

// Reusable Quick Button Component
// Standardized button for consistent UI across all panels

Button {
    id: root
    
    // Styling properties
    property color backgroundColor: Root.Colors.surface
    property color hoverColor: Root.Colors.surface1
    property color pressedColor: Root.Colors.surface2
    property color textColor: Root.Colors.onSurface
    property real cornerRadius: 8
    property real padding: 12
    
    // Size properties
    property real prefixIconSize: 14
    property real suffixIconSize: 14
    
    // Icon properties
    property string prefixIcon: ""
    property string suffixIcon: ""
    property bool showBackground: true
    
    // Animation properties
    property real animationDuration: 150
    
    implicitWidth: contentItem.implicitWidth + (padding * 2)
    implicitHeight: contentItem.implicitHeight + (padding * 2)
    
    background: Rectangle {
        color: {
            if (!showBackground) return "transparent"
            if (root.pressed) return root.pressedColor
            if (root.hovered) return root.hoverColor
            return root.backgroundColor
        }
        radius: root.cornerRadius
        
        Behavior on color {
            ColorAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }
    
    contentItem: Row {
        spacing: 8
        padding: root.padding
        
        // Prefix icon
        Text {
            visible: root.prefixIcon !== ""
            text: root.prefixIcon
            font.pixelSize: root.prefixIconSize
            color: root.textColor
            verticalAlignment: Text.AlignVCenter
        }
        
        // Text
        Text {
            text: root.text
            color: root.textColor
            font: root.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        
        // Suffix icon
        Text {
            visible: root.suffixIcon !== ""
            text: root.suffixIcon
            font.pixelSize: root.suffixIconSize
            color: root.textColor
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    // Hover effect
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse.accepted = false
    }
}
