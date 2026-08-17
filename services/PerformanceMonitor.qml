pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Performance Monitor Service
// Tracks startup time, memory usage, frame rates, and component lifecycle metrics

QtObject {
    id: root
    
    // Startup tracking
    property int startupTime: 0
    property real startupMemory: 0
    property real peakMemory: 0
    property date startTime: new Date()
    
    // Frame tracking
    property int frameCount: 0
    property real averageFps: 60
    property real minimumFps: 60
    property real maximumFps: 60
    
    // Component metrics
    property var componentMetrics: ({})
    
    // Memory monitoring
    property Process memoryMonitor: Timer {
        id: memTimer
        interval: 2000  // Check every 2 seconds
        repeat: true
        running: true
        
        onTriggered: {
            root.updateMemoryStats()
        }
    }
    
    // FPS tracking
    property var fpsTracker: Timer {
        id: fpsTimer
        interval: 1000  // Sample every second
        repeat: true
        running: true
        
        onTriggered: {
            // Calculate and update FPS stats
            // This would need integration with rendering loop
        }
    }
    
    // Initialize performance monitoring
    function initialize() {
        root.startTime = new Date()
        console.log("[PerformanceMonitor] Performance monitoring started")
    }
    
    // Record startup completion
    function recordStartup() {
        const elapsed = new Date().getTime() - root.startTime.getTime()
        root.startupTime = elapsed
        
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
        console.log("[PerformanceMonitor] STARTUP COMPLETE")
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
        console.log(`[PerformanceMonitor] Total startup time: ${root.startupTime}ms`)
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
    }
    
    // Update memory statistics
    function updateMemoryStats() {
        // This would require proc parsing or Qt memory API
        // For now, log placeholder
        console.log("[PerformanceMonitor] Memory check...")
    }
    
    // Track component load/unload
    function trackComponentLoad(componentName, loadTime) {
        if (!componentMetrics[componentName]) {
            componentMetrics[componentName] = {
                name: componentName,
                loadCount: 0,
                unloadCount: 0,
                totalLoadTime: 0,
                averageLoadTime: 0,
                lastLoadTime: 0,
                peakLoadTime: 0
            }
        }
        
        const metric = componentMetrics[componentName]
        metric.loadCount++
        metric.totalLoadTime += loadTime
        metric.averageLoadTime = metric.totalLoadTime / metric.loadCount
        metric.lastLoadTime = loadTime
        
        if (loadTime > metric.peakLoadTime) {
            metric.peakLoadTime = loadTime
        }
    }
    
    // Get performance summary
    function getPerformanceSummary() {
        const summary = {
            startupTime: root.startupTime,
            startupMemory: root.startupMemory,
            peakMemory: root.peakMemory,
            averageFps: root.averageFps,
            minimumFps: root.minimumFps,
            maximumFps: root.maximumFps,
            componentMetrics: root.componentMetrics,
            timestamp: new Date().toISOString()
        }
        
        return summary
    }
    
    // Log performance report
    function logPerformanceReport() {
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
        console.log("[PerformanceMonitor] PERFORMANCE REPORT")
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
        
        console.log("[PerformanceMonitor] STARTUP METRICS:")
        console.log(`[PerformanceMonitor]   • Startup time: ${root.startupTime}ms`)
        console.log(`[PerformanceMonitor]   • Start memory: ${root.startupMemory.toFixed(2)}MB`)
        console.log(`[PerformanceMonitor]   • Peak memory: ${root.peakMemory.toFixed(2)}MB`)
        
        console.log("[PerformanceMonitor] RENDERING METRICS:")
        console.log(`[PerformanceMonitor]   • Average FPS: ${root.averageFps.toFixed(1)}`)
        console.log(`[PerformanceMonitor]   • Min FPS: ${root.minimumFps.toFixed(1)}`)
        console.log(`[PerformanceMonitor]   • Max FPS: ${root.maximumFps.toFixed(1)}`)
        
        console.log("[PerformanceMonitor] COMPONENT METRICS:")
        for (const [name, metric] of Object.entries(root.componentMetrics)) {
            console.log(`[PerformanceMonitor]   ${name}:`)
            console.log(`[PerformanceMonitor]     • Loaded: ${metric.loadCount}x`)
            console.log(`[PerformanceMonitor]     • Avg load: ${metric.averageLoadTime.toFixed(2)}ms`)
            console.log(`[PerformanceMonitor]     • Peak load: ${metric.peakLoadTime.toFixed(2)}ms`)
        }
        
        console.log("[PerformanceMonitor] ═══════════════════════════════════════")
    }
    
    // Get debug info
    function getDebugInfo() {
        return {
            startupTime: root.startupTime,
            uptime: new Date().getTime() - root.startTime.getTime(),
            componentCount: Object.keys(root.componentMetrics).length,
            metrics: root.getPerformanceSummary()
        }
    }
    
    // Auto-initialize on load
    Component.onCompleted: {
        // Defer initialization to avoid circular imports
        Qt.callLater(function() {
            root.initialize()
        })
    }
}
