//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

ApplicationWindow {
    id: root
    
    title: "Quickshell Settings"
    width: 1000
    height: 700
    visible: true
    
    // Track current page
    property int currentPage: 0
    
    // Define pages
    property list<object> pages: [
        { name: "Quick", icon: "⚡", component: "modules/settings/QuickConfig.qml" },
        { name: "General", icon: "⚙️", component: "modules/settings/GeneralConfig.qml" },
        { name: "Interface", icon: "🎨", component: "modules/settings/InterfaceConfig.qml" },
        { name: "Services", icon: "📦", component: "modules/settings/ServicesConfig.qml" },
        { name: "About", icon: "ℹ️", component: "modules/settings/About.qml" },
    ]
    
    // Initial setup
    Component.onCompleted: {
        console.log("[Settings] Settings app opened")
    }
    
    onClosing: {
        console.log("[Settings] Settings app closed")
    }
    
    // Keyboard navigation
    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            // Ctrl+Tab: next page
            if (event.key === Qt.Key_Tab) {
                currentPage = (currentPage + 1) % pages.length
                event.accepted = true
                console.log("[Settings] Navigated to page:", pages[currentPage].name)
            }
            // Ctrl+Shift+Tab: previous page
            else if (event.key === Qt.Key_Backtab) {
                currentPage = (currentPage - 1 + pages.length) % pages.length
                event.accepted = true
                console.log("[Settings] Navigated to page:", pages[currentPage].name)
            }
        }
    }
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        // Title bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#f0f0f0"
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                Text {
                    text: root.pages[root.currentPage].name + " Settings"
                    color: "#1a1a1a"
                    font {
                        pixelSize: 20
                        weight: Font.Medium
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Close button
                Button {
                    text: "✕"
                    onClicked: root.close()
                    
                    background: Rectangle {
                        color: "#e0e0e0"
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#1a1a1a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Content area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            // Sidebar navigation
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 160
                
                color: "#f5f5f5"
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    
                    // Navigation buttons
                    Repeater {
                        model: root.pages
                        
                        Button {
                            Layout.fillWidth: true
                            
                            text: modelData.name
                            
                            background: Rectangle {
                                color: root.currentPage === index 
                                    ? "#6750A4"
                                    : "transparent"
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: root.currentPage === index
                                    ? "#FFFFFF"
                                    : "#1a1a1a"
                                leftPadding: 12
                                horizontalAlignment: Text.AlignLeft
                                font.pixelSize: 13
                            }
                            
                            onClicked: {
                                root.currentPage = index
                            }
                        }
                    }
                    
                    // Spacer
                    Item { Layout.fillHeight: true }
                }
            }
            
            // Content area dengan Loader
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                color: "#FFFFFF"
                radius: 8
                border.color: "#E0E0E0"
                border.width: 1
                
                // Use Loader untuk load selected page
                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    
                    source: root.pages[root.currentPage].component
                    
                    onSourceChanged: {
                        pageTransition.start()
                    }
                }
                
                // Smooth transition animation
                SequentialAnimation {
                    id: pageTransition
                    
                    NumberAnimation {
                        target: pageLoader
                        property: "opacity"
                        from: 1; to: 0
                        duration: 100
                    }
                    
                    PropertyAction {
                        target: pageLoader
                        property: "source"
                    }
                    
                    NumberAnimation {
                        target: pageLoader
                        property: "opacity"
                        from: 0; to: 1
                        duration: 150
                    }
                }
            }
        }
    }
}
