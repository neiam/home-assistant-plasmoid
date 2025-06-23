import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: configGeneral
    
    property alias cfg_homeAssistantUrl: homeAssistantUrlField.text
    property alias cfg_accessToken: accessTokenField.text
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    
    // Test connection functionality
    property bool isTestingConnection: false
    property string connectionTestResult: ""
    property bool connectionTestSuccess: false
    
    // Home Assistant API for testing
    HomeAssistantAPI {
        id: testAPI
        baseUrl: homeAssistantUrlField.text
        accessToken: accessTokenField.text
        
        onError: function(message) {
            isTestingConnection = false
            connectionTestResult = message
            connectionTestSuccess = false
        }
    }
    
    function testConnection() {
        if (!homeAssistantUrlField.text.trim() || !accessTokenField.text.trim()) {
            connectionTestResult = i18n("Please enter both URL and access token")
            connectionTestSuccess = false
            return
        }
        
        isTestingConnection = true
        connectionTestResult = ""
        
        testAPI.testConnection(function(success, message) {
            isTestingConnection = false
            connectionTestResult = message
            connectionTestSuccess = success
            
            if (success) {
                // Also notify the entities tab about the connection
                notifyEntitiesTab()
            }
        })
    }
    
    function notifyEntitiesTab() {
        // Try to find and update the entities configuration
        // This is a bit of a hack, but necessary for cross-tab communication
        var entitiesPage = parent
        while (entitiesPage && !entitiesPage.updateConnectionInfo) {
            entitiesPage = entitiesPage.parent
        }
        if (entitiesPage && entitiesPage.updateConnectionInfo) {
            entitiesPage.updateConnectionInfo(cfg_homeAssistantUrl, cfg_accessToken)
        }
    }
    
    Kirigami.FormLayout {
        QQC2.TextField {
            id: homeAssistantUrlField
            Kirigami.FormData.label: i18n("Home Assistant URL:")
            placeholderText: i18n("http://homeassistant.local:8123")
            
            onTextChanged: {
                connectionTestResult = ""
                if (text.trim() && accessTokenField.text.trim()) {
                    Qt.callLater(notifyEntitiesTab)
                }
            }
        }
        
        QQC2.TextField {
            id: accessTokenField
            Kirigami.FormData.label: i18n("Access Token:")
            placeholderText: i18n("Long-lived access token from Home Assistant")
            echoMode: TextInput.Password
            
            onTextChanged: {
                connectionTestResult = ""
                if (text.trim() && homeAssistantUrlField.text.trim()) {
                    Qt.callLater(notifyEntitiesTab)
                }
            }
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("Connection:")
            
            QQC2.Button {
                text: i18n("Test Connection")
                icon.name: "network-connect"
                enabled: !isTestingConnection && homeAssistantUrlField.text.trim() && accessTokenField.text.trim()
                onClicked: testConnection()
            }
            
            QQC2.BusyIndicator {
                visible: isTestingConnection
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
        }
        
        QQC2.Label {
            visible: connectionTestResult
            text: connectionTestResult
            color: connectionTestSuccess ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
        
        Kirigami.Separator {
            Layout.fillWidth: true
            visible: connectionTestResult
        }
        
        QQC2.SpinBox {
            id: updateIntervalSpinBox
            Kirigami.FormData.label: i18n("Update Interval (seconds):")
            from: 5
            to: 300
            value: 30
        }
        
        Item {
            Layout.fillHeight: true
        }
        
        // Help section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            QQC2.Label {
                text: i18n("How to get an access token:")
                font.bold: true
            }
            
            QQC2.Label {
                text: i18n("1. Open Home Assistant in your browser\n2. Go to Profile → Security\n3. Scroll to 'Long-Lived Access Tokens'\n4. Click 'Create Token'\n5. Give it a name (e.g., 'Plasma Widget')\n6. Copy the token and paste it above")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
