import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../" as Root

PanelWindow {
    id: idlePanel
    
    property bool open: false
    signal closeRequested()
    
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel
    
    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
        }
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-idle"
    WlrLayershell.exclusiveZone: 0
    
    // Klik luar untuk tutup
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: idlePanel.closeRequested()
    }
    
    Rectangle {
        id: card
        
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 200
        
        width: 320
        height: contentColumn.implicitHeight + 32
        
        radius: 16
        color: Root.Colors.base
        border.width: 1
        border.color: Root.Colors.surface0
        
        opacity: 0
        transform: Translate { id: cardTranslate; y: -30 }
        
        states: State {
            name: "open"
            when: idlePanel.open
            PropertyChanges { target: card; opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }
        
        transitions: [
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
                    OpacityAnimator { target: card; duration: Root.Appearance.animation.elementMoveEnter.duration }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardTranslate; property: "y"; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
                        OpacityAnimator { target: card; duration: Root.Appearance.animation.elementMoveExit.duration }
                    }
                    ScriptAction { script: idlePanel.showPanel = false }
                }
            }
        ]
        
        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
        
        // Prevent click-through
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Consume event
        }
        
        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // ── Header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Text {
                    text: "󰒲"
                    font.pixelSize: 20
                    color: Root.Colors.blue
                }
                
                Text {
                    text: "Idle Timeouts"
                    font.pixelSize: 16
                    font.bold: true
                    color: Root.Colors.text
                    Layout.fillWidth: true
                }
                
                // Close button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeArea.containsPress ? Root.Colors.red : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.pixelSize: 14
                        color: closeArea.containsPress ? Root.Colors.base : Root.Colors.subtext
                    }
                    
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: idlePanel.closeRequested()
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface0
            }
            
            // ── Info Text ──────────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text: "Configure automatic idle actions"
                font.pixelSize: 11
                color: Root.Colors.subtext
                wrapMode: Text.WordWrap
            }
            
            Item { height: 4 }
            
            // ── Screen Off ─────────────────────────────────────────────────
            TimeoutRow {
                Layout.fillWidth: true
                icon: "󰹑"
                label: "Screen Off"
                description: "Turn off display"
                value: Services.IdleManager.screenOffTimeout / 60
                minValue: 1
                maxValue: 60
                onTimeoutChanged: v => Services.IdleManager.setScreenOffTimeout(v)
            }
            
            // ── Lock Screen ────────────────────────────────────────────────
            TimeoutRow {
                Layout.fillWidth: true
                icon: "󰌾"
                label: "Lock Screen"
                description: "Require password"
                value: Services.IdleManager.lockTimeout / 60
                minValue: 1
                maxValue: 120
                onTimeoutChanged: v => Services.IdleManager.setLockTimeout(v)
            }
            
            // ── Suspend ────────────────────────────────────────────────────
            TimeoutRow {
                Layout.fillWidth: true
                icon: "󰤄"
                label: "Suspend"
                description: "Sleep system"
                value: Services.IdleManager.suspendTimeout / 60
                minValue: 5
                maxValue: 240
                onTimeoutChanged: v => Services.IdleManager.setSuspendTimeout(v)
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface0
            }
            
            // ── Master Toggle ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: "Idle Monitoring"
                        font.pixelSize: 12
                        font.bold: true
                        color: Root.Colors.text
                    }
                    
                    Text {
                        text: Services.IdleManager.monitoringEnabled 
                              ? "Enabled - Auto actions active"
                              : "Disabled - No auto actions"
                        font.pixelSize: 10
                        color: Root.Colors.subtext
                    }
                }
                
                Rectangle {
                    width: 48
                    height: 26
                    radius: 13
                    color: Services.IdleManager.monitoringEnabled 
                           ? Root.Colors.blue 
                           : Root.Colors.surface1
                    
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                    
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        x: Services.IdleManager.monitoringEnabled ? 24 : 2
                        y: 2
                        color: Root.Colors.base
                        
                        Behavior on x { NumberAnimation { duration: Root.Appearance.animation.elementMoveSmall.duration; easing.type: Root.Appearance.animation.elementMoveSmall.type; easing.bezierCurve: Root.Appearance.animation.elementMoveSmall.bezierCurve } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.IdleManager.toggle()
                    }
                }
            }
            
            Item { height: 2 }
        }
    }
    
    // ── TimeoutRow Component ───────────────────────────────────────────────
    component TimeoutRow: ColumnLayout {
        id: timeoutRow
        
        property string icon: ""
        property string label: ""
        property string description: ""
        property int value: 5
        property int minValue: 1
        property int maxValue: 60
        
        signal timeoutChanged(int newValue)
        
        spacing: 6
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: Root.Colors.surface0
                
                Text {
                    anchors.centerIn: parent
                    text: timeoutRow.icon
                    font.pixelSize: 18
                    color: Root.Colors.blue
                }
            }
            
            Column {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    text: timeoutRow.label
                    font.pixelSize: 12
                    font.bold: true
                    color: Root.Colors.text
                }
                
                Text {
                    text: timeoutRow.description
                    font.pixelSize: 10
                    color: Root.Colors.subtext
                }
            }
        }
        
        // Spinbox
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 8
            color: Root.Colors.surface0
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                
                // Minus button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true
                    radius: 6
                    color: minusArea.containsPress ? Root.Colors.surface1 : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        font.pixelSize: 18
                        color: timeoutRow.value > timeoutRow.minValue 
                               ? Root.Colors.text 
                               : Root.Colors.overlay0
                    }
                    
                    MouseArea {
                        id: minusArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: timeoutRow.value > timeoutRow.minValue
                        onClicked: {
                            if (timeoutRow.value > timeoutRow.minValue) {
                                timeoutRow.timeoutChanged(timeoutRow.value - 1)
                            }
                        }
                    }
                }
                
                // Value display
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 0
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: timeoutRow.value
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.text
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: timeoutRow.value === 1 ? "minute" : "minutes"
                            font.pixelSize: 9
                            color: Root.Colors.subtext
                        }
                    }
                }
                
                // Plus button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true
                    radius: 6
                    color: plusArea.containsPress ? Root.Colors.surface1 : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 18
                        color: timeoutRow.value < timeoutRow.maxValue 
                               ? Root.Colors.text 
                               : Root.Colors.overlay0
                    }
                    
                    MouseArea {
                        id: plusArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: timeoutRow.value < timeoutRow.maxValue
                        onClicked: {
                            if (timeoutRow.value < timeoutRow.maxValue) {
                                timeoutRow.timeoutChanged(timeoutRow.value + 1)
                            }
                        }
                    }
                }
            }
        }
    }
}
