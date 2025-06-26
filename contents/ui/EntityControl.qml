import QtQuick 2.15
import QtQuick.Controls as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

Item {
    id: entityControl
    
    property string entityId: ""
    property string displayName: ""
    property string controlType: "toggle"
    property string iconName: "home-assistant"
    property bool showLabel: true
    property string buttonSize: "medium"
    property var entityState: null
    property bool isOn: entityState ? (entityState.state === "on" || entityState.state === "home" || entityState.state === "open") : false
    property bool isLoadingState: false
    property bool hasValidState: entityState !== null && entityState !== undefined
    property bool showExpandedControls: false
    
    // Light-specific properties
    readonly property bool isLight: entityId.split('.')[0] === 'light'
    readonly property bool supportsRgb: entityState && entityState.attributes && entityState.attributes.supported_color_modes && 
                                       (entityState.attributes.supported_color_modes.indexOf('rgb') !== -1 || 
                                        entityState.attributes.supported_color_modes.indexOf('rgbw') !== -1 ||
                                        entityState.attributes.supported_color_modes.indexOf('rgbww') !== -1)
    readonly property bool supportsCct: entityState && entityState.attributes && entityState.attributes.supported_color_modes && 
                                       (entityState.attributes.supported_color_modes.indexOf('color_temp') !== -1)
    readonly property bool supportsXy: entityState && entityState.attributes && entityState.attributes.supported_color_modes && 
                                      (entityState.attributes.supported_color_modes.indexOf('xy') !== -1)
    readonly property bool supportsBrightness: entityState && entityState.attributes && entityState.attributes.supported_color_modes && 
                                              (entityState.attributes.supported_color_modes.indexOf('brightness') !== -1 || 
                                               entityState.attributes.brightness !== undefined)
    readonly property int currentBrightness: entityState && entityState.attributes && entityState.attributes.brightness ? 
                                           Math.round(entityState.attributes.brightness / 255 * 100) : 0
    readonly property var currentRgbColor: entityState && entityState.attributes && entityState.attributes.rgb_color ? 
                                         entityState.attributes.rgb_color : [255, 255, 255]
    readonly property int currentColorTemp: entityState && entityState.attributes && entityState.attributes.color_temp ? 
                                          entityState.attributes.color_temp : 370
    readonly property var currentXyColor: entityState && entityState.attributes && entityState.attributes.xy_color ? 
                                        entityState.attributes.xy_color : [0.3127, 0.3290] // D65 white point
    readonly property real currentHue: xyToHue(currentXyColor[0], currentXyColor[1])
    readonly property real currentSaturation: xyToSaturation(currentXyColor[0], currentXyColor[1])
    
    signal controlActivated(string entityId, string action, var data)
    signal stateRequested(string entityId)
    
    readonly property int buttonSizePixels: {
        switch (buttonSize) {
            case "small": return Kirigami.Units.iconSizes.medium
            case "large": return Kirigami.Units.iconSizes.huge
            default: return Kirigami.Units.iconSizes.large
        }
    }
    
    readonly property bool hasAdvancedControls: isLight && controlType === "light" && (supportsRgb || supportsCct || supportsXy || supportsBrightness)
    
    width: showExpandedControls ? parent.width : (buttonSizePixels + (showLabel ? Kirigami.Units.smallSpacing : 0))
    height: showExpandedControls ? parent.height : (buttonSizePixels + (showLabel ? Kirigami.Units.gridUnit : 0))
    
    // Expanded controls layout
    ColumnLayout {
        visible: showExpandedControls
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing * 1.5
        
        // Header with entity info
        RowLayout {
            Layout.fillWidth: true
            
            Kirigami.Icon {
                source: getIconName()
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: displayName
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                PlasmaComponents3.Label {
                    text: entityState ? ("State: " + entityState.state) : "State: Unavailable"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                    Layout.fillWidth: true
                }
            }
            
            // Toggle button
            PlasmaComponents3.Button {
                text: isOn ? "Turn Off" : "Turn On"
                onClicked: handleControlClick()
            }
        }
        
        // Advanced Light Controls (only for lights with advanced features)
        ColumnLayout {
            visible: hasAdvancedControls
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            
            // Brightness Control
            RowLayout {
                visible: supportsBrightness && isOn
                Layout.fillWidth: true
                
                Kirigami.Icon {
                    source: "brightness-low"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                
                PlasmaComponents3.Label {
                    text: "Brightness"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                }
                
                QQC2.Slider {
                    id: expandedBrightnessSlider
                    Layout.fillWidth: true
                    from: 1
                    to: 100
                    value: currentBrightness
                    stepSize: 1
                    
                    onMoved: {
                        var brightnessValue = Math.round(value * 255 / 100)
                        controlActivated(entityId, "turn_on", { brightness: brightnessValue })
                    }
                }
                
                PlasmaComponents3.Label {
                    text: currentBrightness + "%"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                }
            }
            
            // Color Temperature Control
            RowLayout {
                visible: supportsCct && isOn
                Layout.fillWidth: true
                
                Kirigami.Icon {
                    source: "weather-clear-night"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                
                PlasmaComponents3.Label {
                    text: "Color Temp"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                }
                
                QQC2.Slider {
                    id: expandedColorTempSlider
                    Layout.fillWidth: true
                    from: 153  // ~6500K (cool)
                    to: 500    // ~2000K (warm)
                    value: currentColorTemp
                    stepSize: 1
                    
                    onMoved: {
                        controlActivated(entityId, "turn_on", { color_temp: Math.round(value) })
                    }
                    
                    background: Rectangle {
                        x: expandedColorTempSlider.leftPadding
                        y: expandedColorTempSlider.topPadding + expandedColorTempSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 8
                        width: expandedColorTempSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#87CEEB" } // Cool blue
                            GradientStop { position: 1.0; color: "#FFA500" } // Warm orange
                        }
                        
                        border.color: Kirigami.Theme.separatorColor
                        border.width: 1
                    }
                }
                
                PlasmaComponents3.Label {
                    text: Math.round(1000000 / currentColorTemp) + "K"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                }
            }
            
            // RGB Color Control
            ColumnLayout {
                visible: supportsRgb && isOn
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents3.Label {
                    text: "RGB Colors"
                    font.bold: true
                }
                
                // Color preset buttons
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.largeSpacing
                    
                    Repeater {
                        model: [
                            { color: "#FF0000", name: "Red" },
                            { color: "#00FF00", name: "Green" },
                            { color: "#0000FF", name: "Blue" },
                            { color: "#FFFF00", name: "Yellow" },
                            { color: "#FF00FF", name: "Magenta" },
                            { color: "#00FFFF", name: "Cyan" },
                            { color: "#FFFFFF", name: "White" }
                        ]
                        
                        PlasmaComponents3.Button {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                            
                            background: Rectangle {
                                radius: Kirigami.Units.cornerRadius
                                color: modelData.color
                                border.color: Qt.rgba(currentRgbColor[0]/255, currentRgbColor[1]/255, currentRgbColor[2]/255, 1.0) === color ? 
                                             Kirigami.Theme.highlightColor : Kirigami.Theme.separatorColor
                                border.width: Qt.rgba(currentRgbColor[0]/255, currentRgbColor[1]/255, currentRgbColor[2]/255, 1.0) === color ? 3 : 1
                            }
                            
                            PlasmaComponents3.ToolTip {
                                text: modelData.name
                            }
                            
                            onClicked: {
                                var rgb = hexToRgb(modelData.color)
                                controlActivated(entityId, "turn_on", { rgb_color: [rgb.r, rgb.g, rgb.b] })
                            }
                        }
                    }
                }
                
                // Current color indicator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(currentRgbColor[0]/255, currentRgbColor[1]/255, currentRgbColor[2]/255, 1.0)
                    border.color: Kirigami.Theme.separatorColor
                    border.width: 1
                    
                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: "Current: RGB(" + currentRgbColor[0] + ", " + currentRgbColor[1] + ", " + currentRgbColor[2] + ")"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: (currentRgbColor[0] + currentRgbColor[1] + currentRgbColor[2]) > 384 ? "black" : "white"
                    }
                }
            }
            
            // XY Color Control (CIE 1931) with HUE Slider
            ColumnLayout {
                visible: supportsXy && isOn
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents3.Label {
                    text: "XY Color Space (CIE 1931)"
                    font.bold: true
                }
                
                // Hue Slider with color wheel visualization
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: "color-picker"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    
                    PlasmaComponents3.Label {
                        text: "Hue"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    }
                    
                    QQC2.Slider {
                        id: hueSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 360
                        value: currentHue
                        stepSize: 1
                        
                        onMoved: {
                            var xyColor = hueToXy(value, currentSaturation)
                            controlActivated(entityId, "turn_on", { xy_color: [xyColor.x, xyColor.y] })
                        }
                        
                        background: Rectangle {
                            x: hueSlider.leftPadding
                            y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 8
                            width: hueSlider.availableWidth
                            height: implicitHeight
                            radius: 4
                            
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.000; color: "#FF0000" } // Red (0°)
                                GradientStop { position: 0.167; color: "#FFFF00" } // Yellow (60°)
                                GradientStop { position: 0.333; color: "#00FF00" } // Green (120°)
                                GradientStop { position: 0.500; color: "#00FFFF" } // Cyan (180°)
                                GradientStop { position: 0.667; color: "#0000FF" } // Blue (240°)
                                GradientStop { position: 0.833; color: "#FF00FF" } // Magenta (300°)
                                GradientStop { position: 1.000; color: "#FF0000" } // Red (360°)
                            }
                            
                            border.color: Kirigami.Theme.separatorColor
                            border.width: 1
                        }
                    }
                    
                    PlasmaComponents3.Label {
                        text: Math.round(currentHue) + "°"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                    }
                }
                
                // Saturation Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: "adjusthsl"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    
                    PlasmaComponents3.Label {
                        text: "Saturation"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    }
                    
                    QQC2.Slider {
                        id: saturationSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        value: currentSaturation
                        stepSize: 0.01
                        
                        onMoved: {
                            var xyColor = hueToXy(currentHue, value)
                            controlActivated(entityId, "turn_on", { xy_color: [xyColor.x, xyColor.y] })
                        }
                        
                        background: Rectangle {
                            x: saturationSlider.leftPadding
                            y: saturationSlider.topPadding + saturationSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 8
                            width: saturationSlider.availableWidth
                            height: implicitHeight
                            radius: 4
                            
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#FFFFFF" } // White (no saturation)
                                GradientStop { position: 1.0; color: hueToRgbColor(currentHue) } // Full saturation at current hue
                            }
                            
                            border.color: Kirigami.Theme.separatorColor
                            border.width: 1
                        }
                    }
                    
                    PlasmaComponents3.Label {
                        text: Math.round(currentSaturation * 100) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                    }
                }
                
                // Color preset buttons for common colors in XY space
                GridLayout {
                    Layout.fillWidth: true
                    columns: 6
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.largeSpacing
                    
                    Repeater {
                        model: [
                            { xy: [0.7006, 0.2993], name: "Red", color: "#FF0000" },
                            { xy: [0.1724, 0.7468], name: "Green", color: "#00FF00" },
                            { xy: [0.1357, 0.0399], name: "Blue", color: "#0000FF" },
                            { xy: [0.4316, 0.5016], name: "Yellow", color: "#FFFF00" },
                            { xy: [0.3127, 0.3290], name: "White", color: "#FFFFFF" },
                            { xy: [0.1670, 0.0090], name: "Deep Blue", color: "#000080" }
                        ]
                        
                        PlasmaComponents3.Button {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                            
                            background: Rectangle {
                                radius: Kirigami.Units.cornerRadius
                                color: modelData.color
                                border.color: (Math.abs(currentXyColor[0] - modelData.xy[0]) < 0.01 && 
                                              Math.abs(currentXyColor[1] - modelData.xy[1]) < 0.01) ? 
                                             Kirigami.Theme.highlightColor : Kirigami.Theme.separatorColor
                                border.width: (Math.abs(currentXyColor[0] - modelData.xy[0]) < 0.01 && 
                                              Math.abs(currentXyColor[1] - modelData.xy[1]) < 0.01) ? 3 : 1
                            }
                            
                            PlasmaComponents3.ToolTip {
                                text: modelData.name + "\nXY: (" + modelData.xy[0].toFixed(4) + ", " + modelData.xy[1].toFixed(4) + ")"
                            }
                            
                            onClicked: {
                                controlActivated(entityId, "turn_on", { xy_color: modelData.xy })
                            }
                        }
                    }
                }
                
                // Current XY color indicator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1
                    radius: Kirigami.Units.cornerRadius
                    color: xyToRgbColor(currentXyColor[0], currentXyColor[1])
                    border.color: Kirigami.Theme.separatorColor
                    border.width: 1
                    
                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: "Current XY: (" + currentXyColor[0].toFixed(4) + ", " + currentXyColor[1].toFixed(4) + ")"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: {
                            // Calculate luminance to determine text color
                            var rgb = xyToRgb(currentXyColor[0], currentXyColor[1])
                            var luminance = (rgb.r + rgb.g + rgb.b) / 3
                            return luminance > 128 ? "black" : "white"
                        }
                    }
                }
            }
        }
        
        // Entity Information Section (previously shown in tooltips)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: entityInfoColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
            color: Kirigami.Theme.alternateBackgroundColor
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
            radius: Kirigami.Units.cornerRadius
            
            ColumnLayout {
                id: entityInfoColumn
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing * 1.5
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents3.Label {
                    text: "Entity Information"
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                // Entity ID
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Entity ID:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityId
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }
                }
                
                // Friendly Name (if different from display name)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.friendly_name && 
                            entityState.attributes.friendly_name !== displayName
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Friendly Name:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes ? (entityState.attributes.friendly_name || "") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
                
                // Current State
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "State:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState ? (entityState.state || "unknown") : "Unavailable"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                    }
                }
                
                // Brightness (for lights)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.brightness !== undefined
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Brightness:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.brightness ? 
                             (Math.round(entityState.attributes.brightness / 255 * 100) + "%") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // RGB Color (for lights)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.rgb_color
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "RGB Color:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.rgb_color ? 
                             entityState.attributes.rgb_color.join(", ") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // XY Color (for lights)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.xy_color
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "XY Color:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.xy_color ? 
                             ("(" + entityState.attributes.xy_color[0].toFixed(4) + ", " + entityState.attributes.xy_color[1].toFixed(4) + ")") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // Color Temperature (for lights)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.color_temp
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Color Temp:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.color_temp ? 
                             (Math.round(1000000 / entityState.attributes.color_temp) + "K") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // Supported Color Modes (for lights)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.supported_color_modes && isLight
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Supported:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.supported_color_modes ? 
                             entityState.attributes.supported_color_modes.join(", ") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
                
                // Temperature (for climate/weather entities)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.temperature !== undefined
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Temperature:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.temperature !== undefined ? 
                             (entityState.attributes.temperature + "°") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // Humidity (for climate/weather entities)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.humidity !== undefined
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Humidity:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.humidity !== undefined ? 
                             (entityState.attributes.humidity + "%") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
                
                // Battery Level (for battery-powered devices)
                RowLayout {
                    visible: entityState && entityState.attributes && entityState.attributes.battery_level !== undefined
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Battery:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: entityState && entityState.attributes && entityState.attributes.battery_level !== undefined ? 
                             (entityState.attributes.battery_level + "%") : ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        color: {
                            if (entityState && entityState.attributes && entityState.attributes.battery_level !== undefined) {
                                var batteryLevel = entityState.attributes.battery_level
                                if (batteryLevel < 20) return Kirigami.Theme.negativeTextColor
                                if (batteryLevel < 50) return Kirigami.Theme.neutralTextColor
                                return Kirigami.Theme.positiveTextColor
                            }
                            return Kirigami.Theme.textColor
                        }
                    }
                }
                
                // Last Updated
                RowLayout {
                    visible: entityState && entityState.last_updated
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents3.Label {
                        text: "Last Updated:"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }
                    PlasmaComponents3.Label {
                        text: {
                            if (entityState && entityState.last_updated) {
                                var lastUpdated = new Date(entityState.last_updated)
                                return lastUpdated.toLocaleTimeString()
                            }
                            return ""
                        }
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
    
    // Compact control layout
    ColumnLayout {
        visible: !showExpandedControls
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        
        // Main control button
        PlasmaComponents3.Button {
            id: controlButton
            Layout.preferredWidth: buttonSizePixels
            Layout.preferredHeight: buttonSizePixels
            Layout.alignment: Qt.AlignHCenter
            
            // Visual state based on entity state
            property color normalColor: Kirigami.Theme.buttonBackgroundColor
            property color activeColor: isOn ? (supportsRgb ? Qt.rgba(currentRgbColor[0]/255, currentRgbColor[1]/255, currentRgbColor[2]/255, 0.3) : Kirigami.Theme.positiveBackgroundColor) : normalColor
            
            background: Rectangle {
                radius: Kirigami.Units.cornerRadius
                color: controlButton.pressed ? Qt.darker(controlButton.activeColor, 1.1) :
                       controlButton.hovered ? Qt.lighter(controlButton.activeColor, 1.1) :
                       controlButton.activeColor
                
                border.color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.buttonFocusColor
                border.width: isOn ? 2 : 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                // Advanced controls indicator for lights
                Rectangle {
                    visible: hasAdvancedControls
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 2
                    width: 6
                    height: 6
                    radius: 3
                    color: Kirigami.Theme.disabledTextColor
                }
            }
            
            contentItem: RowLayout {
                spacing: 0
                
                Kirigami.Icon {
                    source: getIconName()
                    color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                // Loading indicator
                PlasmaComponents3.BusyIndicator {
                    visible: isLoadingState
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    Layout.alignment: Qt.AlignCenter
                }
            }
            
            // PlasmaComponents3.ToolTip {
            //     text: getTooltipText()
            // }
            
            onClicked: handleControlClick()
        }
        
        // Entity label
        PlasmaComponents3.Label {
            visible: showLabel
            text: displayName
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
    
    function getIconName() {
        if (iconName && iconName !== "home-assistant") {
            return iconName
        }
        
        // Auto-detect icon based on entity type and state
        var domain = entityId.split('.')[0]
        switch (domain) {
            case 'light':
                return isOn ? "lightbulb-on" : "lightbulb"
            case 'switch':
                return isOn ? "toggle-switch" : "toggle-switch-off"
            case 'fan':
                return isOn ? "weather-windy" : "fan"
            case 'automation':
                return isOn ? "playlist-play" : "playlist-remove"
            case 'climate':
                return "thermometer"
            case 'lock':
                return entityState && entityState.state === "locked" ? "lock" : "lock-open"
            case 'cover':
                return entityState && entityState.state === "open" ? "window-open" : "window-close"
            case 'input_boolean':
                return isOn ? "checkbox-marked" : "checkbox-blank-outline"
            default:
                return "home-assistant"
        }
    }
    
    function getTooltipText() {
        return ""
        var tooltip = displayName
        
        if (isLoadingState) {
            tooltip += "\nState: Loading..."
            return tooltip
        }
        
        if (!hasValidState) {
            tooltip += "\nState: Unavailable"
            tooltip += "\nClick to refresh"
            return tooltip
        }
        
        var stateText = entityState.state || "unknown"
        
        // Use friendly name if available
        if (entityState.attributes && entityState.attributes.friendly_name) {
            tooltip = entityState.attributes.friendly_name
        }
        
        tooltip += "\nState: " + stateText
        
        // Only show basic info in tooltip, since full details are in expanded view
        if (entityState.attributes) {
            // Show only the most relevant single piece of info
            if (entityState.attributes.brightness && isOn) {
                tooltip += "\nBrightness: " + Math.round(entityState.attributes.brightness / 255 * 100) + "%"
            } else if (entityState.attributes.temperature !== undefined) {
                tooltip += "\nTemperature: " + entityState.attributes.temperature + "°"
            } else if (entityState.attributes.battery_level !== undefined) {
                tooltip += "\nBattery: " + entityState.attributes.battery_level + "%"
            }
        }
        
        // Add instruction for expanded view
        if (showExpandedControls) {
            tooltip += "\n\nDetailed information shown below"
        } else {
            if (isLight && controlType === "light" && (supportsRgb || supportsCct || supportsBrightness)) {
                tooltip += "\n\nRight-click for advanced controls & details"
            } else {
                tooltip += "\n\nRight-click for detailed information"
            }
        }
        
        return tooltip
    }
    
    function handleControlClick() {
        switch (controlType) {
            case "toggle":
                controlActivated(entityId, "toggle", {})
                break
            case "switch":
                controlActivated(entityId, isOn ? "turn_off" : "turn_on", {})
                break
            case "light":
                // For lights, we could show a context menu or brightness slider
                controlActivated(entityId, "toggle", {})
                break
            case "status":
                // Status displays don't perform actions, just refresh state
                stateRequested(entityId)
                break
            default:
                controlActivated(entityId, "toggle", {})
                break
        }
        
        // Always try to refresh state after any action (or for status entities)
        if (controlType !== "status") {
            Qt.callLater(function() {
                stateRequested(entityId)
            })
        }
    }
    
    function hexToRgb(hex) {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    }
    
    // XY to RGB conversion using simplified sRGB primaries
    function xyToRgb(x, y) {
        // Calculate z coordinate
        var z = 1.0 - x - y;
        
        // Convert XYZ to sRGB using sRGB transformation matrix
        var Y = 1.0; // Assume maximum brightness for color calculation
        var X = (Y / y) * x;
        var Z = (Y / y) * z;
        
        // sRGB transformation matrix
        var r = X * 3.2406 + Y * -1.5372 + Z * -0.4986;
        var g = X * -0.9689 + Y * 1.8758 + Z * 0.0415;
        var b = X * 0.0557 + Y * -0.2040 + Z * 1.0570;
        
        // Apply gamma correction
        r = r > 0.0031308 ? 1.055 * Math.pow(r, 1.0 / 2.4) - 0.055 : 12.92 * r;
        g = g > 0.0031308 ? 1.055 * Math.pow(g, 1.0 / 2.4) - 0.055 : 12.92 * g;
        b = b > 0.0031308 ? 1.055 * Math.pow(b, 1.0 / 2.4) - 0.055 : 12.92 * b;
        
        // Clamp values to [0, 1] and convert to [0, 255]
        r = Math.max(0, Math.min(1, r)) * 255;
        g = Math.max(0, Math.min(1, g)) * 255;
        b = Math.max(0, Math.min(1, b)) * 255;
        
        return {
            r: Math.round(r),
            g: Math.round(g),
            b: Math.round(b)
        };
    }
    
    // XY to RGB color string
    function xyToRgbColor(x, y) {
        var rgb = xyToRgb(x, y);
        return Qt.rgba(rgb.r / 255, rgb.g / 255, rgb.b / 255, 1.0);
    }
    
    // Convert XY coordinates to HSV hue (0-360 degrees)
    function xyToHue(x, y) {
        var rgb = xyToRgb(x, y);
        var r = rgb.r / 255;
        var g = rgb.g / 255;
        var b = rgb.b / 255;
        
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var delta = max - min;
        
        if (delta === 0) return 0;
        
        var hue;
        if (max === r) {
            hue = ((g - b) / delta) % 6;
        } else if (max === g) {
            hue = (b - r) / delta + 2;
        } else {
            hue = (r - g) / delta + 4;
        }
        
        hue = hue * 60;
        if (hue < 0) hue += 360;
        
        return hue;
    }
    
    // Convert XY coordinates to HSV saturation (0-1)
    function xyToSaturation(x, y) {
        var rgb = xyToRgb(x, y);
        var r = rgb.r / 255;
        var g = rgb.g / 255;
        var b = rgb.b / 255;
        
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        
        if (max === 0) return 0;
        return (max - min) / max;
    }
    
    // Convert HSV hue and saturation to XY coordinates
    function hueToXy(hue, saturation) {
        // Convert HSV to RGB first
        var h = hue / 60;
        var s = saturation;
        var v = 1.0; // Maximum value for pure color
        
        var c = v * s;
        var x = c * (1 - Math.abs((h % 2) - 1));
        var m = v - c;
        
        var r, g, b;
        if (h >= 0 && h < 1) {
            r = c; g = x; b = 0;
        } else if (h >= 1 && h < 2) {
            r = x; g = c; b = 0;
        } else if (h >= 2 && h < 3) {
            r = 0; g = c; b = x;
        } else if (h >= 3 && h < 4) {
            r = 0; g = x; b = c;
        } else if (h >= 4 && h < 5) {
            r = x; g = 0; b = c;
        } else {
            r = c; g = 0; b = x;
        }
        
        r += m; g += m; b += m;
        
        // Convert RGB to XYZ
        // Apply inverse gamma correction
        r = r > 0.04045 ? Math.pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
        g = g > 0.04045 ? Math.pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
        b = b > 0.04045 ? Math.pow((b + 0.055) / 1.055, 2.4) : b / 12.92;
        
        // sRGB to XYZ transformation matrix
        var X = r * 0.4124 + g * 0.3576 + b * 0.1805;
        var Y = r * 0.2126 + g * 0.7152 + b * 0.0722;
        var Z = r * 0.0193 + g * 0.1192 + b * 0.9505;
        
        // Convert XYZ to xy
        var sum = X + Y + Z;
        if (sum === 0) {
            return { x: 0.3127, y: 0.3290 }; // D65 white point
        }
        
        var x_coord = X / sum;
        var y_coord = Y / sum;
        
        // Clamp to valid CIE 1931 color space bounds
        x_coord = Math.max(0, Math.min(1, x_coord));
        y_coord = Math.max(0, Math.min(1, y_coord));
        
        return { x: x_coord, y: y_coord };
    }
    
    // Convert hue to RGB color string for gradient display
    function hueToRgbColor(hue) {
        var h = hue / 60;
        var c = 1; // Full chroma
        var x = c * (1 - Math.abs((h % 2) - 1));
        
        var r, g, b;
        if (h >= 0 && h < 1) {
            r = c; g = x; b = 0;
        } else if (h >= 1 && h < 2) {
            r = x; g = c; b = 0;
        } else if (h >= 2 && h < 3) {
            r = 0; g = c; b = x;
        } else if (h >= 3 && h < 4) {
            r = 0; g = x; b = c;
        } else if (h >= 4 && h < 5) {
            r = x; g = 0; b = c;
        } else {
            r = c; g = 0; b = x;
        }
        
        return Qt.rgba(r, g, b, 1.0);
    }
}
