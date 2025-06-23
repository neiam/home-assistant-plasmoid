import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral
    
    property alias cfg_homeAssistantUrl: homeAssistantUrlField.text
    property alias cfg_accessToken: accessTokenField.text
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    
    Kirigami.FormLayout {
        QQC2.TextField {
            id: homeAssistantUrlField
            Kirigami.FormData.label: i18n("Home Assistant URL:")
            placeholderText: i18n("http://homeassistant.local:8123")
        }
        
        QQC2.TextField {
            id: accessTokenField
            Kirigami.FormData.label: i18n("Access Token:")
            placeholderText: i18n("Long-lived access token from Home Assistant")
            echoMode: TextInput.Password
        }
        
        QQC2.SpinBox {
            id: updateIntervalSpinBox
            Kirigami.FormData.label: i18n("Update Interval (seconds):")
            from: 5
            to: 300
            value: 30
        }
    }
}
