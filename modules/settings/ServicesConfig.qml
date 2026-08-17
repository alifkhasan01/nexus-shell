import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    Text {
        text: "Enable/Disable Services"
        color: "#1a1a1a"
        font.pixelSize: 14
        font.weight: Font.Medium
    }
    
    GroupBox {
        title: "Core Services"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Calendar"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Weather Service"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Bluetooth Management"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Idle Management"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Audio Visualizer (Cava)"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Volume Control"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: true
                }
                Text {
                    text: "Brightness Control"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    GroupBox {
        title: "Advanced Features"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "#f5f5f5"
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            RowLayout {
                CheckBox {
                    checked: false
                }
                Text {
                    text: "System Monitoring"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Text {
                    text: "(CPU, Memory, Disk)"
                    color: "#999999"
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: false
                }
                Text {
                    text: "Network Status"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Text {
                    text: "(WiFi, Ethernet)"
                    color: "#999999"
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: false
                }
                Text {
                    text: "Media Controls"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Text {
                    text: "(MPRIS)"
                    color: "#999999"
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                CheckBox {
                    checked: false
                }
                Text {
                    text: "Clipboard Manager"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
