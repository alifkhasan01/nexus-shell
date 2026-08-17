import QtQuick
import QtQuick.Controls
import "../../.." as Root

// Reusable Quick Checkbox Component
// Standardized checkbox for consistent UI across all panels

CheckBox {
    id: root
    
    // Styling properties
    property color checkedColor: Root.Colors.primary
    property color uncheckedColor: Root.Colors.surface
    property color borderColor: Root.Colors.outline
    property color textColor: Root.Colors.onSurface
    property real boxSize: 20
    property real cornerRadius: 4
    property real borderWidth: 2
    
    // Animation properties
    property real animationDuration: 150
    
    indicator: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: root.boxSize
        implicitHeight: root.boxSize
        
        radius: root.cornerRadius
        color: root.checked ? root.checkedColor : root.uncheckedColor
        border.color: root.checked ? root.checkedColor : root.borderColor
        border.width: root.borderWidth
        
        Behavior on color {
            ColorAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }
        
        Behavior on border.color {
            ColorAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }
        
        // Checkmark
        Text {
            anchors.centerIn: parent
            text: "✓"
            color: Root.Colors.onPrimary
            font.pixelSize: root.boxSize - 6
            font.bold: true
            visible: root.checked
            opacity: root.checked ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: root.animationDuration
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
    
    contentItem: Text {
        text: root.text
        color: root.textColor
        font: root.font
        leftPadding: root.indicator.width + 8
        verticalAlignment: Text.AlignVCenter
    }
}
