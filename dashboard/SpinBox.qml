import QtQuick
import QtQuick.Layouts
import "../" as Root

// Simple SpinBox untuk input angka
Rectangle {
    id: spinBox
    
    property int value: 5
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: ""
    
    signal valueModified()
    
    implicitHeight: 36
    radius: 8
    color: Root.Colors.surface0
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        
        // Tombol minus
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            radius: 6
            color: minusArea.containsPress ? Root.Colors.surface1 : "transparent"
            
            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: 16
                color: spinBox.value > spinBox.from ? Root.Colors.text : Root.Colors.overlay0
            }
            
            MouseArea {
                id: minusArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: spinBox.value > spinBox.from
                onClicked: {
                    if (spinBox.value > spinBox.from) {
                        spinBox.value -= spinBox.stepSize
                        spinBox.valueModified()
                    }
                }
            }
        }
        
        // Display value
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Text {
                anchors.centerIn: parent
                text: spinBox.value + spinBox.suffix
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Root.Colors.text
            }
        }
        
        // Tombol plus
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            radius: 6
            color: plusArea.containsPress ? Root.Colors.surface1 : "transparent"
            
            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 16
                color: spinBox.value < spinBox.to ? Root.Colors.text : Root.Colors.overlay0
            }
            
            MouseArea {
                id: plusArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: spinBox.value < spinBox.to
                onClicked: {
                    if (spinBox.value < spinBox.to) {
                        spinBox.value += spinBox.stepSize
                        spinBox.valueModified()
                    }
                }
            }
        }
    }
}
