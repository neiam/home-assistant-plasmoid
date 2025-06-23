# Home Assistant Control Widget for Plasma 6

This is a Plasma 6 compatible widget for controlling Home Assistant entities from your KDE desktop.

## Version 2.0 Changes (Plasma 6 Compatibility)

This widget has been updated for Plasma 6 compatibility with the following changes:

### Key Updates:
1. **Qt/QML Imports**: Updated to use version-less imports compatible with Qt6
2. **Kirigami Integration**: Added proper Kirigami units and theming
3. **Configuration System**: Updated to use KCM.SimpleKCM for better integration
4. **Icon Handling**: Replaced deprecated PlasmaCore.IconItem with Kirigami.Icon
5. **Internationalization**: Added proper i18n() calls for all user-visible strings
6. **Layout Improvements**: Better responsive design using Kirigami.Units
7. **Tooltips**: Added proper tooltip integration

### Technical Changes:
- Removed version numbers from import statements
- Updated `PlasmaCore.IconItem` to `Kirigami.Icon`
- Updated configuration UI to use `KCM.SimpleKCM`
- Added `QtQuick.Controls` as `QQC2` alias
- Updated action calls to use `plasmoid.internalAction()`
- Added proper switchWidth/switchHeight properties for compact representation

## Installation

The widget is installed in the standard Plasma widget location:
```
~/.local/share/plasma/plasmoids/org.neiam.kde.homeassistant/
```

## Configuration

1. Right-click the widget and select "Configure"
2. Enter your Home Assistant URL (e.g., http://homeassistant.local:8123)
3. Enter your long-lived access token from Home Assistant
4. Set the update interval (5-300 seconds)

## Compatibility

- **Plasma 6+**: Fully compatible
- **Qt 6+**: Required
- **KDE Frameworks 6+**: Required

## Development Notes

This widget serves as a foundation for Home Assistant integration. Future versions may include:
- Entity state display
- Entity control buttons
- Custom entity selection
- Real-time updates via WebSocket

## Files Structure

```
contents/
├── config/
│   ├── config.qml       # Configuration categories
│   └── main.xml         # Configuration schema
└── ui/
    ├── main.qml         # Main widget UI
    └── configGeneral.qml # Configuration page UI
metadata.json            # Widget metadata
```

## Troubleshooting

If the widget doesn't load:
1. Check Plasma version (must be 6+)
2. Verify all files are in the correct location
3. Restart Plasma: `systemctl --user restart plasma-plasmashell`
4. Check system logs: `journalctl --user -f | grep plasma`
