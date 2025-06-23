import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
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
    readonly property bool supportsBrightness: entityState && entityState.attributes && entityState.attributes.supported_color_modes && 
                                              (entityState.attributes.supported_color_modes.indexOf('brightness') !== -1 || 
                                               entityState.attributes.brightness !== undefined)
    readonly property int currentBrightness: entityState && entityState.attributes && entityState.attributes.brightness ? 
                                           Math.round(entityState.attributes.brightness / 255 * 100) : 0
    readonly property var currentRgbColor: entityState && entityState.attributes && entityState.attributes.rgb_color ? 
                                         entityState.attributes.rgb_color : [255, 255, 255]
    readonly property int currentColorTemp: entityState && entityState.attributes && entityState.attributes.color_temp ? 
                                          entityState.attributes.color_temp : 370
    
    signal controlActivated(string entityId, string action, var data)
    signal stateRequested(string entityId)
    
    readonly property int buttonSizePixels: {
        switch (buttonSize) {
            case "small": return Kirigami.Units.iconSizes.medium
            case "large": return Kirigami.Units.iconSizes.huge
            default: return Kirigami.Units.iconSizes.large
        }
    }
    
    readonly property bool hasAdvancedControls: isLight && controlType === "light" && (supportsRgb || supportsCct || supportsBrightness)
    
    width: buttonSizePixels + (showLabel ? Kirigami.Units.smallSpacing : 0)
    height: buttonSizePixels + (showLabel ? Kirigami.Units.gridUnit : 0)
    
    ColumnLayout {
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
            
            PlasmaComponents3.ToolTip {
                text: getTooltipText()
            }
            
            onClicked: handleControlClick()
            
            // Right-click to show advanced controls popup for lights
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    if (hasAdvancedControls) {
                        advancedControlsPopup.open()
                    }
                }
            }
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
    
    // Advanced Controls Popup
    QQC2.Popup {
        id: advancedControlsPopup
        parent: entityControl
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        
        width: Kirigami.Units.gridUnit * 16
        height: Kirigami.Units.gridUnit * 12
        
        x: (parent.width - width) / 2
        y: parent.height + Kirigami.Units.smallSpacing
        
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
            radius: Kirigami.Units.cornerRadius
            
            // Add a subtle shadow effect
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.1)
                border.width: 1
                radius: Kirigami.Units.cornerRadius + 1
            }
        }
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            
            // Popup Header
            RowLayout {
                Layout.fillWidth: true
                
                Kirigami.Icon {
                    source: getIconName()
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                }
                
                PlasmaComponents3.Label {
                    text: displayName
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                PlasmaComponents3.Button {
                    icon.name: "window-close"
                    flat: true
                    onClicked: advancedControlsPopup.close()
                }
            }
            
            // Brightness Control
            RowLayout {
                visible: supportsBrightness && isOn
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                
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
                    id: popupBrightnessSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    from: 1
                    to: 100
                    value: currentBrightness
                    stepSize: 1
                    
                    onMoved: {
                        var brightnessValue = Math.round(value * 255 / 100)
                        controlActivated(entityId, "turn_on", { brightness: brightnessValue })
                    }
                    
                    background: Rectangle {
                        x: popupBrightnessSlider.leftPadding
                        y: popupBrightnessSlider.topPadding + popupBrightnessSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 8
                        width: popupBrightnessSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.separatorColor
                        
                        Rectangle {
                            width: popupBrightnessSlider.visualPosition * parent.width
                            height: parent.height
                            color: Kirigami.Theme.highlightColor
                            radius: 4
                        }
                    }
                    
                    handle: Rectangle {
                        x: popupBrightnessSlider.leftPadding + popupBrightnessSlider.visualPosition * (popupBrightnessSlider.availableWidth - width)
                        y: popupBrightnessSlider.topPadding + popupBrightnessSlider.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: popupBrightnessSlider.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.1) : Kirigami.Theme.highlightColor
                        border.color: Kirigami.Theme.backgroundColor
                        border.width: 2
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
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                
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
                    id: popupColorTempSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    from: 153  // ~6500K (cool)
                    to: 500    // ~2000K (warm)
                    value: currentColorTemp
                    stepSize: 1
                    
                    onMoved: {
                        controlActivated(entityId, "turn_on", { color_temp: Math.round(value) })
                    }
                    
                    background: Rectangle {
                        x: popupColorTempSlider.leftPadding
                        y: popupColorTempSlider.topPadding + popupColorTempSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 8
                        width: popupColorTempSlider.availableWidth
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
                    
                    handle: Rectangle {
                        x: popupColorTempSlider.leftPadding + popupColorTempSlider.visualPosition * (popupColorTempSlider.availableWidth - width)
                        y: popupColorTempSlider.topPadding + popupColorTempSlider.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: popupColorTempSlider.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.1) : Kirigami.Theme.highlightColor
                        border.color: Kirigami.Theme.backgroundColor
                        border.width: 2
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
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "RGB Colors"
                    font.bold: true
                }
                
                // Color preset buttons
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    
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
        
        // Add additional info for specific entity types
        if (entityState.attributes) {
            if (entityState.attributes.brightness) {
                tooltip += "\nBrightness: " + Math.round(entityState.attributes.brightness / 255 * 100) + "%"
            }
            if (entityState.attributes.rgb_color) {
                tooltip += "\nRGB: " + entityState.attributes.rgb_color.join(", ")
            }
            if (entityState.attributes.color_temp) {
                tooltip += "\nColor Temp: " + Math.round(1000000 / entityState.attributes.color_temp) + "K"
            }
            if (entityState.attributes.supported_color_modes && isLight) {
                tooltip += "\nSupported: " + entityState.attributes.supported_color_modes.join(", ")
            }
            if (entityState.attributes.temperature) {
                tooltip += "\nTemperature: " + entityState.attributes.temperature + "°"
            }
            if (entityState.attributes.humidity) {
                tooltip += "\nHumidity: " + entityState.attributes.humidity + "%"
            }
            if (entityState.attributes.battery_level) {
                tooltip += "\nBattery: " + entityState.attributes.battery_level + "%"
            }
            // Add last updated time
            if (entityState.last_updated) {
                var lastUpdated = new Date(entityState.last_updated)
                tooltip += "\nLast updated: " + lastUpdated.toLocaleTimeString()
            }
        }
        
        // Add instruction for light controls
        if (isLight && controlType === "light" && (supportsRgb || supportsCct || supportsBrightness)) {
            tooltip += "\n\nRight-click for advanced controls"
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
}
