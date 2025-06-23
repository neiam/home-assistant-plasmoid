import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: configEntities
    
    property alias cfg_configuredEntities: configuredEntitiesField.text
    property alias cfg_maxEntitiesPerRow: maxEntitiesPerRowSpinBox.value
    property alias cfg_showEntityLabels: showEntityLabelsCheckBox.checked
    property alias cfg_buttonSize: buttonSizeComboBox.currentValue
    
    // These should be aliases to the actual config values
    property alias cfg_homeAssistantUrl: dummyUrlField.text
    property alias cfg_accessToken: dummyTokenField.text
    
    property var entitiesList: []
    
    // Hidden fields to access the config values
    QQC2.TextField {
        id: dummyUrlField
        visible: false
    }
    
    QQC2.TextField {
        id: dummyTokenField
        visible: false
    }
    
    function parseEntities() {
        try {
            var parsed = JSON.parse(cfg_configuredEntities || "[]")
            entitiesList = parsed
            entityListModel.clear()
            for (var i = 0; i < entitiesList.length; i++) {
                entityListModel.append(entitiesList[i])
            }
        } catch (e) {
            console.log("Error parsing entities:", e)
            entitiesList = []
        }
    }
    
    function saveEntities() {
        entitiesList = []
        for (var i = 0; i < entityListModel.count; i++) {
            entitiesList.push(entityListModel.get(i))
        }
        cfg_configuredEntities = JSON.stringify(entitiesList)
    }
    
    function addEntity() {
        var entityId = entityBrowser.selectedEntityId || newEntityIdField.text.trim()
        var entityName = entityBrowser.selectedEntityName || newEntityNameField.text.trim()
        
        if (!entityId) {
            return
        }
        
        var newEntity = {
            entityId: entityId,
            displayName: entityName || entityId,
            controlType: newEntityTypeComboBox.currentValue,
            icon: newEntityIconField.text.trim() || getAutoIcon(entityId)
        }
        
        // Check if entity already exists
        for (var i = 0; i < entityListModel.count; i++) {
            if (entityListModel.get(i).entityId === entityId) {
                // Update existing entity
                entityListModel.setProperty(i, "displayName", newEntity.displayName)
                entityListModel.setProperty(i, "controlType", newEntity.controlType)
                entityListModel.setProperty(i, "icon", newEntity.icon)
                saveEntities()
                clearAddForm()
                return
            }
        }
        
        // Add new entity
        entityListModel.append(newEntity)
        saveEntities()
        clearAddForm()
    }
    
    function clearAddForm() {
        entityBrowser.editText = ""
        entityBrowser.selectedEntityId = ""
        entityBrowser.selectedEntityName = ""
        newEntityIdField.text = ""
        newEntityNameField.text = ""
        newEntityIconField.text = ""
        newEntityTypeComboBox.currentIndex = 0
    }
    
    function removeEntity(index) {
        entityListModel.remove(index)
        saveEntities()
    }
    
    function getAutoIcon(entityId) {
        var domain = entityId.split('.')[0]
        switch (domain) {
            case 'light': return 'lightbulb'
            case 'switch': return 'toggle-switch'
            case 'fan': return 'fan'
            case 'automation': return 'playlist-play'
            case 'climate': return 'thermometer'
            case 'cover': return 'window-close'
            case 'lock': return 'lock'
            default: return 'home-assistant'
        }
    }
    
    function updateEntityBrowser() {
        entityBrowser.homeAssistantAPI.baseUrl = cfg_homeAssistantUrl
        entityBrowser.homeAssistantAPI.accessToken = cfg_accessToken
        
        if (cfg_homeAssistantUrl && cfg_accessToken) {
            Qt.callLater(function() {
                entityBrowser.loadEntities()
            })
        }
    }
    
    Component.onCompleted: {
        parseEntities()
        // Update the entity browser when the component is loaded
        Qt.callLater(updateEntityBrowser)
    }
    
    // Watch for changes in the config values
    onCfg_homeAssistantUrlChanged: updateEntityBrowser()
    onCfg_accessTokenChanged: updateEntityBrowser()
    
    // Icon picker dialog
    IconPicker {
        id: iconPicker
        parent: configEntities
        
        onIconSelected: function(iconName) {
            newEntityIconField.text = iconName
        }
    }
    
    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        
        // Connection status
        RowLayout {
            Layout.fillWidth: true
            
            Kirigami.Icon {
                source: connectionStatus.connected ? "network-connect" : "network-disconnect"
                color: connectionStatus.connected ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            
            QQC2.Label {
                id: connectionStatus
                property bool connected: cfg_homeAssistantUrl && cfg_accessToken
                text: connected ? i18n("Connected to Home Assistant") : i18n("Configure connection in General tab first")
                color: connected ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            
            Item { Layout.fillWidth: true }
            
            QQC2.Button {
                text: i18n("Refresh Entities")
                icon.name: "view-refresh"
                enabled: connectionStatus.connected
                onClicked: entityBrowser.loadEntities()
            }
        }
        
        Kirigami.FormLayout {
            
            QQC2.SpinBox {
                id: maxEntitiesPerRowSpinBox
                Kirigami.FormData.label: i18n("Entities per row:")
                from: 1
                to: 6
                value: 3
            }
            
            QQC2.CheckBox {
                id: showEntityLabelsCheckBox
                Kirigami.FormData.label: i18n("Show entity labels:")
                checked: true
            }
            
            QQC2.ComboBox {
                id: buttonSizeComboBox
                Kirigami.FormData.label: i18n("Button size:")
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: i18n("Small"), value: "small" },
                    { text: i18n("Medium"), value: "medium" },
                    { text: i18n("Large"), value: "large" }
                ]
                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === cfg_buttonSize) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }
        }
        
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        
        // Add new entity section
        QQC2.GroupBox {
            title: i18n("Add Entity")
            Layout.fillWidth: true
            
            enabled: connectionStatus.connected
            
            Kirigami.FormLayout {
                
                EntityBrowser {
                    id: entityBrowser
                    Kirigami.FormData.label: i18n("Browse Entities:")
                    Layout.fillWidth: true
                    
                    onEntitySelected: function(entity) {
                        newEntityNameField.text = entity.friendly_name
                        newEntityIconField.text = entity.icon ? entity.icon.replace("mdi:", "") : ""
                        
                        // Auto-select appropriate control type
                        var controlType = "toggle"
                        switch (entity.domain) {
                            case "light":
                                controlType = "light"
                                break
                            case "switch":
                            case "fan":
                                controlType = "switch"
                                break
                            case "sensor":
                            case "binary_sensor":
                            case "climate":
                                controlType = "status"
                                break
                        }
                        
                        for (var i = 0; i < newEntityTypeComboBox.model.length; i++) {
                            if (newEntityTypeComboBox.model[i].value === controlType) {
                                newEntityTypeComboBox.currentIndex = i
                                break
                            }
                        }
                    }
                }
                
                QQC2.Label {
                    Kirigami.FormData.label: i18n("OR Manual Entry:")
                    text: i18n("If entity browser doesn't work, enter manually:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                }
                
                QQC2.TextField {
                    id: newEntityIdField
                    Kirigami.FormData.label: i18n("Entity ID:")
                    placeholderText: i18n("e.g., light.living_room")
                    
                    onTextChanged: {
                        if (text.trim()) {
                            entityBrowser.editText = ""
                            entityBrowser.selectedEntityId = text.trim()
                        }
                    }
                }
                
                QQC2.TextField {
                    id: newEntityNameField
                    Kirigami.FormData.label: i18n("Display Name:")
                    placeholderText: i18n("e.g., Living Room Light")
                }
                
                QQC2.ComboBox {
                    id: newEntityTypeComboBox
                    Kirigami.FormData.label: i18n("Control Type:")
                    textRole: "text"
                    valueRole: "value"
                    model: [
                        { text: i18n("Toggle Button"), value: "toggle" },
                        { text: i18n("Switch"), value: "switch" },
                        { text: i18n("Light Control"), value: "light" },
                        { text: i18n("Status Display"), value: "status" }
                    ]
                }
                
                QQC2.TextField {
                    id: newEntityIconField
                    Kirigami.FormData.label: i18n("Icon:")
                    placeholderText: i18n("e.g., lightbulb, power-socket")
                }
                
                RowLayout {
                    Kirigami.FormData.label: i18n("Icon Picker:")
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Button {
                        text: i18n("Browse Icons...")
                        icon.name: "preferences-desktop-icon-theme"
                        onClicked: iconPicker.open()
                    }
                    
                    Kirigami.Icon {
                        source: newEntityIconField.text || getAutoIcon(entityBrowser.selectedEntityId || newEntityIdField.text.trim())
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Kirigami.Theme.separatorColor
                            border.width: 1
                            radius: Kirigami.Units.cornerRadius
                        }
                        
                        PlasmaCore.ToolTipArea {
                            anchors.fill: parent
                            mainText: i18n("Current Icon")
                            subText: newEntityIconField.text || i18n("Auto-detected")
                        }
                    }
                    
                    QQC2.Button {
                        text: i18n("Reset")
                        icon.name: "edit-clear"
                        enabled: newEntityIconField.text.trim().length > 0
                        onClicked: newEntityIconField.text = ""
                        
                        QQC2.ToolTip.text: i18n("Clear custom icon and use auto-detected icon")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 1000
                    }
                }
                
                // PREVIEW SECTION
                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: previewSection.visible
                }
                
                ColumnLayout {
                    id: previewSection
                    visible: entityBrowser.selectedEntityId || newEntityIdField.text.trim()
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Label {
                        text: i18n("Preview:")
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: previewControl.height + Kirigami.Units.largeSpacing * 2
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.separatorColor
                        border.width: 1
                        radius: Kirigami.Units.cornerRadius
                        
                        EntityControl {
                            id: previewControl
                            anchors.centerIn: parent
                            
                            entityId: entityBrowser.selectedEntityId || newEntityIdField.text.trim()
                            displayName: newEntityNameField.text.trim() || 
                                       entityBrowser.selectedEntityName || 
                                       (entityBrowser.selectedEntityId || newEntityIdField.text.trim())
                            controlType: newEntityTypeComboBox.currentValue
                            iconName: newEntityIconField.text.trim() || getAutoIcon(entityBrowser.selectedEntityId || newEntityIdField.text.trim())
                            showLabel: showEntityLabelsCheckBox.checked
                            buttonSize: buttonSizeComboBox.currentValue
                            
                            // Use live entity state from browser if available
                            entityState: entityBrowser.selectedEntity || null
                            
                            onControlActivated: function(entityId, action, data) {
                                // Don't actually control entities in preview mode
                                previewFeedback.text = i18n("Preview: Would %1 %2", action, entityId)
                                previewFeedback.visible = true
                                previewFeedbackTimer.restart()
                            }
                        }
                    }
                    
                    QQC2.Label {
                        id: previewFeedback
                        visible: false
                        text: ""
                        color: Kirigami.Theme.neutralTextColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        
                        Timer {
                            id: previewFeedbackTimer
                            interval: 2000
                            onTriggered: previewFeedback.visible = false
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        
                        QQC2.Label {
                            text: i18n("Settings Preview:")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 0.4
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.4
                            radius: width / 2
                            color: showEntityLabelsCheckBox.checked ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                        }
                        
                        QQC2.Label {
                            text: i18n("Labels")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 0.4
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.4
                            radius: width / 2
                            color: getSizeColor(buttonSizeComboBox.currentValue)
                        }
                        
                        QQC2.Label {
                            text: buttonSizeComboBox.currentValue
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 0.4
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.4
                            radius: width / 2
                            color: getControlTypeColor(newEntityTypeComboBox.currentValue)
                        }
                        
                        QQC2.Label {
                            text: newEntityTypeComboBox.currentValue
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
                
                QQC2.Button {
                    text: i18n("Add Entity")
                    icon.name: "list-add"
                    enabled: entityBrowser.selectedEntityId || newEntityIdField.text.trim()
                    onClicked: addEntity()
                }
            }
        }
        
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        
        // Configured entities list
        QQC2.GroupBox {
            title: i18n("Configured Entities (%1)", entityListModel.count)
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 6
                    
                    ListView {
                        id: entityListView
                        model: ListModel {
                            id: entityListModel
                        }
                        
                        delegate: Kirigami.SwipeListItem {
                            contentItem: RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                
                                Kirigami.Icon {
                                    source: model.icon || "home-assistant"
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    QQC2.Label {
                                        text: model.displayName || model.entityId
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }
                                    
                                    QQC2.Label {
                                        text: i18n("ID: %1 | Type: %2", model.entityId, model.controlType)
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        Layout.fillWidth: true
                                    }
                                }
                                
                                // Domain badge
                                Rectangle {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.6
                                    radius: Kirigami.Units.cornerRadius
                                    color: getDomainColor(model.entityId.split('.')[0])
                                    
                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: model.entityId.split('.')[0]
                                        color: "white"
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        font.bold: true
                                    }
                                }
                            }
                            
                            actions: [
                                Kirigami.Action {
                                    text: i18n("Remove")
                                    icon.name: "list-remove"
                                    onTriggered: removeEntity(index)
                                }
                            ]
                        }
                    }
                }
                
                QQC2.Label {
                    visible: entityListModel.count === 0
                    text: i18n("No entities configured. Browse and add entities above to control them from the widget.")
                    color: Kirigami.Theme.disabledTextColor
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        // Hidden field to store JSON data
        QQC2.TextField {
            id: configuredEntitiesField
            visible: false
            onTextChanged: parseEntities()
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
    
    function getSizeColor(size) {
        switch (size) {
            case "small": return "#4CAF50"
            case "large": return "#FF9800"
            default: return "#2196F3" // medium
        }
    }
    
    function getControlTypeColor(controlType) {
        switch (controlType) {
            case "toggle": return "#9C27B0"
            case "switch": return "#00BCD4"
            case "light": return "#FFC107"
            case "status": return "#607D8B"
            default: return "#9E9E9E"
        }
    }
}
