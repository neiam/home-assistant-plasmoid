# Home Assistant Control Widget for Plasma 6

This is a Plasma 6 compatible widget for controlling Home Assistant entities from your KDE desktop.

## Version 2.0 Features

### ✨ **NEW: Entity Control System**
- **Configure Custom Entities**: Add any Home Assistant entity (lights, switches, automations, etc.)
- **Interactive Controls**: Click to toggle entities directly from your desktop
- **Visual State Feedback**: Buttons show current entity state with color coding
- **Flexible Layout**: Configurable grid layout with 1-6 entities per row
- **Smart Icons**: Auto-detects appropriate icons based on entity type
- **Real-time Updates**: Automatically refreshes entity states at configurable intervals

### 🔍 **NEW: Entity Autocomplete & Browser**
- **Live Entity Browser**: Browse all entities directly from Home Assistant
- **Search & Filter**: Search by name or entity ID, filter by domain type
- **Visual Entity List**: See entity states, icons, and domain badges
- **Auto-fill Fields**: Automatically populate display names and icons
- **Smart Suggestions**: Recommends appropriate control types per entity
- **Connection Test**: Verify Home Assistant connection before browsing
- **Live Preview**: See exactly how your entity control will look before adding it
- **Interactive Icon Picker**: Browse and select icons visually from Plasma's icon collection

### 🎛️ **Control Types Supported**
- **Toggle Button**: For lights, switches, automations
- **Switch Control**: Explicit on/off controls
- **Light Control**: Optimized for light entities
- **Status Display**: Read-only state display

### 🎨 **Customization Options**
- **Button Sizes**: Small, Medium, Large
- **Show/Hide Labels**: Toggle entity names
- **Custom Icons**: Override default icons per entity
- **Grid Layout**: 1-6 entities per row
- **Update Intervals**: 5-300 seconds

## Configuration

### **Step 1: General Settings**
1. Right-click the widget → "Configure"
2. In the **General** tab:
   - Enter your Home Assistant URL (e.g., `http://homeassistant.local:8123`)
   - Enter your long-lived access token
   - Set update interval (5-300 seconds)

### **Step 2: Entity Configuration**
1. Switch to the **Entities** tab
2. Configure display options:
   - **Entities per row**: 1-6 (default: 3)
   - **Show entity labels**: On/Off
   - **Button size**: Small/Medium/Large

3. **Browse & Add Entities** (NEW!):
   - **Entity Browser**: Click the dropdown to browse all Home Assistant entities
   - **Search**: Type to filter entities by name or ID
   - **Domain Filter**: Click buttons to filter by entity type (light, switch, etc.)
   - **Visual Selection**: See entity states, icons, and current values
   - **Auto-fill**: Selected entities automatically populate fields
   - **OR Manual Entry**: Enter entity details manually if needed

4. **Configure Entity & Preview**:
   - **Display Name**: Friendly name (auto-filled from Home Assistant)
   - **Control Type**: Auto-suggested based on entity type
   - **Icon Selection**: 
     - Manual entry in text field OR
     - **Browse Icons**: Visual icon picker with search and categories
     - **Icon Preview**: See current icon in real-time
     - **Reset**: Clear custom icon to use auto-detected
   - **Live Preview**: See exactly how the control will look with current settings
   - **Interactive Preview**: Click the preview to test control behavior (safe mode)
   - **Settings Indicators**: Visual indicators for labels, size, and control type
   - Click **Add Entity**

5. **Manage Entities**:
   - Swipe left on any entity to remove it
   - View entity details and domain badges
   - Duplicate entities are automatically updated

### **Step 3: Usage**
- **Compact Mode**: Shows badge with entity count
- **Click to Expand**: Opens full control panel
- **Entity Controls**: Click buttons to toggle entities
- **Tooltips**: Hover for detailed state information

## Supported Entity Types

