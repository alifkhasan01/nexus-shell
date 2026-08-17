import QtQuick
import QtQuick.Controls
import "../../.." as Root

// Reusable Quick Slider Component
// Standardized slider for consistent UI across all panels

Slider {
    id: root
    
    // Styling properties
    property color backgroundColor: Root.Colors.surface
    property color trackColor: Root.Colors.surface1
    property color handleColor: Root.Colors.primary
    property color handleHoverColor: Root.Colors.primary
    property real trackHeight: 4
    property real handleSize: 16
    property real cornerRadius: 2
    
    // Animation properties
    property real animationDuration: 150
    
    from: 0
    to: 100
    stepSize: 1
    
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: root.trackHeight
        radius: root.cornerRadius
        color: root.trackColor
        
        // Fill track (progress)
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: root.cornerRadius
            color: root.handleColor
            
            Behavior on width {
                NumberAnimation {
                    duration: root.animationDuration
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
    
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        color: root.hovered ? root.handleHoverColor : root.handleColor
        
        Behavior on color {
            ColorAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }
        
        // Shadow effect
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 4
            samples: 8
            color: "#30000000"
            spread: 0.1
        }
    }
}
