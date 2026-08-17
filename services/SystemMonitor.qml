pragma Singleton

import QtQuick
import Quickshell

// System Monitor Service
// Tracks CPU, memory, disk, temperature

QtObject {
    id: root
    
    // CPU metrics
    property real cpuUsage: 0
    property list<real> cpuCores: []
    
    // Memory metrics
    property real memoryUsage: 0
    property real memoryTotal: 0
    property real memoryPercent: 0
    
    // Disk metrics
    property real diskUsage: 0
    property real diskTotal: 0
    property real diskPercent: 0
    
    // Temperature
    property real cpuTemp: 0
    property real gpuTemp: 0
    
    // Update timer
    property Timer updateTimer: Timer {
        id: monitorTimer
        interval: 2000
        repeat: true
        running: true
        
        onTriggered: {
            root.updateMetrics()
        }
    }
    
    function updateMetrics() {
        // Update CPU, memory, disk stats
        console.log(`[SystemMonitor] CPU: ${root.cpuUsage.toFixed(1)}% | RAM: ${root.memoryPercent.toFixed(1)}% | Disk: ${root.diskPercent.toFixed(1)}%`)
    }
    
    function getSystemStats() {
        return {
            cpu: root.cpuUsage,
            memory: root.memoryPercent,
            disk: root.diskPercent,
            temps: {
                cpu: root.cpuTemp,
                gpu: root.gpuTemp
            }
        }
    }
    
    function getDebugInfo() {
        return root.getSystemStats()
    }
    
    Component.onCompleted: {
        console.log("[SystemMonitor] System monitor service initialized")
    }
}
