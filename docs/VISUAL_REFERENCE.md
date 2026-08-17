# Visual Reference Guide - Design Updates

## Main Card Styling

### Main Container Changes
```qml
// BEFORE
Rectangle {
    radius: 20
    color: Root.Colors.mantle
    border.color: Root.Colors.surface2
    border.width: 2
}

// AFTER
Rectangle {
    radius: 24
    color: Root.Colors.mantle
    border.color: Qt.rgba(Root.Colors.surface2.r, Root.Colors.surface2.g, Root.Colors.surface2.b, 0.5)
    border.width: 1
    clip: true
    
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 32
        shadowColor: Qt.rgba(0, 0, 0, 0.3)
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 8
    }
}
```

## Component Cards Pattern

### Profile Card Example
```qml
// BEFORE
Rectangle {
    width: parent.width
    height: 76
    radius: 14
    color: Root.Colors.base
}

// AFTER
Rectangle {
    width: parent.width
    height: 76
    radius: 16
    color: Root.Colors.base
    border.color: Qt.rgba(Root.Colors.surface1.r, Root.Colors.surface1.g, Root.Colors.surface1.b, 0.4)
    border.width: 1
    Behavior on color { ColorAnimation { ... } }
    Behavior on border.color { ColorAnimation { ... } }
}
```

## Button/Toggle Components

### Quick Toggle Button
```qml
// BEFORE
Rectangle {
    radius: 14
    color: active ? Root.Colors.blue : Root.Colors.surface0
}

// AFTER
Rectangle {
    radius: 14
    color: active ? Root.Colors.blue : Root.Colors.surface0
    border.color: Qt.rgba(Root.Colors.surface1.r, Root.Colors.surface1.g, Root.Colors.surface1.b, 0.3)
    border.width: 1
    
    Behavior on color { ColorAnimation { ... } }
    Behavior on border.color { ColorAnimation { ... } }
}
```

## Slider Components

### Slider Track & Handle
```qml
// BEFORE
background: Rectangle {
    height: 6
    radius: 3
    color: Root.Colors.surface0
    
    Rectangle {
        width: slider.visualPosition * parent.width
        color: Root.Colors.blue
    }
}

handle: Rectangle {
    width: 14
    height: 14
    radius: 7
    color: Root.Colors.text
}

// AFTER
background: Rectangle {
    height: 6
    radius: 3
    color: Root.Colors.surface0
    border.color: Qt.rgba(Root.Colors.surface1.r, Root.Colors.surface1.g, Root.Colors.surface1.b, 0.2)
    border.width: 1
    
    Rectangle {
        width: slider.visualPosition * parent.width
        color: Root.Colors.blue
        Behavior on width { 
            NumberAnimation { duration: 50; easing.type: Easing.OutQuad }
        }
    }
}

handle: Rectangle {
    width: 14
    height: 14
    radius: 7
    color: Root.Colors.text
    border.color: Root.Colors.blue
    border.width: slider.pressed ? 2 : 1
    Behavior on border.width { NumberAnimation { duration: 100 } }
    
    layer.enabled: slider.pressed
    layer.effect: MultiEffect {
        shadowEnabled: slider.pressed
        shadowBlur: 12
        shadowColor: Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.4)
    }
}
```

## Border Styling Pattern

All components use this border strategy:
```javascript
// Semi-transparent border based on surface color
border.color: Qt.rgba(
  Root.Colors.surface1.r,   // Red channel
  Root.Colors.surface1.g,   // Green channel
  Root.Colors.surface1.b,   // Blue channel
  0.3 to 0.4                // Opacity for subtlety
)
border.width: 1px           // Always 1px for consistency
```

## Shadow Pattern

Used on elevated elements:
```javascript
layer.effect: MultiEffect {
    shadowEnabled: true
    shadowBlur: 32              // 32px blur for main card
    shadowColor: Qt.rgba(0, 0, 0, 0.3)
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 8     // 8px drop
}
```

## Animation Patterns

### Color Transition
```javascript
Behavior on color { 
    ColorAnimation {
        duration: Root.Appearance.animation.elementMoveFast.duration
        easing.type: Root.Appearance.animation.elementMoveFast.type
        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
    }
}
```

### Slider Progress
```javascript
NumberAnimation {
    target: progressRect
    property: "width"
    duration: 50
    easing.type: Easing.OutQuad
}
```

## Radius Guidelines

- Main Card: `24px` - Most prominent, generous rounding
- Component Cards: `16px` - Standard cards (profiles, media)
- Stats Cards: `12px` - Smaller components
- Buttons/Toggles: `14px` - Interactive elements
- Sliders: `3px` - Minimal, linear elements

## Color Transparency Guidelines

- Active borders: `0.4` opacity - Stronger presence
- Inactive borders: `0.3` opacity - Subtle separation
- Hover states: `0.5` opacity - Enhanced visibility

## Before/After Comparison

### Overall Visual Impact

**BEFORE**
- Flat, minimal aesthetic
- No depth perception
- Hard borders
- Limited visual hierarchy
- Professional but cold

**AFTER**
- Modern, polished aesthetic
- Clear depth through shadows
- Subtle, elegant borders
- Strong visual hierarchy
- Professional and warm

### Component Examples

**Profile Card**
- Increased border radius for softness
- Added subtle border for definition
- Better visual separation from background

**Toggle Buttons**
- Each button now has distinct border
- Better hover feedback
- Consistent styling across all toggles

**Sliders**
- Animated progress bar
- Glowing handle on interaction
- Better visual feedback

## Implementation Notes

1. All colors use `Root.Colors.*` tokens for theme consistency
2. All animations use `Root.Appearance.animation.*` for unified timing
3. Border color uses parent color with reduced opacity for harmony
4. Shadows only on elevated elements (main card, focused sliders)
5. Radius increases with element prominence

## Testing Checklist

- ✅ Main card has visible shadow
- ✅ All cards have subtle 1px borders
- ✅ Toggle buttons show borders
- ✅ Slider handle glows when pressed
- ✅ Colors transition smoothly
- ✅ No harsh edges or flat appearance
- ✅ Consistent border styling across all components
