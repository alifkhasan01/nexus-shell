# Phase 1 Implementation Guide: Quick Wins

## Overview
Phase 1 fokus pada 3 rekomendasi high-impact yang bisa diselesaikan dalam 3-4 hari. Setelah Phase 1 selesai, quickshell akan lebih cepat, lebih user-friendly, dan siap untuk advanced features.

**Estimated Duration**: 3-4 days  
**Expected Improvements**:
- Startup: 1000ms → 600ms (-40%)
- UX: Better configurability, state persistence
- Performance: +10-15% rendering speed

---

## Implementation Order

1. **Performance Pragmas** (30 min) - Quick win
2. **Persistent State Service** (1 day) - Better UX
3. **Basic Settings GUI** (2-3 days) - Biggest UX improvement

---

## 1. Performance Pragmas ⚡ (30 minutes)

### What to Do
Add optimization pragmas ke `shell.qml` dan potentially ke `settings.qml`.

### Step 1: Update shell.qml

**File**: `/home/youtta/.config/quickshell/shell.qml`

**Current (Lines 1-10)**:
```qml
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
```

**Change To**:
```qml
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
```

**What Each Pragma Does**:
- `UseQApplication`: Use native Qt application, better performance
- `QS_NO_RELOAD_POPUP`: Don't show reload notifications
- `QT_QUICK_CONTROLS_STYLE=Basic`: Use native controls
- `QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000`: Better scroll physics

### Step 2: Verify Changes

**Test**:
1. Reload quickshell (or restart)
2. Check tidak ada reload popup
3. Perhatikan input responsiveness lebih smooth

**Expected**: 
- No visual change
- Feel sedikit lebih smooth
- Rendering sedikit lebih cepat

### Step 3: Optional - Add .qmlformat.ini

Untuk consistency dengan illogical impulse, create formatting config:

**File**: `/home/youtta/.config/quickshell/.qmlformat.ini`

```ini
[General]
UseTabs=false
IndentWidth=4
NewlineType=unix
NormalizeOrder=false
FunctionsSpacing=false
ObjectsSpacing=true
MaxColumnWidth=110
```

---

## 2. Persistent State Service 💾 (1 day)

### Goal
Save panel open/close states dan restore saat startup. User preferences remembered across sessions.

### Step 1: Create PersistentState Service

**File**: `/home/youtta/.config/quickshell/services/PersistentState.qml`

```qml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    
    // Path untuk save state
    property string stateDir: `${Directories.cache}/quickshell`
    property string stateFilePath: `${root.stateDir}/state.json`
    
    // Property untuk cache
    property var savedState: ({})
    
    // Create cache directory if not exists
    Component.onCompleted: {
        const dir = new File(root.stateDir)
        if (!dir.exists) {
            dir.mkpath()
            console.log("[PersistentState] Created cache directory:", root.stateDir)
        }
    }
    
    // Load state dari file
    function loadState() {
        try {
            const file = new TextFile(root.stateFilePath)
            const content = file.readAll()
            file.close()
            
            const parsed = JSON.parse(content)
            root.savedState = parsed
            
            console.log("[PersistentState] Loaded saved state:", JSON.stringify(parsed))
            return parsed
        } catch (e) {
            console.log("[PersistentState] No saved state found or invalid JSON:", e.toString())
            return {}
        }
    }
    
    // Save state ke file
    function saveState(state) {
        try {
            // Ensure directory exists
            const dir = new File(root.stateDir)
            if (!dir.exists) {
                dir.mkpath()
            }
            
            const json = JSON.stringify(state, null, 2)
            const file = new TextFile(root.stateFilePath)
            file.writeAll(json)
            file.close()
            
            console.log("[PersistentState] Saved state to:", root.stateFilePath)
        } catch (e) {
            console.log("[PersistentState] Failed to save state:", e.toString())
        }
    }
    
    // Get single value
    function get(key, defaultValue) {
        return root.savedState[key] ?? defaultValue
    }
    
    // Set single value dan save
    function set(key, value) {
        root.savedState[key] = value
        root.saveState(root.savedState)
    }
}
```

### Step 2: Update ShellState to Use Persistence

**File**: `/home/youtta/.config/quickshell/services/ShellState.qml`

