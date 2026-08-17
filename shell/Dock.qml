import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root
import "../modules/common/widgets" as Widgets

// Dock Component
// Taskbar with running apps, workspace switcher, and quick access

PanelWindow {
    id: dock
    
    // Properties
    property var shellState: null
    property list<string> runningApps: []
    property int currentWorkspace: 0
    property int workspaceCount: 4
    
    required property var modelData  // Screen info
    screen: modelData
    
    // Positioning
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: 20
        left: 20
        right: 20
    }
    
    implicitHeight: 70
    implicitWidth: Math.min(400, screen.geometry.width - 40)
    
    color: "transparent"
    
    // Wayland configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0  // Non-exclusive (floating)
    WlrLayershell.namespace: "quickshell-dock"
    
    // Main background
    Rectangle {
        anchors.fill: parent
        color: Root.Colors.surface
        radius: 12
        
        // Shadow
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 8
            samples: 12
            color: "#40000000"
            spread: 0.15
        }
        
        RowLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 16
            
            // LEFT: Workspace switcher
            RowLayout {
                spacing: 8
                
                Text {
                    text: "Workspaces:"
                    color: Root.Colors.onSurface
                    font.pixelSize: 11
                    font.bold: true
                }
                
                Repeater {
                    model: dock.workspaceCount
                    
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: dock.currentWorkspace === index ? Root.Colors.primary : Root.Colors.surfaceVariant
                        
                        Text {
                            anchors.centerIn: parent
                            text: (index + 1).toString()
                            color: dock.currentWorkspace === index ? Root.Colors.onPrimary : Root.Colors.onSurface
                            font.bold: true
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                dock.currentWorkspace = index
                                console.log(`[Dock] Switched to workspace ${index + 1}`)
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
            
            // SEPARATOR
            Rectangle {
                width: 1
                height: parent.height - 16
                color: Root.Colors.outline
            }
            
            // CENTER: Running apps
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                
                Text {
                    text: "Apps:"
                    color: Root.Colors.onSurface
                    font.pixelSize: 11
                    font.bold: true
                }
                
                // Placeholder app icons
                Repeater {
                    model: ["firefox", "thunderbird", "vscode"]
                    
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 4
                        color: Root.Colors.surfaceVariant
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase()
                            color: Root.Colors.onSurface
                            font.bold: true
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: console.log(`[Dock] Clicked app: ${modelData}`)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // SEPARATOR
            Rectangle {
                width: 1
                height: parent.height - 16
                color: Root.Colors.outline
            }
            
            // RIGHT: System tray
            RowLayout {
                spacing: 8
                
                Text {
                    text: "Tray:"
                    color: Root.Colors.onSurface
                    font.pixelSize: 11
                    font.bold: true
                }
                
                // Placeholder tray icons
                Repeater {
                    model: ["📡", "🔊", "⚡"]
                    
                    Text {
                        text: modelData
                        font.pixelSize: 16
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: console.log(`[Dock] Tray icon clicked`)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("[Dock] Dock component initialized")
    }
}
