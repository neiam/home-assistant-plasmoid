import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

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
    
    signal controlActivated(string entityId, string action, var data)
    
    readonly property int buttonSizePixels: {
        switch (buttonSize) {
            case "small": return Kirigami.Units.iconSizes.medium
            case "large": return Kirigami.Units.iconSizes.huge
            default: return Kirigami.Units.iconSizes.large
        }
    }
    
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
            property color activeColor: isOn ? Kirigami.Theme.positiveBackgroundColor : normalColor
            
            background: Rectangle {
                radius: Kirigami.Units.cornerRadius
                color: controlButton.pressed ? Qt.darker(controlButton.activeColor, 1.1) :
                       controlButton.hovered ? Qt.lighter(controlButton.activeColor, 1.1) :
                       controlButton.activeColor
                
                border.color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.buttonFocusColor
                border.width: isOn ? 2 : 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
            
            contentItem: Kirigami.Icon {
                source: getIconName()
                color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            PlasmaComponents3.ToolTip {
                text: getTooltipText()
            }
            
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
        var stateText = entityState ? entityState.state : "unknown"
        var tooltip = displayName + "\nState: " + stateText
        
        if (entityState && entityState.attributes) {
            if (entityState.attributes.friendly_name) {
                tooltip = entityState.attributes.friendly_name + "\nState: " + stateText
            }
            
            // Add additional info for specific entity types
            if (entityState.attributes.brightness) {
                tooltip += "\nBrightness: " + Math.round(entityState.attributes.brightness / 255 * 100) + "%"
            }
            if (entityState.attributes.temperature) {
                tooltip += "\nTemperature: " + entityState.attributes.temperature + "°"
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
                // Status displays don't perform actions, just show state
                break
            default:
                controlActivated(entityId, "toggle", {})
                break
        }
    }
}
