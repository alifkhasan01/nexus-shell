# Rotating Album Cover - Quick Start

## TL;DR (Too Long; Didn't Read)

Sudah buat 2 komponen buat album cover berputar:

1. **RotatingAlbumCover.qml** - Reusable component
2. **FullscreenMediaPlayer.qml** - Fullscreen player (like Caelestia)

**Fitur utama**:
- ✅ Album cover berputar smooth saat playing
- ✅ Pause otomatis saat pause
- ✅ Purple glow effects (customizable)
- ✅ Large display + fullscreen option
- ✅ Complete playback controls

---

## Quick Integration

### 1. Sudah Terintegrasi (No Action Needed)

MediaCard.qml **sudah punya** rotating animation:

```qml
Image {
    id: albumImage
    // ...
    RotationAnimator on rotation {
        running: root.hasPlayer &&
                 root.player.playbackState === MprisPlaybackState.Playing
        from: 0; to: 360
        duration: 16000
        loops: Animation.Infinite
    }
}
```

**Result**: Album art di media card sudah rotating! ✓

### 2. Add Fullscreen Player (Optional)

Di `dashboard/Dashboard.qml`, tambah import dan tab baru:

```qml
import "../panels" as Panels

// Di dalam tab/swipe view
Tab {
    title: "Music"
    
    Panels.FullscreenMediaPlayer {
        anchors.fill: parent
    }
}
```

### 3. Create Standalone Music Player Panel (Optional)

Buat file: `panels/MusicPlayerPanel.qml`

```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell

PanelWindow {
    width: 500
    height: 700
    layer: 100
    title: "Music Player"
    
    FullscreenMediaPlayer {
        anchors.fill: parent
    }
}
```

---

## File Locations

```
~/.config/quickshell/
├── dashboard/
│   ├── MediaCard.qml              (already rotating!)
│   └── RotatingAlbumCover.qml     (new component)
├── panels/
│   └── FullscreenMediaPlayer.qml  (new fullscreen player)
└── docs/
    ├── MEDIA_PLAYER_ROTATING_COVER.md
    └── ROTATING_COVER_USAGE.md (this file)
```

---

## Visual Comparison

### MediaCard (Small - Currently in Dashboard)

```
┌──────────────────────────────┐
│ ↻ | Track Title   ⏮ ⏸ ⏭  │
│   | Artist        controls  │
└──────────────────────────────┘
```

**Album art**: 64x64px rotating

### FullscreenMediaPlayer (Large - New)

```
┌─────────────────────────────────┐
│                                 │
│      ╭──────────────────╮      │
│      │                  │      │
│      │   ↻ ALBUM ART   │      │
│      │   (320x320px)   │      │
│      │                  │      │
│      ╰──────────────────╯      │
│                                 │
│       Track Title               │
│       Artist Name               │
│       Album Name                │
│                                 │
│   Progress Bar ═══════════      │
│                                 │
│  [Shuffle] ⏮  ⏯  ⏭ [Repeat]  │
│                                 │
└─────────────────────────────────┘
```

**Album art**: 320x320px rotating dengan glow effect

---

## Customization Examples

### Change Rotation Speed

```qml
RotatingAlbumCover {
    rotationSpeed: 15  // Faster (15 seconds)
    // or
    rotationSpeed: 30  // Slower (30 seconds)
}
```

### Change Border Color

```qml
RotatingAlbumCover {
    borderColor: "#FF6B6B"    // Red
    borderColor: "#4ECDC4"    // Teal
    borderColor: "#FFE66D"    // Yellow
}
```

### Change Size

```qml
RotatingAlbumCover {
    size: 200   // Small
    size: 400   // Large
    size: 500   // Extra large
}
```

### Combine Customizations

```qml
RotatingAlbumCover {
    size: 350
    borderColor: "#4ECDC4"
    rotationSpeed: 25
    borderWidth: 6
}
```

---

## How Rotation Works

### Flow Diagram

```
Playing State
    ↓
RotationAnimation starts
    ↓
Image rotates 0° → 360°
    ↓
Duration = rotationSpeed * 1000 (milliseconds)
    ↓
Loop infinitely while isPlaying = true
    ↓
Pause pressed → Animation pauses
    ↓
Play pressed → Animation resumes
```

### Animation Parameters

| Parameter | Current | Explanation |
|-----------|---------|-------------|
| From | 0° | Start rotation angle |
| To | 360° | End rotation (full circle) |
| Duration | 20000ms | Time untuk complete rotation |
| Loops | Infinite | Keep rotating |
| Running | isPlaying | Kontrol by play state |

---

## Testing

### Test 1: Verify Rotation

```bash
# 1. Start quickshell
quickshell

# 2. Open Media Card (usually in Dashboard tab)

# 3. Play music from music player (Spotify, mpd, etc.)

# 4. Watch album cover rotate smoothly ✓
```

### Test 2: Verify Pause

```bash
# 1. Music playing (cover rotating)
# 2. Press pause in music player
# 3. Cover should stop rotating ✓
# 4. Press play
# 5. Cover resumes rotating ✓
```

### Test 3: Fullscreen Player

