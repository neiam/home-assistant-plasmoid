import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ComboBox {
    id: entityBrowser
    
    property alias homeAssistantAPI: homeAssistantAPI
    property string selectedEntityId: ""
    property string selectedEntityName: ""
    property var selectedEntity: null
    property var filteredDomains: [] // Empty = all domains, or ["light", "switch"] etc.
    property string searchQuery: ""
    
    signal entitySelected(var entity)
    
    editable: true
    textRole: "display_text"
    valueRole: "entity_id"
    
    // Custom model for entities
    model: ListModel {
        id: entityModel
    }
    
    onEditTextChanged: {
        searchQuery = editText
        filterEntities()
    }
    
    onActivated: function(index) {
        if (index >= 0 && index < entityModel.count) {
            var entity = entityModel.get(index)
            selectedEntityId = entity.entity_id
            selectedEntityName = entity.friendly_name
            selectedEntity = entity
            entitySelected(entity)
        }
    }
    
    // Custom popup for better entity browsing
    popup: QQC2.Popup {
        id: entityPopup
        y: entityBrowser.height
        width: Math.max(entityBrowser.width, Kirigami.Units.gridUnit * 20)
        height: Math.min(contentItem.implicitHeight, Kirigami.Units.gridUnit * 15)
        
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            
            // Domain filter
            RowLayout {
                Layout.fillWidth: true
                
                QQC2.Label {
                    text: i18n("Filter:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                
                Repeater {
                    model: ["all", "light", "switch", "fan", "automation", "climate", "cover", "lock"]
                    
                    QQC2.Button {
                        text: modelData === "all" ? i18n("All") : modelData
                        checkable: true
                        checked: filteredDomains.length === 0 && modelData === "all" || 
                                filteredDomains.indexOf(modelData) !== -1
                        
                        onClicked: {
                            if (modelData === "all") {
                                filteredDomains = []
                            } else {
                                var domains = filteredDomains.slice() // copy array
                                var index = domains.indexOf(modelData)
                                if (index !== -1) {
                                    domains.splice(index, 1)
                                } else {
                                    domains.push(modelData)
                                }
                                filteredDomains = domains
                            }
                            filterEntities()
                        }
                        
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                    }
                }
            }
            
            Kirigami.Separator {
                Layout.fillWidth: true
            }
            
            // Entity list
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ListView {
                    id: entityListView
                    model: entityModel
                    
                    delegate: QQC2.ItemDelegate {
                        width: entityListView.width
                        
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            
                            // Domain badge
                            Rectangle {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                                radius: Kirigami.Units.cornerRadius
                                color: getDomainColor(model.domain)
                                
                                QQC2.Label {
                                    anchors.centerIn: parent
                                    text: model.domain
                                    color: "white"
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.bold: true
                                }
                            }
                            
                            // Entity icon
                            Kirigami.Icon {
                                source: getEntityIcon(model)
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            
                            // Entity info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                
                                QQC2.Label {
                                    text: model.friendly_name
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                
                                QQC2.Label {
                                    text: model.entity_id + " • " + model.state
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                            
                            // State indicator
                            Rectangle {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 0.5
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                                radius: width / 2
                                color: getStateColor(model.state)
                            }
                        }
                        
                        onClicked: {
                            entityBrowser.currentIndex = index
                            selectedEntityId = model.entity_id
                            selectedEntityName = model.friendly_name
                            selectedEntity = model
                            entitySelected(model)
                            entityPopup.close()
                        }
                    }
                }
            }
            
            // Status bar
            RowLayout {
                Layout.fillWidth: true
                
                QQC2.Label {
                    text: i18n("%1 entities found", entityModel.count)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                }
                
                Item { Layout.fillWidth: true }
                
                QQC2.BusyIndicator {
                    visible: homeAssistantAPI.isLoadingEntities
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
            }
        }
    }
    
    // Home Assistant API instance
    HomeAssistantAPI {
        id: homeAssistantAPI
        
        onEntitiesLoaded: function(entities) {
            filterEntities()
        }
        
        onError: function(message) {
            console.log("Entity browser API error:", message)
        }
    }
    
    function loadEntities() {
        if (homeAssistantAPI.baseUrl && homeAssistantAPI.accessToken) {
            homeAssistantAPI.getAllEntities()
        }
    }
    
    function filterEntities() {
        entityModel.clear()
        
        if (!homeAssistantAPI.allEntities || homeAssistantAPI.allEntities.length === 0) {
            return
        }
        
        var searchResults = homeAssistantAPI.searchEntities(searchQuery, filteredDomains)
        
        // Limit results to prevent UI lag
        var maxResults = 100
        for (var i = 0; i < Math.min(searchResults.length, maxResults); i++) {
            var entity = searchResults[i]
            entityModel.append({
                entity_id: entity.entity_id,
                friendly_name: entity.friendly_name,
                domain: entity.domain,
                state: entity.state,
                icon: entity.icon,
                device_class: entity.device_class,
                unit_of_measurement: entity.unit_of_measurement,
                display_text: entity.friendly_name + " (" + entity.entity_id + ")"
            })
        }
    }
    
    function getDomainColor(domain) {
        switch (domain) {
            case "light": return "#FFA726"
            case "switch": return "#42A5F5"
            case "fan": return "#66BB6A"
            case "automation": return "#AB47BC"
            case "climate": return "#EF5350"
            case "cover": return "#26A69A"
            case "lock": return "#8D6E63"
            case "sensor": return "#78909C"
            case "binary_sensor": return "#90A4AE"
            default: return "#9E9E9E"
        }
    }
    
    function getEntityIcon(entity) {
        if (entity.icon) {
            return entity.icon.replace("mdi:", "")
        }
        
        switch (entity.domain) {
            case "light": return entity.state === "on" ? "lightbulb-on" : "lightbulb"
            case "switch": return entity.state === "on" ? "toggle-switch" : "toggle-switch-off"
            case "fan": return "fan"
            case "automation": return "playlist-play"
            case "climate": return "thermometer"
            case "cover": return "window-close"
            case "lock": return entity.state === "locked" ? "lock" : "lock-open"
            case "sensor": return "gauge"
            case "binary_sensor": return "checkbox-marked-circle"
            default: return "home-assistant"
        }
    }
    
    function getStateColor(state) {
        switch (state) {
            case "on":
            case "open":
            case "home":
            case "unlocked":
                return Kirigami.Theme.positiveTextColor
            case "off":
            case "closed":
            case "away":
            case "locked":
                return Kirigami.Theme.disabledTextColor
            case "unavailable":
            case "unknown":
                return Kirigami.Theme.negativeTextColor
            default:
                return Kirigami.Theme.textColor
        }
    }
    
    Component.onCompleted: {
        // Auto-load entities when component is ready
        Qt.callLater(loadEntities)
    }
}