| Domain | Auto-Icon | Supported Actions |
|--------|-----------|-------------------|
| `light.*` | 💡 Lightbulb | Toggle, Turn On/Off |
| `switch.*` | 🔌 Toggle Switch | Toggle, Turn On/Off |
| `fan.*` | 🌪️ Windy | Toggle, Turn On/Off |
| `automation.*` | ▶️ Play/Stop | Toggle, Turn On/Off |
| `input_boolean.*` | ☑️ Checkbox | Toggle |
| `climate.*` | 🌡️ Thermometer | Status Display |
| `lock.*` | 🔒 Lock | Status Display |
| `cover.*` | 🪟 Window | Status Display |

## Entity ID Examples

```
# Lights
light.living_room
light.bedroom_lamp
light.kitchen_ceiling

# Switches  
switch.living_room_fan
switch.coffee_maker
switch.outdoor_lights

# Automations
automation.morning_routine
automation.security_mode
automation.bedtime_lights

# Input Booleans
input_boolean.guest_mode
input_boolean.vacation_mode

# Climate
climate.thermostat
climate.bedroom_ac
```

## Plasma 6 Compatibility Updates

### Key Technical Changes:
- ✅ **Qt6 Compatible**: Version-less imports
- ✅ **Kirigami Integration**: Proper theming and units
- ✅ **KCM Configuration**: Modern config system
- ✅ **Component Updates**: Replaced deprecated elements
- ✅ **API Integration**: Full Home Assistant REST API support
- ✅ **State Management**: Real-time entity state tracking
- ✅ **Error Handling**: Robust error handling and logging

### Files Structure

```
contents/
├── config/
│   ├── config.qml         # Configuration categories
│   └── main.xml           # Configuration schema
└── ui/
    ├── main.qml           # Main widget UI with entity grid
    ├── configGeneral.qml  # Connection configuration
    ├── configEntities.qml # Entity management UI
    ├── HomeAssistantAPI.qml # API communication layer
    └── EntityControl.qml  # Individual entity control component
metadata.json              # Widget metadata
```

## Home Assistant Setup

### 1. Create Long-Lived Access Token
1. Open Home Assistant
2. Go to Profile → Security
3. Scroll to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Name it (e.g., "Plasma Widget")
6. Copy the token (you won't see it again!)

### 2. Test API Access
```bash
# Test connection (replace URL and TOKEN)
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  http://homeassistant.local:8123/api/
```

## Troubleshooting

### Widget Not Loading
1. Check Plasma version: `plasmashell --version` (must be 6+)
2. Verify file permissions: `ls -la ~/.local/share/plasma/plasmoids/`
3. Check logs: `journalctl --user -f | grep plasma`

### Connection Issues
1. Verify Home Assistant URL is accessible
2. Test API token in browser/curl
3. Check firewall settings
4. Ensure Home Assistant is running

### Entity Control Issues
1. Verify entity IDs exist in Home Assistant
2. Check entity permissions (some may be read-only)
3. Review Home Assistant logs for API errors
4. Test entity control in Home Assistant UI first

### Performance Tips
- Use longer update intervals (60+ seconds) for better performance
- Limit entities to 6-12 for optimal responsiveness
- Use "Status Display" for read-only entities

## Advanced Usage

### Custom Icons
Use any KDE icon name or file path:
- `lightbulb`, `power-socket`, `fan`
- `weather-clear`, `weather-cloudy`
- `/path/to/custom/icon.svg`

### Entity Naming
- Use descriptive names: "Living Room Lights" vs "light.living_room"
- Keep names short for better layout
- Use consistent naming conventions

## Compatibility

- **Plasma 6+**: Required
- **Qt 6+**: Required  
- **KDE Frameworks 6+**: Required
- **Home Assistant 2023.1+**: Recommended

## Contributing

This widget is open source. Feel free to contribute improvements:
- Enhanced entity types support
- Additional control types
- UI/UX improvements
- Performance optimizations

---

## 🚀 Automated Publishing

This repository includes GitHub Actions for automated packaging and release management. See [PUBLISHING.md](PUBLISHING.md) for details on:
- Automated KDE Store package creation
- Release management with git tags
- Local development and testing tools
- Deployment workflow documentation
