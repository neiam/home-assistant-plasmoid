import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    Layout.minimumWidth: Kirigami.Units.gridUnit * 8
    Layout.minimumHeight: Kirigami.Units.gridUnit * 4
    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
    Layout.preferredHeight: Kirigami.Units.gridUnit * 6
    
    switchWidth: Kirigami.Units.gridUnit * 5
    switchHeight: Kirigami.Units.gridUnit * 5
    
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
        
        // Title
        PlasmaComponents3.Label {
            text: i18n("Home Assistant Control")
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            visible: !hasValidConfig || !hasEntities
        }
        
        // Configuration prompt
        ColumnLayout {
            visible: !hasValidConfig
            Layout.fillWidth: true
            Layout.fillHeight: true
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
            Layout.fillWidth: true
            Layout.fillHeight: true
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            
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
                                isLoadingState = true
                                homeAssistantAPI.getState(entityId, function(success, state) {
                                    isLoadingState = false
                                    if (!success) {
                                        console.log("Failed to refresh state for:", entityId)
                                    }
                                })
                            }
                        }
                        
                        Component.onCompleted: {
                            if (root.hasValidConfig) {
                                isLoadingState = true
                                homeAssistantAPI.getState(entityId, function(success, state) {
                                    isLoadingState = false
                                    if (!success) {
                                        console.log("Failed to get initial state for:", entityId)
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    compactRepresentation: Kirigami.Icon {
        source: plasmoid.icon
        anchors.fill: parent
        
        // Show number of configured entities as badge
        Rectangle {
            visible: root.hasEntities
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: Math.max(Kirigami.Units.gridUnit * 0.8, badgeText.implicitWidth + 4)
            height: Kirigami.Units.gridUnit * 0.8
            radius: height / 2
            color: Kirigami.Theme.highlightColor
            
            PlasmaComponents3.Label {
                id: badgeText
                anchors.centerIn: parent
                text: root.configuredEntities.length
                color: Kirigami.Theme.highlightedTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
            }
        }
        
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18n("Home Assistant Control")
            subText: root.hasEntities ? 
                     i18n("%1 entities configured", root.configuredEntities.length) :
                     i18n("Click to configure")
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.hasValidConfig && root.hasEntities) {
                    root.expanded = !root.expanded
                    if (root.expanded) {
                        updateEntityStates()
                    }
                } else {
                    plasmoid.internalAction("configure").trigger()
                }
            }
        }
    }
}
