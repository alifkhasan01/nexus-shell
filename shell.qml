//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland._GlobalShortcuts
import QtQml
import QtQuick
import "./bar" as Bar
import "./bar/widgets" as Widgets
import "./lockscreen" as Lock
import "./notifications" as Notif
import "./services"
import "./shell" as ShellComponents
import "./welcome" as Welcome

ShellRoot {
    id: root

    // ── Startup Logging ────────────────────────────────────────────────────
    Component.onCompleted: {
        console.log("[Quickshell] Started successfully")
        console.log("[Quickshell] Screen count:", Quickshell.screens.length)
    }

    // Handler wallpaper acak yang selalu hidup; dipakai oleh GlobalShortcut dan
    // klik kanan tombol wallpaper di Bar, tanpa bergantung pada panel.
    Widgets.WallpaperRandom {
        id: wpRandom
    }

    // ── Shell State Service ────────────────────────────────────────────────
    // Sumber kebenaran untuk panel-panel yang bisa di-toggle dari shortcut
    // Hyprland maupun dari klik di Bar. Accessible dari mana saja di aplikasi.
    ShellState {
        id: shellStateObj
        wallpaperRandom: wpRandom
        lockFn: function() { lockScreenRef.lock() }
    }

    // ── Global Shortcuts ──────────────────────────────────────────────────
    // All shortcuts inline for simplicity - ProcessManager handles background processes
    
    GlobalShortcut {
        appid: "quickshell"
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: shellStateObj.dashboardOpen = !shellStateObj.dashboardOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "powermenu"
        description: "Toggle power menu"
        onPressed: shellStateObj.powerMenuOpen = !shellStateObj.powerMenuOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "menu"
        description: "Toggle menu panel"
        onPressed: shellStateObj.menuOpen = !shellStateObj.menuOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        description: "Lock screen"
        onPressed: lockScreenRef.lock()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-toggle"
        description: "Toggle wallpaper panel"
        onPressed: shellStateObj.wallpaperPanelOpen = !shellStateObj.wallpaperPanelOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper-random"
        description: "Ganti wallpaper acak"
        onPressed: wpRandom.pickRandom()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "calendar"
        description: "Toggle calendar panel"
        onPressed: shellStateObj.calendarOpen = !shellStateObj.calendarOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "connection"
        description: "Toggle connection panel"
        onPressed: shellStateObj.connectionOpen = !shellStateObj.connectionOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        description: "Toggle clipboard panel"
        onPressed: shellStateObj.clipboardOpen = !shellStateObj.clipboardOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volume:up"
        description: "Volume up"
        onPressed: if (volumeControlObj) volumeControlObj.volumeUp()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volume:down"
        description: "Volume down"
        onPressed: if (volumeControlObj) volumeControlObj.volumeDown()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volume:mute"
        description: "Toggle mute"
        onPressed: if (volumeControlObj) volumeControlObj.toggleMute()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "brightness:up"
        description: "Brightness up"
        onPressed: if (brightnessControlObj) brightnessControlObj.brightnessUp()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "brightness:down"
        description: "Brightness down"
        onPressed: if (brightnessControlObj) brightnessControlObj.brightnessDown()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "screenshot-full"
        description: "Screenshot fullscreen"
        onPressed: procManager.takeScreenshotFull()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "screenshot-select"
        description: "Screenshot area"
        onPressed: procManager.takeScreenshotSelect()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "welcome"
        description: "Toggle welcome panel"
        onPressed: shellStateObj.welcomeOpen = !shellStateObj.welcomeOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "restart"
        description: "Restart quickshell"
        onPressed: Quickshell.reload(true)
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "media"
        description: "Toggle media player & equalizer panel"
        onPressed: shellStateObj.mediaOpen = !shellStateObj.mediaOpen
    }

    // ── IPC / CLI Integration Shortcuts ───────────────────────────────────
    // These shortcuts communicate via Nexus IPC protocol to registered actions
    // without affecting the core 17 global shortcuts above

    GlobalShortcut {
        appid: "quickshell"
        name: "nexus:launcher"
        description: "Toggle launcher (Nexus IPC)"
        onPressed: {
            console.log("[Shell] nexus:launcher triggered")
            const request = {
                version: 1,
                module: "launcher",
                action: "toggle"
            }
            console.log("[Shell] IPC request:", JSON.stringify(request))
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "nexus:dashboard"
        description: "Toggle dashboard (Nexus IPC)"
        onPressed: {
            console.log("[Shell] nexus:dashboard triggered")
            const request = {
                version: 1,
                module: "dashboard",
                action: "toggle"
            }
            console.log("[Shell] IPC request:", JSON.stringify(request))
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "nexus:wallpaper-next"
        description: "Next wallpaper (Nexus IPC)"
        onPressed: {
            console.log("[Shell] nexus:wallpaper-next triggered")
            const request = {
                version: 1,
                module: "wallpaper",
                action: "next"
            }
            console.log("[Shell] IPC request:", JSON.stringify(request))
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "nexus:wallpaper-random"
        description: "Random wallpaper (Nexus IPC)"
        onPressed: {
            console.log("[Shell] nexus:wallpaper-random triggered")
            const request = {
                version: 1,
                module: "wallpaper",
                action: "random"
            }
            console.log("[Shell] IPC request:", JSON.stringify(request))
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "nexus:media-play"
        description: "Play/pause media (Nexus IPC)"
        onPressed: {
            console.log("[Shell] nexus:media-play triggered")
            const request = {
                version: 1,
                module: "media",
                action: "play_pause"
            }
            console.log("[Shell] IPC request:", JSON.stringify(request))
        }
    }

    // ── Process Manager (Screenshot, BlueZ Agent, Cava Feed) ────────────────
    ShellComponents.ProcessManager {
        id: procManager
        shellState: shellStateObj
        osdRef: osdRef
    }

    // ── Volume Control Service ────────────────────────────────────────────
    VolumeControl {
        id: volumeControlObj
        osdRef: osdRef
    }

    // ── Brightness Control Service ────────────────────────────────────────
    BrightnessControl {
        id: brightnessControlObj
        osdRef: osdRef
    }

    // Satu Bar per monitor
    Variants {
        model: Quickshell.screens

        Bar.Bar {
            id: barInstance
            required property var modelData
            screen: modelData
            shellState: shellStateObj
            procManager: procManager

            // Inject window reference ke IdleInhibitService saat bar pertama dibuat
            Component.onCompleted: {
                if (!IdleInhibitService.targetWindow) {
                    IdleInhibitService.targetWindow = barInstance
                }
            }
        }
    }

    // ── OSD untuk Volume & Brightness ─────────────────────────────────────
    Notif.Osd {
        id: osdRef
    }

    // ── Lock Screen ───────────────────────────────────────────────────────
    // WlSessionLock harus ada satu instance di root (bukan di dalam Bar),
    // karena ia menutup SEMUA monitor sekaligus via ext_session_lock_v1.
    // GlobalShortcut (quickshell:lock) memanggil lockScreenRef.lock().
    Lock.LockScreen {
        id: lockScreenRef
    }

    // ── Notification Popup — root level agar selalu di atas semua ────────
    // Diletakkan di sini (bukan di dalam Bar) supaya render di atas
    // dashboard, panel, dan komponen overlay lainnya.
    Notif.NotificationPopup {
        dnd: shellStateObj.dnd
    }

    // ── Welcome Panel — muncul saat startup kalau ada dependensi kurang ──
    // Auto-open via Connection di bawah; bisa juga di-toggle manual via
    // GlobalShortcut `quickshell:welcome`.
    Welcome.WelcomePanel {
        id: welcomeRef
        open: shellStateObj.welcomeOpen
        procManager: procManager
        onCloseRequested: shellStateObj.welcomeOpen = false
        onInstallFinished: function(allInstalled) {
            if (allInstalled) {
                console.log("[Welcome] Semua dependensi terinstall — menutup panel")
                shellStateObj.welcomeOpen = false
            }
        }
    }

    function maybeOpenWelcome() {
        if (welcomeRef.settingsLoaded && welcomeRef.missingCount > 0
                && welcomeRef.showOnStartup) {
            console.log("[Welcome] Dependensi kurang — membuka welcome panel")
            shellStateObj.welcomeOpen = true
        }
    }

    Connections {
        target: procManager
        function onDepsCheckedChanged() { root.maybeOpenWelcome() }
    }
    Connections {
        target: welcomeRef
        function onSettingsLoadedChanged() { root.maybeOpenWelcome() }
    }
    Connections {
        target: welcomeRef
        function onDepsUpdated() { root.maybeOpenWelcome() }
    }

    // ── Auto-pairing BlueZ agent (berjalan di background) ─────────────────
    // Menjawab "yes" pada prompt pair/confirm bluetooth sehingga perangkat
    // bisa connect langsung dari panel tanpa input terminal.
    // Dijalankan sekali saat startup; jika crash, tidak direstart otomatis
    // (bluetoothd biasanya sudah handle re-registration sendiri).
    // NOTE: Dikelola oleh ProcessManager di shell/ProcessManager.qml

    // ── Audio visualizer feed ──────────────────────────────────────────
    // Hanya berjalan saat dashboard terbuka (tab Media butuh data spektrum).
    // Feed dikelola CavaRingDank langsung (scripts/qs_visualizer — C++ native,
    // PipeWire+FFT): aktif otomatis saat CavaRingDank visible, mati saat tidak.

    // ── Bluetooth Device Auto-promotion ───────────────────────────────────
    // Saat perangkat bluetooth (headphone/dst) terhubung, sink audionya
    // dijadikan default agar slider volume di Bar & Dashboard ikut
    // mengontrol volume perangkat bluetooth tersebut.
    BluetoothDevicePromotion {
    }
}
