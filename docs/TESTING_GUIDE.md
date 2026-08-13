# Testing & Validation Checklist

Comprehensive guide untuk testing Quickshell config setelah refactor v2.1.

---

## Pre-Testing Setup

### Environment Check

```bash
# 1. Verify Quickshell installed
which quickshell
quickshell --version

# 2. Check required dependencies
which grimblast cava swww nmcli bluetoothctl
which brightnessctl pactl

# 3. Verify config location
ls -la ~/.config/quickshell/
cd ~/.config/quickshell

# 4. Check Hyprland integration
echo $HYPRLAND_INSTANCE_SIGNATURE
```

### Pre-flight Checks

- [ ] Hyprland compositor running
- [ ] No other Quickshell instance running (`pkill -f quickshell`)
- [ ] Clean `/tmp` directory (`rm -f /tmp/qs-*.out`)
- [ ] Audio working (`alsamixer` or `pavucontrol`)
- [ ] Display manager not running (`systemctl stop gdm` or equivalent)

---

## Unit Tests: Services

### ShellState Service

**Test**: Global state management

```bash
# 1. Start Quickshell dan buka developer console
# 2. Run di QML console:

// Test 1: Toggle panels
ShellState.dashboardOpen = true
ShellState.dashboardOpen = false
ShellState.togglePanel("calendar")
ShellState.togglePanel("calendar")

// Test 2: Close all panels
ShellState.dashboardOpen = true
ShellState.calendarOpen = true
ShellState.closeAllPanels()
// Expected: semua panel tertutup

// Test 3: DND toggle
ShellState.dnd = true
ShellState.dnd = false
// Expected: notifikasi tidak muncul saat dnd=true
```

**Acceptance Criteria:**
- [x] `togglePanel()` method works for all panels
- [x] `closeAllPanels()` closes all simultaneously
- [x] DND state properly toggles notifications
- [x] State changes reflected immediately in UI

### VolumeControl Service

**Test**: Audio volume control dengan debouncing

```bash
# Terminal 1: Monitor logs
tail -f /tmp/quickshell.log | grep "\[VolumeControl\]"

# Terminal 2: Run Quickshell
quickshell

# Test 1: Volume up (5x rapid presses)
# XF86AudioRaiseVolume (kernel) atau Mod+V (custom keybind)
# Expected output:
# [VolumeControl] Volume up: 30% → 35%
# [VolumeControl] Volume up: 35% → 40%
# ...
# (OSD muncul max 1x untuk sequence rapid presses)

# Test 2: Volume mute toggle
# XF86AudioMute
# Expected: Audio muted + OSD mute indicator

# Test 3: Check sink selection (with BT device)
# 1. Connect Bluetooth headphone
# 2. Press XF86AudioRaiseVolume
# Expected: Volume headphone naik, bukan speaker
```

**Acceptance Criteria:**
- [x] Volume changes 5% per keypress
- [x] OSD shows current volume %
- [x] Debouncing prevents multiple OSD updates in rapid sequence
- [x] Bluetooth device prioritized over speaker
- [x] Mute toggle works instantly
- [x] No errors in console logs

**Performance Check:**

```qml
// Di QML console:
console.log(JSON.stringify(VolumeControl.getDebugInfo(), null, 2))

// Expected output:
{
  "status": "ready",
  "volume": "45%",
  "muted": false,
  "update_count": 10,
  "error_count": 0,
  "debounce_hits": 3,  // <-- Optimization working
  "performance": {
    "debounce_interval_ms": 75
  }
}
```

### BrightnessControl Service

**Test**: Brightness control dengan debouncing

```bash
# Test 1: Brightness up (5x rapid presses)
# XF86MonBrightnessUp
# Expected: Brightness increases by 5% each
# (OSD max 1x update untuk rapid sequence)

# Test 2: Brightness down
# XF86MonBrightnessDown

# Test 3: Verify hardware integration
# Expected: `/sys/class/backlight/...` files updated
```

**Acceptance Criteria:**
- [x] Brightness changes 5% per keypress
- [x] OSD shows current brightness %
- [x] Debouncing works (cache tracking)
- [x] Hardware brightness actually changes
- [x] Works on laptops with backlight

**Performance Check:**

```qml
console.log(JSON.stringify(BrightnessControl.getDebugInfo(), null, 2))

// Expected: debounce_hits > 0, cache working
```

### ProcessManager

