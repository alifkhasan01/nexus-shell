import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    GroupBox {
        title: "General Settings"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            RowLayout {
                Text {
                    text: "Verbose Logging:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                CheckBox {
                    checked: false
                }
                
                Text {
                    text: "Show detailed logs in console"
                    color: "#666666"
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                Text {
                    text: "Corner Style:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                ComboBox {
                    model: ["Rounded", "Sharp", "Beveled"]
                    currentIndex: 0
                    
                    background: Rectangle {
                        color: "#FFFFFF"
                        border.color: "#E0E0E0"
                        border.width: 1
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.currentText
                        color: "#1a1a1a"
                        leftPadding: 8
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                Text {
                    text: "UI Responsiveness:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                Slider {
                    from: 0
                    to: 1
                    stepSize: 0.1
                    value: 0.8
                    Layout.preferredWidth: 200
                }
                
                Text {
                    text: (Math.round(value * 100)) + "%"
                    color: "#666666"
                    font.pixelSize: 12
                    width: 50
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    GroupBox {
        title: "System Integration"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            CheckBox {
                text: "Auto-start on login"
                checked: true
            }
            
            CheckBox {
                text: "Enable idle management"
                checked: true
            }
            
            CheckBox {
                text: "Monitor system updates"
                checked: false
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