**Add This At Top**:
```qml
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    
    // Import persistent state service
    PersistentState {
        id: persistentState
    }
    
    // Existing properties...
    property bool dashboardOpen: false
    property bool powerMenuOpen: false
    property bool wallpaperPanelOpen: false
    property bool calendarOpen: false
    property bool connectionOpen: false
    property bool clipboardOpen: false
    property bool menuOpen: false
    property bool welcomeOpen: false
    
    // ... other existing properties like dnd, lockFn, etc
    
    // Track wallpaper random handler
    property var wallpaperRandom: null
    property var lockFn: null
```

**Add After Component Definition** (before closing brace):
```qml
    // Load saved state on startup
    Component.onCompleted: {
        console.log("[ShellState] Loading persistent state...")
        const saved = persistentState.loadState()
        
        // Restore panel states
        root.dashboardOpen = saved.dashboardOpen ?? false
        root.powerMenuOpen = saved.powerMenuOpen ?? false
        root.wallpaperPanelOpen = saved.wallpaperPanelOpen ?? false
        root.calendarOpen = saved.calendarOpen ?? false
        root.connectionOpen = saved.connectionOpen ?? false
        root.clipboardOpen = saved.clipboardOpen ?? false
        root.menuOpen = saved.menuOpen ?? false
        root.welcomeOpen = saved.welcomeOpen ?? false
        
        console.log("[ShellState] State restored from persistent storage")
    }
    
    // Save state whenever any panel opens/closes
    onDashboardOpenChanged: persistentState.set("dashboardOpen", dashboardOpen)
    onPowerMenuOpenChanged: persistentState.set("powerMenuOpen", powerMenuOpen)
    onWallpaperPanelOpenChanged: persistentState.set("wallpaperPanelOpen", wallpaperPanelOpen)
    onCalendarOpenChanged: persistentState.set("calendarOpen", calendarOpen)
    onConnectionOpenChanged: persistentState.set("connectionOpen", connectionOpen)
    onClipboardOpenChanged: persistentState.set("clipboardOpen", clipboardOpen)
    onMenuOpenChanged: persistentState.set("menuOpen", menuOpen)
    onWelcomeOpenChanged: persistentState.set("welcomeOpen", welcomeOpen)
    
    // Helper function untuk close all panels
    function closeAllPanels() {
        dashboardOpen = false
        powerMenuOpen = false
        wallpaperPanelOpen = false
        calendarOpen = false
        connectionOpen = false
        clipboardOpen = false
        menuOpen = false
    }
```

### Step 3: Test Persistent State

1. Open quickshell
2. Open Dashboard (shellState.dashboardOpen = true)
3. Open Calendar Panel
4. Restart quickshell
5. Dashboard dan Calendar harus terbuka lagi ✓

**Debug**:
- Check file exists: `ls ~/.cache/quickshell/state.json`
- Check content: `cat ~/.cache/quickshell/state.json`
- Check logs: Look untuk "[PersistentState]" messages

---

## 3. Basic Settings GUI 🎛️ (2-3 days)

### Architecture

**File Structure To Create**:
```
shell.qml (root)
├── settings.qml (NEW - settings application)
├── modules/
│   └── settings/
│       ├── QuickConfig.qml
│       ├── GeneralConfig.qml
│       ├── InterfaceConfig.qml
│       ├── ServicesConfig.qml
│       └── About.qml
├── Config.qml (update)
└── services/
    └── PersistentState.qml
```

### Step 1: Create Main Settings App

**File**: `/home/youtta/.config/quickshell/settings.qml`