**Test**: Background process management

**Screenshot Process:**

```bash
# Test 1: Full screen screenshot
# Bind Print key or run:
# quickshell ipc call screenshot-full

# Expected:
# [Screenshot:Full] Triggered from shortcut
# [Screenshot:Full] Saved to: /home/user/Pictures/Screenshots/screenshot-20260813-143022.png
# + Notification popup

# Test 2: Area selection screenshot
# Bind Shift+Print key

# Expected:
# [Screenshot:Select] Triggered from shortcut
# + Grimblast area selector appears
# + Screenshot saved (atau cancelled)
```

**Cava Feed Process:**

```bash
# Test 1: Auto-start on launch
# Watch logs during Quickshell startup:
tail -f /tmp/quickshell.log | grep CavaFeed

# Expected:
# [CavaFeed] Initialized - auto-start enabled
# [CavaFeed] Started successfully

# Test 2: Verify data flowing
tail -f /tmp/qs-cava.out
# Expected: ASCII numbers flowing when audio playing

# Test 3: Media card visualizer
# 1. Open dashboard (Mod+D)
# 2. Play music with MPRIS player
# Expected: Cava ring visualizer around album art
```

**BlueZ Agent:**

```bash
# Test 1: Bluetooth pairing
# 1. Unpair a bluetooth device via bluetoothctl
# 2. Run pair command
# Expected: btagent auto-answers "yes" prompt

# Test 2: Check restart logic
# 1. Kill btagent: pkill -f btagent.sh
# 2. Watch logs for restart

# Expected:
# [BTAgent] Process stopped, will restart in 5 seconds
# [BTAgent] Restarting...
# [BTAgent] Started successfully
```

**Acceptance Criteria:**
- [x] Screenshot save to correct folder
- [x] Notification shows saved filename
- [x] Cava feed auto-starts without manual setup
- [x] Visualizer shows data in real-time
- [x] Processes restart on crash
- [x] Max retries limit (3) prevents infinite loops

---

## Integration Tests: Global Shortcuts

### Panel Toggle Shortcuts

```bash
# Test: All panel toggle shortcuts

# Mod+D (Dashboard)
# Expected: Dashboard slides down + Cava feed runs

# Mod+C (Calendar)
# Expected: Calendar panel opens

# Mod+N (Connection/Network)
# Expected: Network + Bluetooth panel opens

# Mod+V (Clipboard)
# Expected: Clipboard panel opens

# Mod+P (Power Menu)
# Expected: Power menu (shutdown/reboot/suspend/logout/lock)

# Mod+M (Menu/App Launcher)
# Expected: App launcher (walker/fuzzel) opens

# Mod+L (Lock)
# Expected: Lock screen with PAM auth
```

**Acceptance Criteria:**
- [x] All shortcuts mapped correctly
- [x] Panels open/close smoothly
- [x] Only one panel visible at time (except dashboard+media)
- [x] Escape key closes panels
- [x] Clicking outside panel closes it

### Volume/Brightness Shortcuts

```bash
# Test: XF86 media keys

XF86AudioRaiseVolume   # Volume +5%
XF86AudioLowerVolume   # Volume -5%
XF86AudioMute          # Toggle mute
XF86MonBrightnessUp    # Brightness +5%
XF86MonBrightnessDown  # Brightness -5%

# Verify:
# 1. OSD appears correctly
# 2. State persists (e.g., mute state saved)
# 3. Both keyboard & mouse scroll events work
```

### Screenshot Shortcuts

```bash
Print              # Full screen screenshot
Shift+Print        # Area selection screenshot
Mod+Shift+S        # Custom (if configured)
```

**Acceptance Criteria:**
- [x] Screenshot saved to `~/Pictures/Screenshots/`
- [x] Notification shows filename
- [x] Image copied to clipboard
- [x] Area selection works (grimblast)
- [x] Retry mechanism works if grimblast not found

---

## UI/UX Tests: Dashboard

### Dashboard Layout

```bash
# 1. Open dashboard (Mod+D)
# Expected:
# - Left column: profile pic, date, quick toggles, stats
# - Center: Media card with Cava visualizer
# - Right: System info with sparkline charts

# 2. Check responsive layout on different resolutions
# Expected: Components scale/reflow correctly
```

### Media Card

