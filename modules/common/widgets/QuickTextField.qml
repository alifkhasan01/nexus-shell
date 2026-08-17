import QtQuick
import QtQuick.Controls
import "../../.." as Root

// Reusable Quick TextField Component
// Standardized text input for consistent UI across all panels

TextField {
    id: root
    
    // Styling properties
    property color backgroundColor: Root.Colors.surface
    property color borderColor: Root.Colors.outline
    property color focusColor: Root.Colors.primary
    property color textColor: Root.Colors.onSurface
    property color placeholderColor: Root.Colors.onSurfaceVariant
    property real borderWidth: 1
    property real cornerRadius: 8
    property real padding: 12
    
    // Size properties
    implicitWidth: 200
    implicitHeight: 40
    
    // Animation properties
    property real animationDuration: 150
    
    color: root.textColor
    placeholderTextColor: root.placeholderColor
    
    background: Rectangle {
        color: root.backgroundColor
        radius: root.cornerRadius
        border.color: root.activeFocus ? root.focusColor : root.borderColor
        border.width: root.borderWidth
        
        Behavior on border.color {
            ColorAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }
    
    padding: root.padding
    
    // Remove default placeholder styling
    selectByMouse: true
    
    // Cursor styling
    cursorDelegate: Rectangle {
        color: root.textColor
        width: 2
        height: root.contentHeight - (root.padding * 2)
        
        SequentialAnimation on visible {
            id: cursorAnimation
            running: root.activeFocus
            
            PropertyAction { value: true }
            PauseAnimation { duration: 500 }
            PropertyAction { value: false }
            PauseAnimation { duration: 500 }
            loops: Animation.Infinite
        }
    }
}
