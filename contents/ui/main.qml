import QtQuick
import QtQuick.Layouts
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
    
    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            text: i18n("Home Assistant Control")
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        PlasmaComponents3.Label {
            text: i18n("Configure the widget to connect to your Home Assistant instance")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
        }
        
        PlasmaComponents3.Button {
            text: i18n("Configure")
            Layout.alignment: Qt.AlignHCenter
            onClicked: plasmoid.internalAction("configure").trigger()
        }
        
        Item {
            Layout.fillHeight: true
        }
    }
    
    compactRepresentation: Kirigami.Icon {
        source: plasmoid.icon
        anchors.fill: parent
        
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18n("Home Assistant Control")
            subText: i18n("Click to open")
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
}
