pragma Singleton

import QtQuick
import Quickshell

// Advanced Network Service
// Provides detailed network information and management

QtObject {
    id: root
    
    // Network states
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool vpnConnected: false
    property string currentNetwork: "Disconnected"
    property real signalStrength: 0
    
    // Network info
    property var networkList: []
    property var vpnList: []
    
    // Methods
    function getNetworkInfo() {
        return {
            wifiEnabled: root.wifiEnabled,
            bluetoothEnabled: root.bluetoothEnabled,
            vpnConnected: root.vpnConnected,
            currentNetwork: root.currentNetwork,
            signalStrength: root.signalStrength
        }
    }
    
    function toggleWifi() {
        root.wifiEnabled = !root.wifiEnabled
        console.log(`[NetworkAdvanced] WiFi ${root.wifiEnabled ? "enabled" : "disabled"}`)
    }
    
    function toggleBluetooth() {
        root.bluetoothEnabled = !root.bluetoothEnabled
        console.log(`[NetworkAdvanced] Bluetooth ${root.bluetoothEnabled ? "enabled" : "disabled"}`)
    }
    
    function connectToVPN(vpnName) {
        root.vpnConnected = true
        console.log(`[NetworkAdvanced] Connected to VPN: ${vpnName}`)
    }
    
    function getDebugInfo() {
        return {
            wifi: root.wifiEnabled,
            bluetooth: root.bluetoothEnabled,
            vpn: root.vpnConnected,
            network: root.currentNetwork
        }
    }
    
    Component.onCompleted: {
        console.log("[NetworkAdvanced] Network service initialized")
    }
}