```bash
# 1. Start music player (mpv, spotify, etc.)
# 2. Open dashboard
# Expected:
# - Album art displayed
# - Cava ring visualizer around art
# - Player controls (prev/play/next) visible
# - Track info (title, artist)

# Test: Pause/resume
# Expected: Player state updates in real-time
```

### System Stats

```bash
# 1. Check sparkline charts
# Expected: CPU, GPU, RAM, Disk sparklines render

# 2. Run stress test: stress --cpu 4 --timeout 60s
# Expected: CPU sparkline updates in real-time

# 3. Monitor refresh rate
# Expected: Charts update every ~1 second
```

### Quick Toggles

```bash
# Dashboard left column:
# - IDLE: toggle hypridle on/off
# - SS SELECT: screenshot area
# - SS FULL: screenshot fullscreen
# - RECORD: toggle recording (with/without mic)
# - DND: Do Not Disturb toggle
# - NIGHT: night light toggle

# Test each toggle
# Expected: Command executes + notification shows
```

**Acceptance Criteria:**
- [x] All dashboard components visible
- [x] Charts update in real-time
- [x] Quick toggles execute commands
- [x] Layout responsive on different resolutions
- [x] No console errors or warnings

---

## UI/UX Tests: Panels

### Wallpaper Panel

```bash
# 1. Open wallpaper panel (Mod+W or right-click wallpaper button)
# Expected: Grid of wallpaper thumbnails

# 2. Hover over thumbnail → preview
# 3. Click thumbnail → apply
# Expected: Wallpaper changes with transition effect (swww)

# 4. Test slideshow
# Expected: Wallpapers change automatically every N minutes
```

### Volume Panel

```bash
# 1. Open volume panel (click speaker icon in bar)
# Expected:
# - List of audio inputs (applications)
# - Slider for each application volume
# - Output device selector

# 2. Move volume slider → OSD updates in real-time
# 3. Switch output device (speaker → headphones)
# Expected: Volume control switches to new device
```

### Connect Panel (Wi-Fi + Bluetooth)

```bash
# 1. Open connect panel (Mod+N)
# Expected: Two tabs (Wi-Fi, Bluetooth)

# Wi-Fi Tab:
# - List of available networks
# - Click to connect/disconnect
# - Show connection strength

# Bluetooth Tab:
# - List of paired devices
# - Show connection status
# - Click to connect/disconnect
```

**Acceptance Criteria:**
- [x] Panels open/close smoothly
- [x] All controls functional
- [x] State reflects actual system state
- [x] Updates in real-time

---

## Lock Screen Test

```bash
# 1. Trigger lock screen
# quickshell ipc call lockscreen lock
# Or: Mod+L

# Expected:
# - Background blurred
# - Dark overlay
# - Time displayed large
# - Date displayed
# - Profile picture

# 2. Type password
# Expected:
# - Dots show for each character
# - Visual feedback on input

# 3. Password correct → unlock
# 4. Password wrong → shake animation + error message
```

**Acceptance Criteria:**
- [x] Lock screen renders correctly
- [x] Background properly blurred
- [x] PAM authentication works
- [x] Error handling for wrong password
- [x] Unlock transitions smoothly

---

## Error Handling Tests

### Missing Dependencies

```bash
# Test 1: grimblast not installed
# 1. Uninstall grimblast: pacman -R grimblast
# 2. Press Print key
# Expected:
# [Screenshot] Failed - grimblast unavailable or error
# Notification: "Screenshot Gagal - Grimblast tidak tersedia"

# Test 2: cava not installed
# 1. Uninstall cava
# Expected:
# [CavaFeed] Process stopped (exit code: 127)
# [CavaFeed] Attempting restart (1/3)...
# Media visualizer doesn't show, but dashboard still works
```

### Audio Device Errors

```bash
# Test 1: Disconnect audio device mid-operation
# 1. Play music with BT headphones
# 2. Disconnect headphones
# Expected:
# [VolumeControl] Audio sink changed, cache invalidated
# Volume control switches to speaker

# Test 2: PipeWire crash
# 1. Kill pulseaudio/pipewire
# 2. Try volume control
# Expected:
# [VolumeControl] No audio sink available
# Error logged, no crash
```

**Acceptance Criteria:**
- [x] Services handle missing dependencies gracefully
- [x] Error messages clear & actionable
- [x] No crashes on error conditions
- [x] Recovery possible without restart

---

## Performance Tests

### Startup Time

