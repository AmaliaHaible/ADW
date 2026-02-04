# ADW (Amy's Desktop Widgets) - Agent Guide

This document provides comprehensive guidance for AI agents working with this codebase.

## Project Overview

ADW is a **PySide6/QML desktop widget system for Windows**. It displays customizable, floating widgets on the desktop with features like:

- Transparent frameless windows with custom title bars
- System tray integration
- Global hotkeys (`Ctrl+Alt+J` toggle always-on-top, `Ctrl+Alt+H` show hub)
- Edit mode for drag-and-drop repositioning/resizing
- Full theming system with 20+ included themes
- Persistent settings (JSON) and widget configuration (TOML)

**Note**: Most code in this repository is AI-generated.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **UI** | Qt Quick (QML) with QtQuick.Controls 2.15 |
| **Backend** | Python 3.13 with PySide6 |
| **Package Manager** | [uv](https://docs.astral.sh/uv/) |
| **Linting/Formatting** | [ruff](https://docs.astral.sh/ruff/) |
| **Platform** | Windows-only (WinRT APIs, pywin32) |

---

## Commands

### Installation

```bash
# Clone the repository
git clone https://github.com/AmaliaHaible/ADW
cd ADW

# Install dependencies using uv
uv sync

# Create environment file
cp .env.example .env
# Edit .env and add your LocationIQ API key
```

### Running

```bash
# Run the application
uv run python main.py

# Run with hot-reload (auto-restarts on file changes)
uv run python dev.py
```

### Linting and Formatting with Ruff

```bash
# Check for linting issues
uv run ruff check .

# Auto-fix linting issues
uv run ruff check --fix .

# Format code
uv run ruff format .

# Check formatting without applying
uv run ruff format --check .
```

---

## Directory Structure

```
ADW/
├── main.py                    # Application entry point
├── dev.py                     # Hot-reload development script
├── pyproject.toml             # Project config, dependencies
├── uv.lock                    # uv lockfile
├── enabled_widgets.toml       # Widget enable/disable config (auto-generated)
├── settings.json              # Persistent settings (auto-generated)
├── .env                       # Environment variables (LOCATIONIQ_KEY)
├── .python-version            # Python version (3.13)
│
├── qml/                       # QML UI files
│   ├── Common/                # Shared QML components
│   │   ├── qmldir             # Module definition
│   │   ├── Theme.qml          # Theme singleton (colors, dimensions)
│   │   ├── WidgetWindow.qml   # Base widget window component
│   │   ├── TitleBar.qml       # Custom title bar component
│   │   ├── ColorPicker.qml    # Color picker component
│   │   └── ScrollingText.qml  # Scrolling text component
│   ├── Hub.qml                # Main control panel widget
│   ├── Weather.qml            # Weather widget
│   ├── Media.qml              # Media control widget
│   ├── Todo.qml               # Todo list widget
│   ├── Notes.qml              # Notes widget
│   ├── Pomodoro.qml           # Pomodoro timer widget
│   ├── Launcher.qml           # App launcher widget
│   ├── SystemMonitor.qml      # CPU/RAM monitor widget
│   ├── NetworkMonitor.qml     # Network speed widget
│   ├── Battery.qml            # Battery status widget
│   ├── News.qml               # News aggregator widget
│   └── GeneralSettings.qml    # Theme customization widget
│
├── widgets/                   # Python backend modules
│   ├── __init__.py            # Exports all backends
│   ├── settings.py            # SettingsBackend (persistent storage)
│   ├── theme_provider.py      # ThemeProvider (theme management)
│   ├── theme_constants.py     # DEFAULT_THEME dictionary
│   ├── hub/                   # Hub widget backend
│   │   ├── __init__.py
│   │   └── hub.py             # HubBackend class
│   ├── weather/               # Weather widget backend
│   ├── media/                 # Media control backend (WinRT)
│   ├── todo/                  # Todo widget backend
│   ├── notes/                 # Notes widget backend
│   ├── pomodoro/              # Pomodoro timer backend
│   ├── launcher/              # App launcher backend
│   ├── system_monitor/        # System monitor backend
│   ├── network_monitor/       # Network monitor backend
│   ├── battery/               # Battery monitor backend
│   ├── news/                  # News aggregator backend
│   └── hotkey/                # Global hotkey handler
│
├── default_themes/            # JSON theme files (20+ themes)
│   ├── catppuccin_mocha.json
│   ├── tokyo_night.json
│   ├── gruvbox_dark.json
│   └── ...
│
└── icons/                     # SVG icon library (Lucide icons)
```

---

## Architecture

### Python-QML Bridge Pattern

Python backend classes in `widgets/` are **QObject subclasses** registered as **context properties** on the QML engine:

```python
# main.py pattern
from widgets import BatteryBackend

battery = BatteryBackend(settings_backend=settings)
engine.rootContext().setContextProperty("batteryBackend", battery)
```

This exposes Python properties, signals, and slots directly to QML:

```qml
// Battery.qml - accessing Python backend
Text {
    text: batteryBackend.percent + "%"  // Property access
    visible: batteryBackend.hasBattery  // Property access
}

// Calling a Python slot
Button {
    onClicked: batteryBackend.refresh()  // Slot invocation
}
```

### Backend Class Pattern

All widget backends follow this consistent pattern:

```python
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

class ExampleBackend(QObject):
    # 1. Declare signals for property change notifications
    dataChanged = Signal()
    
    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        
        # 2. Initialize internal state
        self._data = ""
        
        # 3. Set up timers if needed (for periodic updates)
        self._timer = QTimer(self)
        self._timer.setInterval(30000)  # 30 seconds
        self._timer.timeout.connect(self._update)
        self._timer.start()
        
        # 4. Initial update
        self._update()
    
    def _update(self):
        """Update internal state and emit change signal."""
        # ... update logic ...
        self.dataChanged.emit()
    
    # 5. Properties with notify signals (read from QML)
    @Property(str, notify=dataChanged)
    def data(self):
        return self._data
    
    # 6. Slots callable from QML
    @Slot()
    def refresh(self):
        """Force refresh."""
        self._update()
    
    # 7. Cleanup method (connected to app.aboutToQuit)
    def cleanup(self):
        """Stop timer on cleanup."""
        self._timer.stop()
```

### QML Widget Pattern

All widget UIs extend `WidgetWindow` from `Common`:

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: myWindow
    
    // Required properties
    geometryKey: "my_widget"           // Key for settings persistence
    settingsStore: settingsBackend     // Reference to SettingsBackend
    editMode: hubBackend.editMode      // Bound to hub's edit mode
    hubVisible: hubBackend.hubVisible  // For z-order management
    
    // Size constraints
    minResizeWidth: 180
    minResizeHeight: 120
    
    // Initial geometry
    width: 200
    height: 140
    x: 100
    y: 100
    
    // Visibility bound to hub
    visible: hubBackend.myWidgetVisible
    title: "My Widget"
    
    Column {
        anchors.fill: parent
        spacing: 0
        
        // Title bar with minimize button
        TitleBar {
            width: parent.width
            title: "My Widget"
            dragEnabled: myWindow.editMode
            minimized: myWindow.minimized
            effectiveRadius: myWindow.effectiveWindowRadius
            rightButtons: [
                {icon: myWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}
            ]
            onButtonClicked: function(action) {
                if (action === "minimize") myWindow.toggleMinimize()
            }
        }
        
        // Main content area
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !myWindow.minimized
            
            // Widget content here...
        }
    }
}
```

### Theme System

Theme values flow from Python to QML:

1. **`widgets/theme_constants.py`**: Defines `DEFAULT_THEME` dictionary
2. **`widgets/theme_provider.py`**: `ThemeProvider` class exposes theme as QML properties
3. **`qml/Common/Theme.qml`**: Singleton that reads from `themeProvider` context property
4. **Widget QML files**: Access via `Theme.propertyName` (e.g., `Theme.accentColor`)

```qml
// Accessing theme in QML
Rectangle {
    color: Theme.windowBackground
    radius: Theme.borderRadius
    
    Text {
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeNormal
    }
}
```

---

## Widget System

### Widget Lifecycle

1. **Configuration**: `enabled_widgets.toml` determines which widgets load
2. **Backend Init**: Python backend created and registered as context property
3. **QML Load**: Corresponding QML file loaded by engine
4. **Visibility**: Controlled by `HubBackend` (toggle buttons in Hub widget)
5. **Cleanup**: `aboutToQuit` signal triggers backend cleanup methods

### Adding a New Widget

#### Step 1: Create Python Backend

Create `widgets/my_widget/my_widget.py`:

```python
from PySide6.QtCore import QObject, Property, Signal, Slot

