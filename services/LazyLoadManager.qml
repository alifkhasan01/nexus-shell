pragma Singleton

import QtQuick

// Lazy Loading Manager Service
// Manages lazy component loading with performance tracking and optimization
// Provides utilities for efficient component lifecycle management

QtObject {
    id: root
    
    // Performance tracking
    property var lazyLoadStats: ({})
    property int totalComponentsLoaded: 0
    property int peakMemoryUsage: 0
    
    // Lazy loader registry
    property var lazyLoaders: ({})
    
    // Register a lazy loader for monitoring
    function registerLazyLoader(name, loaderComponent) {
        lazyLoaders[name] = {
            name: name,
            loader: loaderComponent,
            loadTime: 0,
            isLoaded: false,
            activationCount: 0
        }
        
        console.log(`[LazyLoadManager] Registered lazy loader: ${name}`)
    }
    
    // Track component load event
    function trackLoadStart(name) {
        if (lazyLoadStats[name]) {
            lazyLoadStats[name].loadCount++
            lazyLoadStats[name].lastLoadTime = new Date().getTime()
        } else {
            lazyLoadStats[name] = {
                loadCount: 1,
                unloadCount: 0,
                lastLoadTime: new Date().getTime(),
                totalLoadTime: 0,
                peakActive: 1
            }
        }
    }
    
    // Track component unload event
    function trackUnload(name) {
        if (lazyLoadStats[name]) {
            lazyLoadStats[name].unloadCount++
            const loadTime = new Date().getTime() - lazyLoadStats[name].lastLoadTime
            lazyLoadStats[name].totalLoadTime += loadTime
        }
    }
    
    // Get statistics for a component
    function getStats(name) {
        return lazyLoadStats[name] ?? null
    }
    
    // Get all statistics
    function getAllStats() {
        return lazyLoadStats
    }
    
    // Log statistics
    function logStats() {
        console.log("[LazyLoadManager] ═══════════════════════════════════════")
        console.log("[LazyLoadManager] Lazy Loading Statistics")
        console.log("[LazyLoadManager] ═══════════════════════════════════════")
        
        let totalLoads = 0
        let totalUnloads = 0
        
        for (const [name, stats] of Object.entries(lazyLoadStats)) {
            console.log(`[LazyLoadManager] ${name}:`)
            console.log(`[LazyLoadManager]   • Loaded: ${stats.loadCount} times`)
            console.log(`[LazyLoadManager]   • Unloaded: ${stats.unloadCount} times`)
            console.log(`[LazyLoadManager]   • Avg load time: ${(stats.totalLoadTime / stats.loadCount).toFixed(2)}ms`)
            
            totalLoads += stats.loadCount
            totalUnloads += stats.unloadCount
        }
        
        console.log("[LazyLoadManager] ───────────────────────────────────────")
        console.log(`[LazyLoadManager] Total loads: ${totalLoads}`)
        console.log(`[LazyLoadManager] Total unloads: ${totalUnloads}`)
        console.log("[LazyLoadManager] ═══════════════════════════════════════")
    }
    
    // Preload a component (useful for frequently-used panels)
    function preloadComponent(name, loaderComponent) {
        if (loaderComponent && !loaderComponent.active) {
            console.log(`[LazyLoadManager] Preloading component: ${name}`)
            loaderComponent.active = true
            trackLoadStart(name)
        }
    }
    
    // Unload a component manually
    function unloadComponent(name, loaderComponent) {
        if (loaderComponent && loaderComponent.active) {
            console.log(`[LazyLoadManager] Unloading component: ${name}`)
            loaderComponent.active = false
            trackUnload(name)
        }
    }
    
    // Get debug info
    function getDebugInfo() {
        return {
            totalComponentsLoaded: totalComponentsLoaded,
            peakMemoryUsage: peakMemoryUsage,
            registeredLoaders: Object.keys(lazyLoaders).length,
            stats: lazyLoadStats
        }
    }
}
