import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root
import "../panels"
import "../bar/widgets"

// Compact Layout - Minimal version of horizontal bar
// Smaller footprint with essential widgets only

PanelWindow {
    id: compact
    
    // Properties
    property var shellState: null
    property var procManager: null
    
    required property var modelData  // Screen info
    screen: modelData
    
    // Positioning
    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: 0
    
    implicitHeight: 35
    
    color: "transparent"
    
    // Wayland configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: implicitHeight
    WlrLayershell.namespace: "quickshell-compact"
    
    // Main background
    Rectangle {
        anchors.fill: parent
        color: Root.Colors.mantle
        radius: 0
        
        // Rounded only bottom corners
        bottomLeftRadius: 8
        bottomRightRadius: 8
        topLeftRadius: 0
        topRightRadius: 0
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4
            
            // LEFT SIDE - Essential info
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    // Menu button
                    Button {
                        text: "≡"
                        font.pixelSize: 14
                        onClicked: {
                            if (compact.shellState) {
                                compact.shellState.menuOpen = !compact.shellState.menuOpen
                            }
                        }
                    }
                    
                    // Time
                    Clock {}
                    
                    // Active window
                    ActiveWindow {
                        Layout.maximumWidth: 200
                    }
                }
            }
            
            // RIGHT SIDE - Quick access buttons
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    // Network status
                    NetworkStatus {
                        panelOpen: false
                        onTogglePanel: {
                            if (compact.shellState) {
                                compact.shellState.connectionOpen = !compact.shellState.connectionOpen
                            }
                        }
                    }
                    
                    // Volume
                    Volume {}
                    
                    // Brightness
                    Brightness {}
                    
                    // Power menu
                    Button {
                        text: "⏻"
                        font.pixelSize: 12
                        onClicked: {
                            if (compact.shellState) {
                                compact.shellState.powerMenuOpen = !compact.shellState.powerMenuOpen
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("[Compact] Compact layout initialized")
    }
}