class MyWidgetBackend(QObject):
    dataChanged = Signal()
    
    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._value = "Hello"
    
    @Property(str, notify=dataChanged)
    def value(self):
        return self._value
    
    @Slot(str)
    def setValue(self, new_value):
        if self._value != new_value:
            self._value = new_value
            self.dataChanged.emit()
```

Create `widgets/my_widget/__init__.py`:

```python
from .my_widget import MyWidgetBackend

__all__ = ["MyWidgetBackend"]
```

#### Step 2: Export from widgets package

Edit `widgets/__init__.py`:

```python
from .my_widget import MyWidgetBackend
# ... other imports ...

__all__ = [
    "MyWidgetBackend",
    # ... other exports ...
]
```

#### Step 3: Create QML UI

Create `qml/MyWidget.qml`:

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import Common 1.0

WidgetWindow {
    id: myWindow
    geometryKey: "my_widget"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    visible: hubBackend.myWidgetVisible
    title: "My Widget"
    width: 200
    height: 150
    
    Column {
        anchors.fill: parent
        
        TitleBar {
            width: parent.width
            title: "My Widget"
            dragEnabled: myWindow.editMode
            minimized: myWindow.minimized
            effectiveRadius: myWindow.effectiveWindowRadius
            rightButtons: [{icon: myWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}]
            onButtonClicked: (action) => { if (action === "minimize") myWindow.toggleMinimize() }
        }
        
        Rectangle {
            width: parent.width
            height: parent.height - 32
            color: "transparent"
            visible: !myWindow.minimized
            
            Text {
                anchors.centerIn: parent
                text: myWidgetBackend.value
                color: Theme.textPrimary
            }
        }
    }
}
```

