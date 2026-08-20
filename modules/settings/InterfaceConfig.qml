import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    GroupBox {
        title: "Appearance"
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
                    text: "Theme:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                ComboBox {
                    model: ["Auto", "Light", "Dark", "Catppuccin Latte", "Catppuccin Frappe", "Catppuccin Macchiato", "Catppuccin Mocha"]
                    currentIndex: 1
                    
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
                    text: "Font Family:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                ComboBox {
                    model: ["Noto Sans", "Ubuntu", "JetBrains Mono", "Roboto Mono", "Fira Code"]
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
                    text: "Font Size:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                SpinBox {
                    from: 8
                    to: 24
                    value: 12
                }
                
                Text {
                    text: "px"
                    color: "#666666"
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
            }
            
            CheckBox {
                text: "Enable transparency effects"
                checked: true
            }
            
            CheckBox {
                text: "Use blurred backgrounds"
                checked: true
            }
        }
    }
    
    GroupBox {
        title: "Icon Settings"
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
                    text: "Icon Size:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                Slider {
                    id: iconSizeSlider
                    from: 16
                    to: 48
                    stepSize: 2
                    value: 24
                    Layout.preferredWidth: 200
                }
                
                Text {
                    text: (Math.round(iconSizeSlider.value)) + "px"
                    color: "#666666"
                    font.pixelSize: 12
                    width: 50
                }
                
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                Text {
                    text: "Icon Pack:"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                
                ComboBox {
                    model: ["Nerd Fonts", "Material Icons", "Font Awesome"]
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
        }
    }
    
    Item { Layout.fillHeight: true }
}
