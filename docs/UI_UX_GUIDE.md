# UI/UX Improvement Guide

Panduan untuk meningkatkan user experience dan accessibility di Quickshell config.

---

## Overview

Config Quickshell sudah memiliki design yang solid. Guide ini mencakup:

1. **Accessibility Best Practices** — untuk semua pengguna
2. **Animation Recommendations** — smooth transitions tanpa kinerja menurun
3. **Hover States & Feedback** — visual feedback yang jelas
4. **Responsive Design** — bekerja di berbagai resolusi
5. **Color & Contrast** — WCAG compliance
6. **Keyboard Navigation** — navigasi tanpa mouse

---

## 1. Accessibility Best Practices

### Keyboard Navigation

Pastikan semua UI elements navigable dengan keyboard:

```qml
// BAD: Not keyboard accessible
Button {
    text: "Click me"
    onClicked: doSomething()
    // Tidak bisa di-focus
}

// GOOD: Keyboard accessible
Button {
    text: "Click me"
    onClicked: doSomething()
    Keys.onReturnPressed: doSomething()
    Keys.onSpacePressed: doSomething()
    focus: true
    // Tab dapat navigate ke button ini
}
```

### Color Contrast

WCAG AA standard: 4.5:1 untuk normal text, 3:1 untuk large text

Check contrast dengan Catppuccin colors:

```qml
// GOOD: Sufficient contrast (7:1)
Text {
    text: "Important"
    color: Root.Colors.text        // Catppuccin text color
    background: Rectangle {
        color: Root.Colors.base    // Catppuccin base
    }
}

// BAD: Insufficient contrast (2:1)
Text {
    text: "Subtle"
    color: Root.Colors.surface1    // Too close to background
    background: Rectangle {
        color: Root.Colors.base
    }
}
```

**Catppuccin Color Contrast (Mocha):**

| Foreground | Background | Ratio | Status |
|---|---|---|---|
| `text` | `base` | 8:1 | ✅ AAA |
| `text` | `mantle` | 7:1 | ✅ AA |
| `subtext0` | `base` | 5:1 | ✅ AA |
| `subtext1` | `base` | 3:1 | ⚠️ Large text only |
| `surface1` | `base` | 1.5:1 | ❌ Use for borders only |

### Focus Indicators

Always show focus state clearly:

```qml
Rectangle {
    id: focusable
    color: Root.Colors.surface0
    
    border.width: activeFocus ? 2 : 0
    border.color: activeFocus ? Root.Colors.blue : "transparent"
    
    // Outline for better visibility
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: activeFocus ? 2 : 0
        border.color: Root.Colors.blue
        visible: activeFocus
    }
    
    Keys.onReturnPressed: doSomething()
}
```

### Screen Reader Support

Add semantic meaning to components:

```qml
// BAD: Not descriptive
Rectangle {
    width: 40; height: 40
    Text { text: "●" }  // Ambiguous
}

// GOOD: Descriptive
Rectangle {
    width: 40; height: 40
    property string ariaLabel: "Volume indicator at 50%"
    
    Text { 
        text: "●"
        Accessible.name: parent.ariaLabel
        Accessible.role: Accessible.Indicator
    }
}
```

---

## 2. Animation Recommendations

### Panel Open/Close Animations

Smooth animations tanpa blocking:

```qml
// GOOD: Smooth fade + slide
SequentialAnimation {
    ParallelAnimation {
        NumberAnimation {
            target: panelContainer
            property: "opacity"
            from: 0; to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: panelContainer
            property: "y"
            from: -panelContainer.height
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
}

// BAD: Too slow atau janky
Behavior on opacity { NumberAnimation { duration: 500 } }
```

### Hover State Animations

Immediate feedback dengan smooth transition:

```qml
// GOOD: Immediate feedback
Rectangle {
    id: button
    color: Root.Colors.surface0
    
    // Fast response, smooth transition
    Behavior on color {
        ColorAnimation { duration: 80 }
    }
    
    MouseArea {
        anchors.fill: parent
        onEntered: button.color = Root.Colors.surface1
        onExited: button.color = Root.Colors.surface0
        onPressed: button.color = Root.Colors.blue
    }
}
```

