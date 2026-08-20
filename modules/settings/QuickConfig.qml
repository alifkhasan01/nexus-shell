import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    // Panel Settings Group
    GroupBox {
        title: "Panel Settings"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            // Panel height
            RowLayout {
                Text {
                    text: "Panel Height:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                SpinBox {
                    from: 30
                    to: 100
                    value: 50
                }
                
                Text {
                    text: "px"
                    color: "#666666"
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // Panel opacity
            RowLayout {
                Text {
                    text: "Panel Opacity:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                Slider {
                    id: opacitySlider
                    from: 0
                    to: 1
                    stepSize: 0.05
                    value: 0.95
                    Layout.preferredWidth: 150
                }
                
                Text {
                    text: Math.round(opacitySlider.value * 100) + "%"
                    color: "#666666"
                    font.pixelSize: 12
                    width: 40
                }
            }
        }
    }
    
    // Behavior Group
    GroupBox {
        title: "Behavior"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            RowLayout {
                CheckBox {
                    text: "Remember panel states on exit"
                    checked: true
                    enabled: false
                }
                
                Text {
                    text: "(Always enabled)"
                    color: "#999999"
                    font.pixelSize: 11
                }
                
                Item { Layout.fillWidth: true }
            }
            
            CheckBox {
                text: "Show welcome panel on first run"
                checked: true
            }
            
            CheckBox {
                text: "Enable notifications"
                checked: true
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
