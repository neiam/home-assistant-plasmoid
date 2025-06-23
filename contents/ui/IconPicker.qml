import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

QQC2.Dialog {
    id: iconPicker
    
    property string selectedIcon: ""
    property var iconCategories: [
        "Applications", "Actions", "Devices", "Places", "Status", "Mimes"
    ]
    property var commonIcons: [
        // Lights & Electrical
        "lightbulb", "lightbulb-on", "lightbulb-off", "power-socket", "battery", "battery-full",
        "preferences-system-power-management", "network-wireless", "network-wired",
        
        // Home & Rooms
        "user-home", "go-home", "preferences-desktop-wallpaper", "window", "window-close",
        "window-open", "door-open", "door-closed",
        
        // Controls & Actions
        "media-playback-start", "media-playback-stop", "media-playback-pause",
        "toggle-switch", "configure", "settings-configure", "system-run",
        
        // Weather & Climate
        "weather-clear", "weather-clouds", "weather-fog", "weather-rain",
        "weather-snow", "thermometer", "temperature-warm", "temperature-cold",
        
        // Security
        "security-high", "security-low", "lock", "unlock", "view-hidden", "view-visible",
        
        // Technology
        "computer", "laptop", "tablet", "smartphone", "camera-photo", "camera-video",
        "speaker", "audio-headphones", "microphone-sensitivity-high",
        
        // Appliances
        "games-config-background", "preferences-desktop-theme", "fan", "air-conditioner",
        "washing-machine", "refrigerator", "microwave", "coffee-maker",
        
        // Automotive
        "car", "vehicle", "fuel", "engine", "tire",
        
        // Nature & Garden
        "weather-clear-night", "weather-few-clouds", "plant", "tree", "flower",
        
        // Utilities
        "tools-check-spelling", "edit-find", "zoom-in", "zoom-out", "view-refresh",
        "dialog-information", "dialog-warning", "dialog-error", "emblem-important"
    ]
    
    signal iconSelected(string iconName)
    
    title: i18n("Select Icon")
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 25
    modal: true
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
        
        // Search field
        QQC2.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("Search icons...")
            onTextChanged: filterIcons()
        }
        
        // Tab bar for categories
        QQC2.TabBar {
            id: categoryTabBar
            Layout.fillWidth: true
            
            QQC2.TabButton {
                text: i18n("Common")
            }
            QQC2.TabButton {
                text: i18n("All Icons")
            }
        }
        
        // Icon grid
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            
            GridView {
                id: iconGrid
                cellWidth: Kirigami.Units.gridUnit * 3
                cellHeight: Kirigami.Units.gridUnit * 3
                
                model: ListModel {
                    id: iconModel
                }
                
                delegate: Item {
                    width: iconGrid.cellWidth
                    height: iconGrid.cellHeight
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        color: mouseArea.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                        border.color: selectedIcon === model.iconName ? Kirigami.Theme.highlightColor : "transparent"
                        border.width: 2
                        radius: Kirigami.Units.cornerRadius
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            
                            Kirigami.Icon {
                                source: model.iconName
                                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            QQC2.Label {
                                text: model.iconName
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            
                            onClicked: {
                                selectedIcon = model.iconName
                            }
                            
                            onDoubleClicked: {
                                selectedIcon = model.iconName
                                iconSelected(selectedIcon)
                                iconPicker.close()
                            }
                        }
                    }
                }
            }
        }
        
        // Status bar
        RowLayout {
            Layout.fillWidth: true
            
            QQC2.Label {
                text: selectedIcon ? i18n("Selected: %1", selectedIcon) : i18n("Click an icon to select it")
                Layout.fillWidth: true
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            
            QQC2.Label {
                text: i18n("%1 icons", iconModel.count)
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }
        
        // Buttons
        RowLayout {
            Layout.fillWidth: true
            
            QQC2.Button {
                text: i18n("Cancel")
                onClicked: iconPicker.close()
            }
            
            Item { Layout.fillWidth: true }
            
            QQC2.Button {
                text: i18n("Select")
                enabled: selectedIcon
                highlighted: true
                onClicked: {
                    if (selectedIcon) {
                        iconSelected(selectedIcon)
                        iconPicker.close()
                    }
                }
            }
        }
    }
    
    function loadCommonIcons() {
        iconModel.clear()
        for (var i = 0; i < commonIcons.length; i++) {
            iconModel.append({ iconName: commonIcons[i] })
        }
    }
    
    function loadAllIcons() {
        iconModel.clear()
        
        // This is a simplified approach - in a real implementation,
        // you might want to use KIconLoader or similar to get all available icons
        var systemIcons = [
            // Add more system icons here - this is a sample
            "accessories-calculator", "accessories-character-map", "accessories-dictionary",
            "accessories-text-editor", "application-exit", "applications-accessories",
            "applications-development", "applications-games", "applications-graphics",
            "applications-internet", "applications-multimedia", "applications-office",
            "applications-system", "applications-utilities", "appointment-new",
            "call-start", "call-stop", "camera-photo", "camera-video",
            "document-new", "document-open", "document-print", "document-save",
            "edit-copy", "edit-cut", "edit-delete", "edit-find", "edit-paste",
            "folder", "folder-new", "go-down", "go-home", "go-jump", "go-next",
            "go-previous", "go-up", "help-about", "help-contents", "insert-image",
            "list-add", "list-remove", "mail-message-new", "media-eject",
            "network-connect", "network-disconnect", "printer", "system-log-out",
            "system-reboot", "system-shutdown", "view-fullscreen", "view-refresh",
            "zoom-fit-best", "zoom-in", "zoom-original", "zoom-out"
        ]
        
        var allIcons = commonIcons.concat(systemIcons)
        for (var i = 0; i < allIcons.length; i++) {
            iconModel.append({ iconName: allIcons[i] })
        }
    }
    
    function filterIcons() {
        var searchText = searchField.text.toLowerCase()
        if (!searchText) {
            if (categoryTabBar.currentIndex === 0) {
                loadCommonIcons()
            } else {
                loadAllIcons()
            }
            return
        }
        
        var sourceIcons = categoryTabBar.currentIndex === 0 ? commonIcons : commonIcons.concat([
            "accessories-calculator", "applications-games", "document-new", "folder"
            // Add more as needed
        ])
        
        iconModel.clear()
        for (var i = 0; i < sourceIcons.length; i++) {
            if (sourceIcons[i].toLowerCase().indexOf(searchText) !== -1) {
                iconModel.append({ iconName: sourceIcons[i] })
            }
        }
    }
    
    onAboutToShow: {
        selectedIcon = ""
        if (categoryTabBar.currentIndex === 0) {
            loadCommonIcons()
        } else {
            loadAllIcons()
        }
    }
    
    Connections {
        target: categoryTabBar
        function onCurrentIndexChanged() {
            if (categoryTabBar.currentIndex === 0) {
                loadCommonIcons()
            } else {
                loadAllIcons()
            }
        }
    }
}