### Avoid Animation Stutter

Keep animations on 60fps:

```qml
// BAD: Heavy computation dalam animation
Timer {
    running: true
    interval: 16  // ~60fps
    onTriggered: {
        // Heavy operation → stutter
        expensiveCalculation()
        updateUI()
    }
}

// GOOD: Pre-calculate values
Timer {
    running: true
    interval: 16
    onTriggered: {
        // Light operation → smooth
        value = preCalculatedValues[frameCount++]
    }
}
```

---

## 3. Hover States & Visual Feedback

### Button Hover States

```qml
Button {
    text: "Click me"
    background: Rectangle {
        color: {
            if (parent.pressed) return Root.Colors.blue
            if (parent.hovered) return Root.Colors.surface1
            return Root.Colors.surface0
        }
        
        Behavior on color { ColorAnimation { duration: 80 } }
    }
}
```

### Feedback untuk Actions

```qml
// Screenshot feedback
Timer {
    id: feedbackTimer
    interval: 2000
    onTriggered: feedbackLabel.opacity = 0
}

Text {
    id: feedbackLabel
    text: "Screenshot saved!"
    opacity: 1
    
    Behavior on opacity { NumberAnimation { duration: 200 } }
}

// Trigger feedback
onScreenshotFinished: {
    feedbackLabel.opacity = 1
    feedbackTimer.restart()
}
```

### Loading States

```qml
// Untuk process yang delayed
Rectangle {
    id: loader
    width: 20; height: 20
    
    RotationAnimation {
        target: loader
        from: 0; to: 360
        duration: 1000
        running: isLoading
        loops: Animation.Infinite
    }
}
```

---

## 4. Responsive Design

### Adaptive Layouts

```qml
// Responsive untuk berbagai resolusi
Rectangle {
    width: parent.width
    height: parent.height
    
    ColumnLayout {
        anchors.fill: parent
        
        // Main content area
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            // Responsive padding
            property int padding: root.width > 2000 ? 32 : 16
        }
    }
    
    states: [
        State {
            name: "wideScreen"
            when: root.width > 2000
            PropertyChanges {
                target: layout
                spacing: 24
            }
        },
        State {
            name: "narrowScreen"
            when: root.width < 1366
            PropertyChanges {
                target: layout
                spacing: 12
            }
        }
    ]
}
```

### Flexible Grid Layouts

```qml
GridLayout {
    width: parent.width
    height: parent.height
    
    // Automatically adapt columns
    columns: Math.max(1, Math.floor(width / 300))
    
    Repeater {
        model: items
        delegate: Rectangle {
            Layout.fillWidth: true
            height: 200
        }
    }
}
```

---

## 5. Color & Contrast

### Using Catppuccin Effectively

```qml
// Primary content
Text {
    color: Root.Colors.text
}

// Secondary content (less emphasis)
Text {
    color: Root.Colors.subtext0
}

// Subtle content (hints, descriptions)
Text {
    color: Root.Colors.subtext1
}

// Accent colors
Rectangle {
    color: Root.Colors.blue      // Primary action
}

Rectangle {
    color: Root.Colors.yellow    // Warning
}

Rectangle {
    color: Root.Colors.red       // Danger/Error
}

Rectangle {
    color: Root.Colors.green     // Success
}
```

### Dark/Light Mode Support

Already handled by Catppuccin theme switching. Just use `Root.Colors.*` consistently.

```qml
// BAD: Hardcoded colors
Rectangle { color: "#1e1e2e" }

// GOOD: Theme-aware
Rectangle { color: Root.Colors.base }
```

---

## 6. Keyboard Navigation Implementation

### Tab Order Management

```qml
Item {
    id: panel
    focus: true
    
    // Define tab order explicitly
    TabOrder {
        items: [button1, button2, textInput, button3]
    }
    
    // Or use focusSequence
    Keys.onTabPressed: nextButton.focus = true
    Keys.onBacktabPressed: previousButton.focus = true
}
```

### Escape to Close

```qml
// Panels should close on Escape
Rectangle {
    id: panel
    focus: true
    
    Keys.onEscapePressed: panel.close()
}
```

### Arrow Key Navigation

