import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root
import "../modules/common/widgets" as Widgets

// Waffle Layout - Grid-based floating panel
// Alternative to traditional horizontal bar with grid of widgets

PanelWindow {
    id: waffle
    
    // Properties
    property var shellState: null
    property var procManager: null
    
    required property var modelData  // Screen info
    screen: modelData
    
    // Positioning
    anchors {
        top: true
        right: true
    }
    margins {
        top: 20
        right: 20
    }
    
    implicitWidth: 400
    implicitHeight: Math.min(contentHeight + 40, screen.geometry.height - 100)
    
    color: "transparent"
    
    // Wayland configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0  // Non-exclusive (floating)
    WlrLayershell.namespace: "quickshell-waffle"
    
    // Main content
    Rectangle {
        anchors.fill: parent
        color: Root.Colors.surface
        radius: 16
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 12
            samples: 16
            color: "#40000000"
            spread: 0.2
        }
        
        // Grid layout
        GridLayout {
            anchors {
                fill: parent
                margins: 16
            }
            
            columns: 4
            rowSpacing: 12
            columnSpacing: 12
            
            // Quick toggle buttons (4 columns x 2 rows)
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "🎨 Theme"
                prefixIcon: "🌓"
                onClicked: {
                    if (Root.ThemeLoader) {
                        Root.ThemeLoader.toggle()
                    }
                }
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "📱 WiFi"
                prefixIcon: "📡"
                onClicked: {
                    if (waffle.shellState) {
                        waffle.shellState.connectionOpen = !waffle.shellState.connectionOpen
                    }
                }
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "🔋 Battery"
                prefixIcon: "⚡"
                onClicked: console.log("[Waffle] Battery clicked")
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "🔊 Volume"
                prefixIcon: "🔉"
                onClicked: console.log("[Waffle] Volume clicked")
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "📅 Calendar"
                prefixIcon: "📆"
                onClicked: {
                    if (waffle.shellState) {
                        waffle.shellState.calendarOpen = !waffle.shellState.calendarOpen
                    }
                }
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "📎 Clipboard"
                prefixIcon: "📋"
                onClicked: {
                    if (waffle.shellState) {
                        waffle.shellState.clipboardOpen = !waffle.shellState.clipboardOpen
                    }
                }
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "⚙️ Settings"
                prefixIcon: "🔧"
                onClicked: console.log("[Waffle] Settings clicked")
            }
            
            Widgets.QuickButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "🎯 Inhibit"
                prefixIcon: "🚫"
                onClicked: console.log("[Waffle] Idle inhibitor clicked")
            }
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("[Waffle] Waffle layout initialized")
    }
}
