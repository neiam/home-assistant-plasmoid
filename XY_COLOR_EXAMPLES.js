// Example showing XY Color Space usage in EntityControl

// Mock entity state for testing XY color support
var mockEntityState = {
    state: "on",
    attributes: {
        friendly_name: "Philips Hue Color Light",
        brightness: 200,
        supported_color_modes: ["xy", "color_temp", "brightness"],
        xy_color: [0.3127, 0.3290], // D65 white point
        color_mode: "xy"
    },
    last_updated: new Date().toISOString()
}

// Example usage in QML
/*
EntityControl {
    id: xyLightControl
    entityId: "light.hue_color_bulb"
    displayName: "Hue Color Bulb"
    controlType: "light"
    showExpandedControls: true
    entityState: mockEntityState
    
    // Handle color changes
    onControlActivated: function(entityId, action, data) {
        if (data.xy_color) {
            console.log("Setting XY color:", data.xy_color)
            // Send to Home Assistant API
            // PUT /api/services/light/turn_on
            // {
            //   "entity_id": entityId,
            //   "xy_color": data.xy_color
            // }
        }
    }
}
*/

// Color conversion examples
console.log("=== XY Color Conversion Examples ===")

// Convert common colors to XY coordinates
var redXY = hueToXy(0, 1.0)      // Pure red
var greenXY = hueToXy(120, 1.0)  // Pure green  
var blueXY = hueToXy(240, 1.0)   // Pure blue
var cyanXY = hueToXy(180, 0.8)   // Cyan at 80% saturation

console.log("Red XY:", redXY)
console.log("Green XY:", greenXY)
console.log("Blue XY:", blueXY)
console.log("Cyan XY:", cyanXY)

// Convert XY back to hue/saturation
var redHSV = {
    hue: xyToHue(redXY.x, redXY.y),
    saturation: xyToSaturation(redXY.x, redXY.y)
}

console.log("Red HSV:", redHSV)

// Test RGB conversion
var rgbFromXY = xyToRgb(0.7006, 0.2993) // Red preset
console.log("RGB from XY:", rgbFromXY)

// Common XY coordinates for reference
var commonColors = {
    "Warm White": [0.4209, 0.3761],
    "Cool White": [0.3127, 0.3290],
    "Red": [0.7006, 0.2993],
    "Orange": [0.5614, 0.4156],
    "Yellow": [0.4316, 0.5016],
    "Green": [0.1724, 0.7468],
    "Cyan": [0.1532, 0.3297],
    "Blue": [0.1357, 0.0399],
    "Purple": [0.2451, 0.1056],
    "Pink": [0.3960, 0.2151]
}

console.log("Common XY Colors:", commonColors)

// Gamut validation (for future implementation)
function isWithinSRGBGamut(x, y) {
    // sRGB triangle vertices in xy space
    var sRGB_vertices = [
        [0.64, 0.33],  // Red
        [0.30, 0.60],  // Green  
        [0.15, 0.06]   // Blue
    ]
    
    // Point-in-triangle test (simplified)
    // In a real implementation, you'd use proper barycentric coordinates
    return x >= 0 && x <= 1 && y >= 0 && y <= 1 && (x + y) <= 1
}

// Test gamut validation
console.log("Red in sRGB gamut:", isWithinSRGBGamut(0.7006, 0.2993))
console.log("Green in sRGB gamut:", isWithinSRGBGamut(0.1724, 0.7468))