#### Step 4: Register in main.py

```python
from widgets import MyWidgetBackend

# In main():
my_widget = None
if enabled.get("my_widget", True):
    my_widget = MyWidgetBackend(settings_backend=settings)
    engine.rootContext().setContextProperty("myWidgetBackend", my_widget)

# Load QML
if enabled.get("my_widget", True):
    engine.load(qml_dir / "MyWidget.qml")

# Cleanup if needed
if my_widget:
    app.aboutToQuit.connect(my_widget.cleanup)
```

#### Step 5: Add visibility to HubBackend

Edit `widgets/hub/hub.py`:

```python
class HubBackend(QObject):
    myWidgetVisibleChanged = Signal(bool)
    
    def __init__(self, ...):
        # ...
        self._my_widget_visible = self._settings.getWidgetVisible("my_widget") if self._settings else False
    
    @Property(bool, notify=myWidgetVisibleChanged)
    def myWidgetVisible(self):
        return self._my_widget_visible
    
    @myWidgetVisible.setter
    def myWidgetVisible(self, value):
        if self._my_widget_visible != value:
            self._my_widget_visible = value
            if self._settings:
                self._settings.setWidgetVisible("my_widget", value)
            self.myWidgetVisibleChanged.emit(value)
    
    @Slot(bool)
    def setMyWidgetVisible(self, visible):
        self.myWidgetVisible = visible
```