```qml
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
        { name: "Quick", icon: "instant_mix", component: "modules/settings/QuickConfig.qml" },
        { name: "General", icon: "settings", component: "modules/settings/GeneralConfig.qml" },
        { name: "Interface", icon: "layers", component: "modules/settings/InterfaceConfig.qml" },
        { name: "Services", icon: "extension", component: "modules/settings/ServicesConfig.qml" },
        { name: "About", icon: "info", component: "modules/settings/About.qml" },
    ]
    
    // Initial setup
    Component.onCompleted: {
        console.log("[Settings] Settings app opened")
        // Ensure config is loaded
        if (Config.ready) {
            console.log("[Settings] Config ready, all services loaded")
        }
    }
    
    onClosing: {
        console.log("[Settings] Settings app closed")
        // Config is auto-saved by Config.qml
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
            color: Appearance.colors.surface
            radius: 8
            
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                
                text: root.pages[root.currentPage].name + " Settings"
                color: Appearance.colors.onSurface
                font {
                    pixelSize: 20
                    weight: Font.Medium
                }
            }
            
            // Close button
            Button {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                
                text: "✕"
                onClicked: root.close()
                
                background: Rectangle {
                    color: "transparent"
                    radius: 4
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
                
                color: Appearance.colors.surfaceContainer
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
                                    ? Appearance.colors.primary
                                    : "transparent"
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: root.currentPage === index
                                    ? Appearance.colors.onPrimary
                                    : Appearance.colors.onSurfaceVariant
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
                
                color: Appearance.colors.surfaceContainerLow
                radius: 8
                
                // Use Loader untuk load selected page
                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    
                    source: root.pages[root.currentPage].component
                    
                    // Smooth transition
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
                            value: root.pages[root.currentPage].component
                        }
                        
                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            from: 0; to: 1
                            duration: 150
                        }
                    }
                    
                    onSourceChanged: {
                        pageTransition.start()
                    }
                }
            }
        }
    }
}
```

### Step 2: Create Settings Page Components

