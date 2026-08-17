import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 20
    
    // Header
    ColumnLayout {
        spacing: 8
        
        Text {
            text: "Quickshell"
            color: "#1a1a1a"
            font.pixelSize: 28
            font.weight: Font.Bold
        }
        
        Text {
            text: "Personal Desktop Shell & Dashboard"
            color: "#666666"
            font.pixelSize: 14
        }
        
        Text {
            text: "Version: 2.1.0"
            color: "#999999"
            font.pixelSize: 12
            font.family: "monospace"
        }
    }
    
    Rectangle {
        height: 1
        Layout.fillWidth: true
        color: "#E0E0E0"
    }
    
    // Description
    GroupBox {
        title: "About This Project"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            Text {
                text: "Quickshell is a highly customizable desktop shell and dashboard for Linux, built with Qt and QML. It provides a modern, feature-rich environment for managing your desktop."
                color: "#1a1a1a"
                font.pixelSize: 12
                wrapText: true
                Layout.fillWidth: true
            }
            
            Text {
                text: "Features:"
                color: "#1a1a1a"
                font.weight: Font.Medium
                font.pixelSize: 12
            }
            
            ColumnLayout {
                spacing: 6
                
                Text {
                    text: "• Customizable panels and widgets"
                    color: "#1a1a1a"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "• Dashboard with media player and quick toggles"
                    color: "#1a1a1a"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "• Calendar system with notes and events"
                    color: "#1a1a1a"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "• System monitoring with live charts"
                    color: "#1a1a1a"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "• Multi-theme support (Catppuccin)"
                    color: "#1a1a1a"
                    font.pixelSize: 11
                }
            }
        }
    }
    
    // Links
    GroupBox {
        title: "Project Links"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            
            Button {
                text: "📚 Documentation"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#6750A4"
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: 12
                    font.pixelSize: 12
                }
                
                onClicked: {
                    console.log("[Settings] Opening documentation...")
                }
            }
            
            Button {
                text: "🐛 Report Issues"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#6750A4"
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: 12
                    font.pixelSize: 12
                }
                
                onClicked: {
                    console.log("[Settings] Opening issue tracker...")
                }
            }
            
            Button {
                text: "📦 Source Code"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#6750A4"
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: 12
                    font.pixelSize: 12
                }
                
                onClicked: {
                    console.log("[Settings] Opening repository...")
                }
            }
        }
    }
    
    // Config file info
    GroupBox {
        title: "Configuration"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            
            Text {
                text: "Configuration File:"
                color: "#1a1a1a"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#FFFFFF"
                radius: 4
                border.color: "#E0E0E0"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    Text {
                        text: "~/.config/quickshell/shell.qml"
                        color: "#1a1a1a"
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        text: "Copy"
                        
                        background: Rectangle {
                            color: "#6750A4"
                            radius: 3
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignCenter
                            font.pixelSize: 11
                        }
                        
                        onClicked: {
                            console.log("[Settings] Copied config path to clipboard")
                        }
                    }
                }
            }
            
            Text {
                text: "State File:"
                color: "#1a1a1a"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#FFFFFF"
                radius: 4
                border.color: "#E0E0E0"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    Text {
                        text: "~/.cache/quickshell/state.json"
                        color: "#1a1a1a"
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        text: "Copy"
                        
                        background: Rectangle {
                            color: "#6750A4"
                            radius: 3
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignCenter
                            font.pixelSize: 11
                        }
                        
                        onClicked: {
                            console.log("[Settings] Copied state path to clipboard")
                        }
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