```bash
# Measure startup time
time quickshell

# Expected: < 2 seconds from launch to first render
```

### Memory Usage

```bash
# Monitor during operation
watch -n 1 'ps aux | grep quickshell | grep -v grep | awk "{print \$6}"'

# Expected: < 200MB RSS after startup
```

### CPU Usage

```bash
# Idle state (no activity)
# Expected: < 2% CPU

# During activity (volume changes, dashboard open)
# Expected: < 10% CPU
```

### Debouncing Efficiency

```qml
// Check debounce hits after using volume keys
console.log("Debounce hits:", VolumeControl.debounceHits)

// Expected: debounceHits > 0 (optimization working)
```

---

## Accessibility Tests

### Keyboard Navigation

- [x] Tab key navigates between UI elements
- [x] Enter/Space activates buttons
- [x] Escape closes panels
- [x] Arrow keys navigate in lists/grids

### Screen Reader (if applicable)

- [x] All buttons have labels
- [x] Icons have alt text or aria-label equivalents
- [x] Color not only means of information (e.g., volume % also shown as number)

### High Contrast

- [x] Text readable on all backgrounds
- [x] Buttons have visible focus indicators
- [x] Colors pass WCAG AA contrast ratio

---

## Regression Tests: Post-Update

### After Updating Config

1. **Verify all shortcuts still work:**
   ```bash
   # Test all Mod+key combinations
   # Test all XF86 media keys
   ```

2. **Check service registration:**
   ```bash
   ls -la services/qmldir
   # Verify ShellState, VolumeControl, etc. listed
   ```

3. **Verify cava auto-start:**
   ```bash
   tail -f /tmp/qs-cava.out
   # Should show data immediately
   ```

4. **Test process restart logic:**
   ```bash
   pkill -f cava_feed.sh
   # Watch logs for automatic restart
   ```

---

## Log Analysis

### Where to Find Logs

```bash
# QML console logging
# Open in Quickshell launcher: quickshell -debug

# System journal
journalctl -u hyprland -f

# Check for warnings/errors
grep -i "error\|warn" /tmp/quickshell.log
```

### Common Warnings (Safe to Ignore)

- `QML Warning: ... cannot be overridden` → Expected during property binding
- `QML: Trying to add duplicate binding` → Usually harmless state updates
- `Property with unknown type found` → QML version compatibility

### Critical Errors (Must Fix)

- `[ServiceName] Fatal error ...` → Service crash
- `segmentation fault` → Memory issue
- `Cannot find type X` → Missing import or service

---

## Test Report Template

Use this template to document test runs:

```markdown
# Test Report - Quickshell v2.1

**Date**: 2026-08-13
**Tester**: [Your Name]
**System**: Linux [distro] [kernel]
**Hardware**: [CPU] / [GPU] / [RAM]

## Environment
- [ ] Hyprland running
- [ ] No other Quickshell instance
- [ ] Dependencies installed (grimblast, cava, swww, etc.)
- [ ] Audio working

## Results

### Services
- [x] ShellState - PASS
- [x] VolumeControl - PASS
- [ ] BrightnessControl - FAIL (reason: ...)
- [x] ProcessManager - PASS

### Shortcuts
- [x] Mod+D (Dashboard) - PASS
- [x] XF86AudioRaiseVolume - PASS
- [ ] Print (Screenshot) - FAIL (grimblast not found)

### UI/UX
- [x] Dashboard - PASS
- [x] Panels - PASS
- [x] Lock screen - PASS

## Issues Found
1. Screenshot fails without grimblast
2. Cava visualizer missing (expected behavior without cava)

## Performance
- Startup: 1.2s
- Memory: 180MB
- CPU idle: 1.2%

## Sign-off
- [ ] All critical tests passed
- [ ] Performance acceptable
- [ ] Ready for production
```

---

## Continuous Testing

### Automated Checks

Consider adding to pre-commit hook:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check QML syntax
qmlformat --check *.qml shell/*.qml services/*.qml

# Check for common errors
grep -r "property.*property" . --include="*.qml" && exit 1

exit 0
```

---

## Next Steps After Testing

1. **Document Issues**: Create GitHub issues for any bugs found
2. **Performance Profile**: Use Qt profiler if performance issues found
3. **Collect Metrics**: Track usage patterns to guide future optimization
4. **User Feedback**: Ask other users to test on their systems
5. **Release**: Mark as stable after successful testing