```bash
# 1. If integrated to Dashboard:
#    - Go to Music tab
#    - See large rotating album cover
#    - Controls fully functional ✓

# 2. If standalone panel:
#    - Open music player panel
#    - Large cover visible
#    - All controls working ✓
```

---

## Common Issues & Fixes

### Issue: Cover not rotating

**Cause**: MPRIS not detected or `isPlaying` false

**Fix**:
```bash
# Check MPRIS service
qdbus org.mpris.MediaPlayer2.* /org/mpris/MediaPlayer2 \
    org.mpris.MediaPlayer2.Player.PlaybackStatus

# Should show "Playing"
```

### Issue: Animation too fast/slow

**Fix**: Adjust `duration` in RotationAnimation:
```qml
duration: 10000  // 10 seconds (faster)
duration: 30000  // 30 seconds (slower)
```

### Issue: Cover not visible

**Cause**: albumArt URL invalid or background color issue

**Fix**:
```qml
albumArt: "file:///home/user/Music/cover.jpg"  // Absolute path
albumArt: player.trackArtUrl  // Bind to player
```

### Issue: Border/glow not visible

**Fix**:
```qml
borderColor: "#FFFFFF"  // White (high contrast for test)
borderWidth: 8          // Thicker border
```

---

## Code Location Reference

### Component 1: RotatingAlbumCover

**File**: `~/.config/quickshell/dashboard/RotatingAlbumCover.qml`

**Key Code**:
```qml
transform: Rotation {
    id: imageRotation
    origin.x: albumImage.width / 2
    origin.y: albumImage.height / 2
    angle: 0
}

RotationAnimation {
    target: imageRotation
    from: 0; to: 360
    duration: root.rotationSpeed * 1000
    running: root.isPlaying
    loops: Animation.Infinite
}
```

### Component 2: FullscreenMediaPlayer

**File**: `~/.config/quickshell/panels/FullscreenMediaPlayer.qml`

**Key Code**:
```qml
Image {
    id: albumArt
    // ...
    RotationAnimation {
        target: coverRotation
        from: 0; to: 360
        duration: 20000
        running: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing
        loops: Animation.Infinite
    }
}
```

---

## Properties Reference

### RotatingAlbumCover Properties

```qml
property url albumArt              // Path to image
property bool isPlaying            // Control rotation
property real rotationSpeed        // Duration in seconds (default: 20)
property real size                 // Size in pixels (default: 280)
property color borderColor         // Border color (default: #9C6FDE)
property real borderWidth          // Border width (default: 8)
property real shadowBlur           // Shadow blur (default: 30)
```

### FullscreenMediaPlayer Properties

```qml
property var player                // MPRIS player object
property bool hasPlayer            // Check if player available
```

---

## Color Presets

Ready-to-use color schemes:

**Purple** (Current):
```qml
borderColor: "#9C6FDE"
```

**Blue**:
```qml
borderColor: "#6B9EFF"
```

**Green**:
```qml
borderColor: "#2ECC71"
```

**Red**:
```qml
borderColor: "#FF6B6B"
```

**Pink**:
```qml
borderColor: "#FF6B9D"
```

**Teal**:
```qml
borderColor: "#4ECDC4"
```

**Orange**:
```qml
borderColor: "#FFA500"
```

**Yellow**:
```qml
borderColor: "#FFE66D"
```

---

## Speed Presets

Ready-to-use rotation speeds:

```qml
rotationSpeed: 10   // Fast (energetic)
rotationSpeed: 15   // Moderate fast
rotationSpeed: 20   // **Recommended** (smooth)
rotationSpeed: 25   // Moderate slow
rotationSpeed: 30   // Slow (relaxed)
```

---

## Size Presets

For different contexts:

```qml
size: 100   // Tiny (icons)
size: 150   // Small (thumbnails)
size: 200   // Medium (cards)
size: 280   // **Default** (dashboard)
size: 320   // Large (panels)
size: 400   // XL (fullscreen emphasis)
size: 500   // XXL (wall display)
```

---

## Integration Checklist

- [ ] Files created:
  - [ ] `RotatingAlbumCover.qml`
  - [ ] `FullscreenMediaPlayer.qml`
  - [ ] Documentation created

- [ ] MediaCard testing:
  - [ ] Album art visible
  - [ ] Rotates when playing
  - [ ] Stops when paused

- [ ] Optional: Fullscreen player:
  - [ ] Add to Dashboard
  - [ ] All controls functional
  - [ ] Animation smooth

- [ ] Customization (optional):
  - [ ] Adjusted colors
  - [ ] Modified speed
  - [ ] Changed size

---

## Related Documentation

- **MEDIA_PLAYER_ROTATING_COVER.md** - Detailed technical guide
- **Dashboard components** - Where media player integrated
- **Qt Rotation Animation** - Official docs

---

## Summary

**What Was Created**:
- Rotating album cover component
- Fullscreen music player
- Documentation & guides

**Current Status**:
- ✅ MediaCard already rotating (no action needed!)
- ✅ Fullscreen player ready (optional integration)
- ✅ Fully customizable

**Next Steps**:
1. Verify album art in dashboard rotates ✓
2. If want fullscreen player → integrate to Dashboard
3. Customize colors/speed as preferred

---

**Enjoy! 🎵↻**

*Last updated: August 17, 2026*
