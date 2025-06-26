# XY Color Space (CIE 1931) Support for EntityControl

## Overview

The EntityControl component now supports XY color space (CIE 1931) alongside the existing RGB and CCT color controls. This implementation provides a HUE slider abstraction that makes it intuitive for users to control lights that use the XY color model.

## Features Added

### 1. XY Color Space Detection
- `supportsXy` property detects if a light entity supports the XY color mode
- Updates `hasAdvancedControls` to include XY support

### 2. XY Color State Management
- `currentXyColor` property retrieves current XY coordinates from the entity state
- `currentHue` and `currentSaturation` properties convert XY to HSV for user-friendly controls
- Default to D65 white point [0.3127, 0.3290] when no XY data is available

### 3. XY Color Controls UI
- **Hue Slider**: Intuitive 0-360° hue control with rainbow gradient background
- **Saturation Slider**: 0-100% saturation control with gradient from white to full color
- **Color Preset Buttons**: Quick access to common colors in XY space
- **Current Color Indicator**: Shows the current XY coordinates and color preview

### 4. Color Conversion Functions

#### XY to RGB Conversion (`xyToRgb`)
- Converts CIE 1931 xy coordinates to RGB values
- Uses proper XYZ to sRGB transformation matrix
- Applies gamma correction for accurate color representation
- Clamps values to valid RGB range [0-255]

#### XY to HSV Conversion
- `xyToHue`: Converts XY coordinates to HSV hue (0-360°)
- `xyToSaturation`: Converts XY coordinates to HSV saturation (0-1)

#### HSV to XY Conversion (`hueToXy`)
- Converts HSV hue and saturation back to XY coordinates
- Handles proper RGB to XYZ transformation
- Applies inverse gamma correction
- Clamps to valid CIE 1931 color space bounds

#### Utility Functions
- `xyToRgbColor`: Returns Qt color object for UI display
- `hueToRgbColor`: Returns pure hue color for gradient displays

## Usage

### In QML
The XY controls automatically appear for lights that support the XY color mode:

```qml
EntityControl {
    entityId: "light.philips_hue_bulb"
    displayName: "Living Room Light"
    controlType: "light"
    showExpandedControls: true
}
```

### Home Assistant Integration
The component sends XY color commands to Home Assistant:

```javascript
// Set specific XY coordinates
controlActivated(entityId, "turn_on", { xy_color: [0.7006, 0.2993] })

// Set color via hue/saturation sliders
var xyColor = hueToXy(180, 0.8) // Cyan at 80% saturation
controlActivated(entityId, "turn_on", { xy_color: [xyColor.x, xyColor.y] })
```

## Color Presets

The implementation includes 6 carefully chosen color presets in XY space:

1. **Red**: [0.7006, 0.2993] - Deep red
2. **Green**: [0.1724, 0.7468] - Vivid green
3. **Blue**: [0.1357, 0.0399] - Pure blue
4. **Yellow**: [0.4316, 0.5016] - Bright yellow
5. **White**: [0.3127, 0.3290] - D65 white point
6. **Deep Blue**: [0.1670, 0.0090] - Deep blue

## Entity Information Display

The Entity Information section now shows:
- Current XY coordinates in 4-decimal precision
- Properly formatted as "(x, y)" pairs
- Only displays when XY color data is available

## Technical Details

### Color Space Accuracy
- Uses proper sRGB color space transformations
- Implements CIE 1931 XY chromaticity coordinates
- Handles edge cases with fallback to D65 white point
- Maintains color accuracy across different light hardware

### Performance Considerations
- Color conversions are cached where possible
- Slider updates are debounced to prevent excessive API calls
- Gradient generation is optimized for smooth UI rendering

### Compatibility
- Works alongside existing RGB and CCT controls
- Automatically hides when XY mode is not supported
- Maintains backward compatibility with existing configurations

## Browser Support

The XY color space implementation works with:
- Philips Hue lights (native XY support)
- LIFX lights (with XY color mode)
- Other smart lights supporting CIE 1931 XY color space
- Home Assistant lights with `xy` in supported_color_modes

## Future Enhancements

Potential improvements could include:
- 2D color picker with XY gamut visualization
- Color temperature to XY conversion
- Gamut limiting for specific light models
- Color harmony suggestions based on current XY values
