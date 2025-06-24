import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    // Panel widget sizing - compact for panel mode
    Layout.minimumWidth: hasValidConfig && hasEntities ? 
                        (configuredEntities.length * (Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing)) + Kirigami.Units.smallSpacing :
                        Kirigami.Units.gridUnit * 3
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 2
    Layout.preferredWidth: hasValidConfig && hasEntities ? 
                          (configuredEntities.length * (Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing)) + Kirigami.Units.smallSpacing :
                          Kirigami.Units.gridUnit * 3
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 2
    
    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 8
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    property string homeAssistantUrl: plasmoid.configuration.homeAssistantUrl
    property string accessToken: plasmoid.configuration.accessToken
    property int updateInterval: plasmoid.configuration.updateInterval
    property string configuredEntitiesJson: plasmoid.configuration.configuredEntities
    property int maxEntitiesPerRow: plasmoid.configuration.maxEntitiesPerRow
    property bool showEntityLabels: plasmoid.configuration.showEntityLabels
    property string buttonSize: plasmoid.configuration.buttonSize
    
    property var configuredEntities: []
    property var entityStates: ({}) // Store entity states here
    property bool hasValidConfig: homeAssistantUrl && accessToken
    property bool hasEntities: configuredEntities.length > 0
    
    // For expanded popup with advanced controls
    property string expandedEntityId: ""
    property var expandedEntityData: null
    
    // Parse configured entities from JSON
    function parseConfiguredEntities() {
        try {
            var parsed = JSON.parse(configuredEntitiesJson || "[]")
            configuredEntities = parsed
        } catch (e) {
            console.log("Error parsing configured entities:", e)
            configuredEntities = []
        }
    }
    
    // Update entity states
    function updateEntityStates() {
        if (!hasValidConfig || !hasEntities) return
        
        for (var i = 0; i < configuredEntities.length; i++) {
            var entity = configuredEntities[i]
            homeAssistantAPI.getState(entity.entityId)
        }
    }
    
    onConfiguredEntitiesJsonChanged: parseConfiguredEntities()
    Component.onCompleted: parseConfiguredEntities()
    
    // Home Assistant API helper
    HomeAssistantAPI {
        id: homeAssistantAPI
        baseUrl: root.homeAssistantUrl
        accessToken: root.accessToken
        
        onStateChanged: function(entityId, state) {
            // Store the state in our central state store
            var newStates = root.entityStates
            newStates[entityId] = state
            root.entityStates = newStates
            
            // Trigger a change notification
            root.entityStatesChanged()
        }
        
        onError: function(message) {
            console.log("Home Assistant API Error:", message)
        }
    }
    
    // Update timer
    Timer {
        id: updateTimer
        interval: root.updateInterval * 1000
        running: root.hasValidConfig && root.hasEntities
        repeat: true
        onTriggered: updateEntityStates()
    }
    
    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        
        // Advanced lighting controls popup for the selected entity
        Rectangle {
            visible: expandedEntityId !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
            radius: Kirigami.Units.cornerRadius
            
            EntityControl {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing * 2
                
                entityId: root.expandedEntityId
                displayName: root.expandedEntityData ? (root.expandedEntityData.displayName || root.expandedEntityData.entityId) : ""
                controlType: root.expandedEntityData ? (root.expandedEntityData.controlType || "toggle") : "toggle"
                iconName: root.expandedEntityData ? (root.expandedEntityData.icon || "home-assistant") : "home-assistant"
                showLabel: true
                buttonSize: "large"
                entityState: root.entityStates[root.expandedEntityId] || null
                showExpandedControls: true
                
                onControlActivated: function(entityId, action, data) {
                    switch (action) {
                        case "toggle":
                            homeAssistantAPI.toggleEntity(entityId)
                            break
                        case "turn_on":
                            homeAssistantAPI.turnOn(entityId, data)
                            break
                        case "turn_off":
                            homeAssistantAPI.turnOff(entityId)
                            break
                    }
                    
                    // Update state after a short delay
                    Qt.callLater(function() {
                        homeAssistantAPI.getState(entityId)
                    })
                }
                
                onStateRequested: function(entityId) {
                    if (root.hasValidConfig) {
                        homeAssistantAPI.getState(entityId)
                    }
                }
            }
            
            // Close button
            PlasmaComponents3.Button {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Kirigami.Units.smallSpacing
                icon.name: "window-close"
                flat: true
                onClicked: {
                    root.expandedEntityId = ""
                    root.expandedEntityData = null
                }
            }
        }
        
        // Regular grid view when no specific entity is expanded
        Item {
            visible: expandedEntityId === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Title
            PlasmaComponents3.Label {
                id: titleLabel
                text: i18n("Home Assistant Control")
                font.bold: true
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !hasValidConfig || !hasEntities
            }
            
            // Configuration prompt
            ColumnLayout {
                visible: !hasValidConfig
                anchors.fill: parent
                anchors.topMargin: titleLabel.height + Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents3.Label {
                    text: i18n("Configure the widget to connect to your Home Assistant instance")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                
                PlasmaComponents3.Button {
                    text: i18n("Configure Connection")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: plasmoid.internalAction("configure").trigger()
                }
            }
            
            // Entity setup prompt
            ColumnLayout {
                visible: hasValidConfig && !hasEntities
                anchors.fill: parent
                anchors.topMargin: titleLabel.height + Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents3.Label {
                    text: i18n("Configure entities to control them from the widget")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                
                PlasmaComponents3.Button {
                    text: i18n("Configure Entities")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: plasmoid.internalAction("configure").trigger()
                }
            }
            
            // Entity controls grid
            QQC2.ScrollView {
                id: scrollView
                visible: hasValidConfig && hasEntities
                anchors.fill: parent
                
                GridLayout {
                    id: entityGrid
                    columns: root.maxEntitiesPerRow
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing
                    
                    Repeater {
                        model: root.configuredEntities
                        
                        EntityControl {
                            entityId: modelData.entityId || ""
                            displayName: modelData.displayName || modelData.entityId || ""
                            controlType: modelData.controlType || "toggle"
                            iconName: modelData.icon || "home-assistant"
                            showLabel: root.showEntityLabels
                            buttonSize: root.buttonSize
                            entityState: root.entityStates[entityId] || null
                            
                            onControlActivated: function(entityId, action, data) {
                                switch (action) {
                                    case "toggle":
                                        homeAssistantAPI.toggleEntity(entityId)
                                        break
                                    case "turn_on":
                                        homeAssistantAPI.turnOn(entityId, data)
                                        break
                                    case "turn_off":
                                        homeAssistantAPI.turnOff(entityId)
                                        break
                                }
                                
                                // Update state after a short delay
                                Qt.callLater(function() {
                                    homeAssistantAPI.getState(entityId)
                                })
                            }
                            
                            onStateRequested: function(entityId) {
                                if (root.hasValidConfig) {
                                    homeAssistantAPI.getState(entityId)
                                }
                            }
                            
                            Component.onCompleted: {
                                if (root.hasValidConfig) {
                                    homeAssistantAPI.getState(entityId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper functions for panel buttons
    function getEntityIconName(entityId, iconName, entityState, isOn) {
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
    
    function getEntityTooltipText(displayName, entityState, isLight, controlType, hasAdvancedControls) {
        var tooltip = displayName
        
        if (!entityState) {
            tooltip += "\nState: Unavailable"
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
            if (entityState.attributes.temperature) {
                tooltip += "\nTemperature: " + entityState.attributes.temperature + "°"
            }
            if (entityState.attributes.humidity) {
                tooltip += "\nHumidity: " + entityState.attributes.humidity + "%"
            }
            if (entityState.attributes.battery_level) {
                tooltip += "\nBattery: " + entityState.attributes.battery_level + "%"
            }
        }
        
        // Add instruction for advanced controls
        if (hasAdvancedControls) {
            tooltip += "\n\nRight-click for advanced controls"
        } else {
            tooltip += "\n\nRight-click for details"
        }
        
        return tooltip
    }
    
    function handlePanelEntityClick(entityId, controlType, isOn) {
        switch (controlType) {
            case "toggle":
                homeAssistantAPI.toggleEntity(entityId)
                break
            case "switch":
                homeAssistantAPI.callService(isOn ? "turn_off" : "turn_on", entityId)
                break
            case "light":
                homeAssistantAPI.toggleEntity(entityId)
                break
            case "status":
                // Status displays don't perform actions, just refresh state
                homeAssistantAPI.getState(entityId)
                return
            default:
                homeAssistantAPI.toggleEntity(entityId)
                break
        }
        
        // Always try to refresh state after any action
        Qt.callLater(function() {
            homeAssistantAPI.getState(entityId)
        })
    }
    
    compactRepresentation: Item {
        anchors.fill: parent
        
        // Configuration prompt when not configured
        Rectangle {
            visible: !hasValidConfig || !hasEntities
            anchors.fill: parent
            color: "transparent"
            border.color: Kirigami.Theme.separatorColor
            border.width: 1
            radius: Kirigami.Units.cornerRadius
            
            RowLayout {
                anchors.centerIn: parent
                anchors.margins: Kirigami.Units.smallSpacing
                
                Kirigami.Icon {
                    source: "home-assistant"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    color: Kirigami.Theme.disabledTextColor
                }
                
                PlasmaComponents3.Label {
                    text: i18n("Setup")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                }
            }
            
            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: i18n("Home Assistant Control")
                subText: !hasValidConfig ? i18n("Click to configure connection") : i18n("Click to configure entities")
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: plasmoid.internalAction("configure").trigger()
            }
        }
        
        // Panel entity controls when configured
        RowLayout {
            visible: hasValidConfig && hasEntities
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            
            Repeater {
                model: root.configuredEntities
                
                PlasmaComponents3.Button {
                    id: panelButton
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    
                    property string entityId: modelData.entityId || ""
                    property string displayName: modelData.displayName || modelData.entityId || ""
                    property string controlType: modelData.controlType || "toggle"
                    property string iconName: modelData.icon || "home-assistant"
                    property var entityState: root.entityStates[entityId] || null
                    property bool isOn: entityState ? (entityState.state === "on" || entityState.state === "home" || entityState.state === "open") : false
                    property bool isLight: entityId.split('.')[0] === 'light'
                    property bool hasAdvancedControls: isLight && controlType === "light" &&
                                                     entityState && entityState.attributes && entityState.attributes.supported_color_modes &&
                                                     (entityState.attributes.supported_color_modes.indexOf('rgb') !== -1 ||
                                                      entityState.attributes.supported_color_modes.indexOf('color_temp') !== -1 ||
                                                      entityState.attributes.supported_color_modes.indexOf('brightness') !== -1)
                    property var currentRgbColor: entityState && entityState.attributes && entityState.attributes.rgb_color ? 
                                                entityState.attributes.rgb_color : [255, 255, 255]
                    
                    // Visual state based on entity state
                    property color normalColor: Kirigami.Theme.buttonBackgroundColor
                    property color activeColor: isOn ? 
                        (isLight && entityState && entityState.attributes && entityState.attributes.rgb_color ? 
                         Qt.rgba(currentRgbColor[0]/255, currentRgbColor[1]/255, currentRgbColor[2]/255, 0.3) : 
                         Kirigami.Theme.positiveBackgroundColor) : normalColor
                    
                    background: Rectangle {
                        radius: Kirigami.Units.cornerRadius
                        color: panelButton.pressed ? Qt.darker(panelButton.activeColor, 1.1) :
                               panelButton.hovered ? Qt.lighter(panelButton.activeColor, 1.1) :
                               panelButton.activeColor
                        
                        border.color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.buttonFocusColor
                        border.width: isOn ? 2 : 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        // Advanced controls indicator for lights
                        Rectangle {
                            visible: hasAdvancedControls
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 1
                            width: 4
                            height: 4
                            radius: 2
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                    
                    contentItem: Kirigami.Icon {
                        source: getEntityIconName(entityId, iconName, entityState, isOn)
                        color: isOn ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    PlasmaComponents3.ToolTip {
                        text: getEntityTooltipText(displayName, entityState, isLight, controlType, hasAdvancedControls)
                    }
                    
                    onClicked: {
                        handlePanelEntityClick(entityId, controlType, isOn)
                    }
                    
                    // Right-click to show advanced controls popup for lights or expanded view
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            if (hasAdvancedControls) {
                                // Store the current entity for the popup
                                root.expandedEntityId = entityId
                                root.expandedEntityData = modelData
                                root.expanded = true
                            } else {
                                // For non-light entities, show expanded view
                                root.expanded = !root.expanded
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        if (root.hasValidConfig && entityId) {
                            homeAssistantAPI.getState(entityId)
                        }
                    }
                }
            }
        }
    }
}