```qml
// For lists/grids
ListView {
    focus: true
    
    Keys.onUpPressed: decrementCurrentIndex()
    Keys.onDownPressed: incrementCurrentIndex()
    Keys.onLeftPressed: decrementCurrentIndex()
    Keys.onRightPressed: incrementCurrentIndex()
    Keys.onReturnPressed: selectCurrentItem()
}
```

---

## 7. Common Patterns to Implement

### Loading Indicator Pattern

```qml
// Show loading state
Rectangle {
    id: loader
    visible: isLoading
    
    BusyIndicator {
        anchors.centerIn: parent
        running: isLoading
    }
    
    Text {
        text: "Loading..."
        anchors.centerIn: parent
        anchors.topMargin: 40
    }
}
```

### Empty State Pattern

```qml
// Show empty state when no data
Rectangle {
    visible: model.count === 0
    
    Column {
        anchors.centerIn: parent
        spacing: 16
        
        Text {
            text: "No items"
            font.pointSize: 14
        }
        
        Text {
            text: "Try adding something new"
            color: Root.Colors.subtext0
        }
        
        Button {
            text: "Create"
            onClicked: createNew()
        }
    }
}
```

### Error State Pattern

```qml
// Show error state
Rectangle {
    visible: hasError
    color: Root.Colors.surface0
    
    border.color: Root.Colors.red
    border.width: 1
    
    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        
        Text {
            text: "Error"
            color: Root.Colors.red
            font.bold: true
        }
        
        Text {
            text: errorMessage
            color: Root.Colors.text
            wrapMode: Text.Wrap
        }
        
        Button {
            text: "Retry"
            onClicked: retry()
        }
    }
}
```

---

## 8. Tooltip & Help Text

```qml
// Hover untuk tooltip
MouseArea {
    hoverEnabled: true
    
    ToolTip {
        visible: parent.containsMouse
        text: "This button takes a screenshot"
        delay: 500
        timeout: 3000
    }
}
```

---

## 9. Animation Performance Checklist

Before adding animation:

- [ ] Does animation improve UX or just distract?
- [ ] Is animation duration < 300ms (perceived as instant)?
- [ ] Is 60fps achievable without dropping frames?
- [ ] Does animation respect system acceleration preferences?
- [ ] Can animation be disabled in settings if needed?

---

## 10. Testing UI Changes

### Before Merging UI Changes

```bash
# 1. Test on different resolutions
# 1280x720 (minimal), 1920x1080 (common), 2560x1440 (high)

# 2. Test with different Catppuccin themes
# Latte, Frappé, Macchiato, Mocha

# 3. Test keyboard navigation
# Tab through all interactive elements
# Escape closes panels
# Enter/Space activates buttons

# 4. Test with accessibility
# Screenshot with color blindness simulator
# Check contrast ratios

# 5. Performance test
# Monitor CPU/Memory during animations
# No frame drops (60fps target)
```

---

## Recommended Next Steps

### Priority 1: Critical Accessibility
- [x] Focus indicators on all interactive elements
- [x] Keyboard navigation for panels
- [x] Color contrast compliance (WCAG AA)

### Priority 2: Smooth Animations
- [ ] Panel open/close transitions (150ms)
- [ ] Hover state animations (80ms)
- [ ] Smooth property transitions

### Priority 3: Visual Feedback
- [ ] Loading states for async operations
- [ ] Success/error notifications
- [ ] Progress indicators

### Priority 4: Polish
- [ ] Tooltip for complex controls
- [ ] Empty state when no data
- [ ] Skeleton loading for lazy-loaded content

---

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [QML Accessibility](https://doc.qt.io/qt-6/qtquick-accessible.html)
- [Catppuccin Design Guide](https://github.com/catppuccin/catppuccin)
- [Material Design Motion](https://material.io/design/motion/understanding-motion.html)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)

---

## Contributing UI Improvements

When submitting UI improvements:

1. **Check accessibility first** — does it work with keyboard/screen reader?
2. **Verify contrast** — use Color Contrast Analyzer tool
3. **Test performance** — no frame drops, < 300MB memory
4. **Test responsiveness** — works on 1280x720 to 4K
5. **Document changes** — explain why this improves UX