**File**: `/home/youtta/.config/quickshell/modules/settings/QuickConfig.qml`

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    // Panel Settings Group
    GroupBox {
        title: "Panel Settings"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: Appearance.colors.surfaceContainer
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            // Panel height
            RowLayout {
                Text {
                    text: "Panel Height:"
                    color: Appearance.colors.onSurface
                }
                
                SpinBox {
                    from: 30
                    to: 100
                    value: Config.options?.bar?.height ?? 50
                    onValueChanged: {
                        if (Config.options) {
                            if (!Config.options.bar) Config.options.bar = {}
                            Config.options.bar.height = value
                        }
                    }
                }
                
                Text {
                    text: "px"
                    color: Appearance.colors.onSurfaceVariant
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // Panel opacity
            RowLayout {
                Text {
                    text: "Panel Opacity:"
                    color: Appearance.colors.onSurface
                }
                
                Slider {
                    from: 0
                    to: 1
                    stepSize: 0.05
                    value: Config.options?.appearance?.backgroundTransparency ?? 0.11
                    onValueChanged: {
                        if (Config.options) {
                            if (!Config.options.appearance) Config.options.appearance = {}
                            Config.options.appearance.backgroundTransparency = value
                        }
                    }
                    Layout.fillWidth: true
                }
                
                Text {
                    text: Math.round(Slider.value * 100) + "%"
                    color: Appearance.colors.onSurfaceVariant
                    width: 40
                }
            }
        }
    }
    
    // Behavior Group
    GroupBox {
        title: "Behavior"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: Appearance.colors.surfaceContainer
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            CheckBox {
                text: "Remember panel states on exit"
                checked: true  // Always enabled now
                enabled: false
                
                indicator: Rectangle {
                    checked: true
                    color: Appearance.colors.primary
                }
            }
            
            CheckBox {
                text: "Show welcome panel on first run"
                checked: Config.options?.welcome?.show ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.welcome) Config.options.welcome = {}
                        Config.options.welcome.show = checked
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
```

**File**: `/home/youtta/.config/quickshell/modules/settings/GeneralConfig.qml`

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    GroupBox {
        title: "General Settings"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: Appearance.colors.surfaceContainer
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            RowLayout {
                Text {
                    text: "Verbose Logging:"
                    color: Appearance.colors.onSurface
                }
                
                CheckBox {
                    checked: Config.options?.bar?.verbose ?? false
                    onCheckedChanged: {
                        if (Config.options) {
                            if (!Config.options.bar) Config.options.bar = {}
                            Config.options.bar.verbose = checked
                        }
                    }
                }
                
                Text {
                    text: "Show detailed logs in console"
                    color: Appearance.colors.onSurfaceVariant
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                Text {
                    text: "Corner Style:"
                    color: Appearance.colors.onSurface
                }
                
                ComboBox {
                    model: ["rounded", "sharp", "beveled"]
                    currentIndex: {
                        const style = Config.options?.bar?.cornerStyle ?? "rounded"
                        return model.indexOf(style)
                    }
                    onCurrentTextChanged: {
                        if (Config.options) {
                            if (!Config.options.bar) Config.options.bar = {}
                            Config.options.bar.cornerStyle = currentText
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
```

**File**: `/home/youtta/.config/quickshell/modules/settings/InterfaceConfig.qml`

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    GroupBox {
        title: "Appearance"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: Appearance.colors.surfaceContainer
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            RowLayout {
                Text {
                    text: "Font Family:"
                    color: Appearance.colors.onSurface
                }
                
                ComboBox {
                    model: ["Noto Sans", "Ubuntu", "JetBrains Mono", "Roboto"]
                    
                    background: Rectangle {
                        color: Appearance.colors.surface
                        radius: 4
                        border.color: Appearance.colors.outline
                        border.width: 1
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
            
            RowLayout {
                Text {
                    text: "Font Size:"
                    color: Appearance.colors.onSurface
                }
                
                SpinBox {
                    from: 8
                    to: 24
                    value: Config.options?.appearance?.fontSize ?? 12
                    onValueChanged: {
                        if (Config.options) {
                            if (!Config.options.appearance) Config.options.appearance = {}
                            Config.options.appearance.fontSize = value
                        }
                    }
                }
                
                Text {
                    text: "px"
                    color: Appearance.colors.onSurfaceVariant
                }
                
                Item { Layout.fillWidth: true }
            }
            
            CheckBox {
                text: "Enable transparency"
                checked: Config.options?.appearance?.enableTransparency ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.appearance) Config.options.appearance = {}
                        Config.options.appearance.enableTransparency = checked
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
```

**File**: `/home/youtta/.config/quickshell/modules/settings/ServicesConfig.qml`

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    
    Text {
        text: "Enable/Disable Services"
        color: Appearance.colors.onSurface
        font.pixelSize: 14
        font.weight: Font.Medium
    }
    
    GroupBox {
        title: "Core Services"
        Layout.fillWidth: true
        
        background: Rectangle {
            color: Appearance.colors.surfaceContainer
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            
            CheckBox {
                text: "Calendar"
                checked: Config.options?.services?.calendar ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.services) Config.options.services = {}
                        Config.options.services.calendar = checked
                    }
                }
            }
            
            CheckBox {
                text: "Weather"
                checked: Config.options?.services?.weather ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.services) Config.options.services = {}
                        Config.options.services.weather = checked
                    }
                }
            }
            
            CheckBox {
                text: "Bluetooth"
                checked: Config.options?.services?.bluetooth ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.services) Config.options.services = {}
                        Config.options.services.bluetooth = checked
                    }
                }
            }
            
            CheckBox {
                text: "Idle Management"
                checked: Config.options?.services?.idle ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.services) Config.options.services = {}
                        Config.options.services.idle = checked
                    }
                }
            }
            
            CheckBox {
                text: "Audio Visualizer"
                checked: Config.options?.services?.cava ?? true
                onCheckedChanged: {
                    if (Config.options) {
                        if (!Config.options.services) Config.options.services = {}
                        Config.options.services.cava = checked
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
```

**File**: `/home/youtta/.config/quickshell/modules/settings/About.qml`

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 20
    
    Image {
        source: "image://icon/quickshell"
        width: 80
        height: 80
        sourceSize: Qt.size(80, 80)
    }
    
    ColumnLayout {
        spacing: 8
        
        Text {
            text: "Quickshell"
            color: Appearance.colors.onSurface
            font.pixelSize: 24
            font.weight: Font.Bold
        }
        
        Text {
            text: "Personal Desktop Shell & Dashboard"
            color: Appearance.colors.onSurfaceVariant
            font.pixelSize: 14
        }
        
        Text {
            text: "Version: 2.1.0"
            color: Appearance.colors.onSurfaceVariant
            font.pixelSize: 12
            font.family: "monospace"
        }
    }
    
    Rectangle {
        height: 1
        Layout.fillWidth: true
        color: Appearance.colors.outline
    }
    
    ColumnLayout {
        spacing: 4
        
        Text {
            text: "Project Links"
            color: Appearance.colors.onSurface
            font.weight: Font.Medium
        }
        
        Button {
            text: "📚 Documentation"
            onClicked: Qt.openUrlExternally("https://quickshell.dev")
            
            background: Rectangle {
                color: "transparent"
            }
            
            contentItem: Text {
                text: parent.text
                color: Appearance.colors.primary
            }
        }
        
        Button {
            text: "🐛 Report Issues"
            onClicked: Qt.openUrlExternally("https://github.com/jovanlanik/quickshell")
            
            background: Rectangle {
                color: "transparent"
            }
            
            contentItem: Text {
                text: parent.text
                color: Appearance.colors.primary
            }
        }
    }
    
    ColumnLayout {
        spacing: 8
        
        Text {
            text: "Configuration File:"
            color: Appearance.colors.onSurfaceVariant
            font.pixelSize: 12
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Appearance.colors.surface
            radius: 4
            border.color: Appearance.colors.outline
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                
                Text {
                    text: "~/.config/quickshell/config.json"
                    color: Appearance.colors.onSurface
                    font.family: "monospace"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Copy"
                    onClicked: {
                        Quickshell.clipboardText = "~/.config/quickshell/config.json"
                    }
                    
                    background: Rectangle {
                        color: Appearance.colors.primary
                        radius: 3
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: Appearance.colors.onPrimary
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
```

### Step 3: Update Config.qml to Support New Options

**File**: `/home/youtta/.config/quickshell/services/Config.qml`

Add new config defaults:

```qml
// Existing code...

property object options: ({
    // Bar settings
    bar: {
        height: 50,
        cornerStyle: "rounded",
        verbose: false,
    },
    
    // Appearance settings
    appearance: {
        fontSize: 12,
        fontFamily: "Noto Sans",
        enableTransparency: true,
        backgroundTransparency: 0.11,
    },
    
    // Services toggle
    services: {
        calendar: true,
        weather: true,
        bluetooth: true,
        idle: true,
        cava: true,
    },
    
    // Welcome panel
    welcome: {
        show: true,
    },
    
    // Panel family (for future Phase 2)
    panelFamily: "ii",
})
```

### Step 4: Test Settings Application

1. Run settings.qml:
```bash
qml settings.qml
```

2. Test navigation:
   - Click different tabs ✓
   - Ctrl+Tab untuk next page ✓
   - Ctrl+Shift+Tab untuk prev page ✓

3. Test configuration:
   - Change panel height → saved ke config.json
   - Change opacity → persisted
   - Toggle services → remembered

4. Check config file:
```bash
cat ~/.config/quickshell/config.json
```

---

## Testing & Verification

### Performance Test
```bash
# Measure startup time
time quickshell

# Expected: < 700ms dengan lazy loading
# Before Phase 1: ~1000ms
# After Phase 1: ~900ms
# After Phase 2: ~600ms
```

### Persistent State Test
```bash
# Check saved state
cat ~/.cache/quickshell/state.json

# Should contain:
# {
#   "dashboardOpen": true,
#   "calendarOpen": true,
#   ...
# }
```

### Settings GUI Test
- Open settings.qml
- Change each setting
- Close settings
- Reopen settings → changes should persist
- Verify config.json updated

---

## Phase 1 Completion Checklist

- [ ] Performance pragmas added ke shell.qml
- [ ] PersistentState.qml service created
- [ ] ShellState.qml updated untuk use persistence
- [ ] State file created at ~/.cache/quickshell/state.json
- [ ] Settings.qml app created dengan 5 pages
- [ ] Config.qml updated dengan new options
- [ ] All settings pages tested dan working
- [ ] Keyboard navigation tested
- [ ] Changes persisted ke config.json
- [ ] State persisted across restart
- [ ] Documentation updated

---

## Troubleshooting

### Issue: Settings app won't open
**Solution**: 
- Check if qml/Qt installed: `which qml`
- Try: `cd ~/.config/quickshell && qml settings.qml`

### Issue: Config changes not persisting
**Solution**:
- Check Config.qml connected properly
- Verify config.json file writable: `touch ~/.config/quickshell/config.json`
- Check logs for errors

### Issue: Persistent state not loading
**Solution**:
- Verify directory exists: `mkdir -p ~/.cache/quickshell`
- Check file permissions: `ls -la ~/.cache/quickshell/state.json`
- Look for "[PersistentState]" logs

---

## Next Steps After Phase 1

Once Phase 1 complete, move to Phase 2:
- Implement Lazy Panel Loading (40% faster startup)
- Material Theme Loader Service (auto theme sync)
- Modular Widget System foundation

See `IMPROVEMENTS_ROADMAP.md` Phase 2 section for details.

---

**Last Updated**: August 17, 2026  
**Status**: Ready for implementation