#### Step 6: Add to enabled_widgets.toml defaults

Edit the defaults in `main.py`:

```python
defaults = {
    "widgets": {
        # ... existing widgets ...
        "my_widget": True,
    }
}
```

#### Step 7: Add toggle button to Hub.qml

Add a button in the Hub widget to toggle visibility.

---

## Configuration Files

### pyproject.toml

```toml
[project]
name = "ADW"
version = "0.1.0"
description = "QML Desktop Widget System for Windows"
requires-python = ">=3.11"
dependencies = [
    "pyside6>=6.10.1",
    "psutil>=5.9.0",
    "dotenv>=0.9.9",
    "pillow>=12.1.0",
    "pywin32>=311",
    "winotify>=1.1.0",
    "winrt-windows-media-control>=3.2.1",
    "watchfiles>=1.1.1",
    # ... more winrt packages ...
]
```

### enabled_widgets.toml

Controls which widgets are loaded at startup (auto-generated with defaults):

```toml
[widgets]
weather = true
media = true
general_settings = true
todo = true
notes = true
pomodoro = true
launcher = true
system_monitor = true
network_monitor = true
battery = true
news = true
```

**Note**: The Hub widget is always enabled and cannot be disabled.

### .env

Required for weather widget location search:

```
LOCATIONIQ_KEY=your_api_key_here
```

Get a free API key at [locationiq.com](https://locationiq.com).

---

## Development Workflow

### Hot Reload

Use `dev.py` for development - it watches `qml/`, `main.py`, and `widgets/` for changes and auto-restarts:

```bash
uv run python dev.py
```

### Code Quality

Always run ruff before committing:

```bash
# Check and auto-fix
uv run ruff check --fix .

# Format
uv run ruff format .
```

### Testing Changes

1. Make code changes
2. Run `uv run ruff check --fix . && uv run ruff format .`
3. Run `uv run python main.py` (or use dev.py for hot reload)
4. Test the affected widget functionality

---

## Key Patterns & Conventions

### Property Naming

- Python: `snake_case` internally, but Properties use `camelCase` for QML
- QML: `camelCase` for all identifiers
- Signals: `propertyNameChanged` pattern for property notifications

### File Naming

- Python: `snake_case.py`
- QML: `PascalCase.qml`
- JSON themes: `snake_case.json`

### Settings Keys

- Widget geometry keys match the widget name in snake_case
- Use `settingsBackend.getWidgetSetting()` / `setWidgetSetting()` for widget-specific settings

### Z-Order Management

Widgets use `Qt.WindowStaysOnTopHint` or `Qt.WindowStaysOnBottomHint` based on:
- `hubBackend.alwaysOnTop` - Global always-on-top toggle
- `hubBackend.hubVisible` - Whether hub is visible (widgets come to front with hub)

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `pyside6` | Qt bindings for Python |
| `psutil` | System monitoring (CPU, RAM, battery) |
| `dotenv` | Environment variable loading |
| `pillow` | Image processing (album art, icons) |
| `pywin32` | Windows API access |
| `winotify` | Windows toast notifications |
| `winrt-*` | Windows Runtime APIs (media control) |
| `watchfiles` | File watching for hot reload |

---

## Troubleshooting

### Common Issues

1. **QML import errors**: Ensure `engine.addImportPath(qml_dir)` is called before loading QML
2. **Context property not found**: Backend must be registered before loading its QML file
3. **Theme not updating**: Check that `themeChanged` signal is emitted and QML bindings use `Theme.` prefix
4. **Window not showing**: Check `visible` property binding and `hubBackend.*Visible` property

### Debugging Tips

- Use `debug_timing()` in main.py to profile startup
- Check console for Python exceptions
- QML errors appear in console with file:line references
- Use `console.log()` in QML for debugging
