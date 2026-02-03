# ADW (Amy's Desktop Widgets)

A desktop shell application for Windows displaying customizable widgets. Built with Python and Qt Quick/QML using PySide6.

**Note:** Most of the code in this repository is AI generated.

## Requirements

- Windows OS
- Python 3.11 or higher
- [uv](https://docs.astral.sh/uv/) package manager (recommended)
- LocationIQ API key for weather location search (free tier available at [locationiq.com](https://locationiq.com))

## Background

I saw a lot of great looking desktop widget systems for Linux, and I wanted to make something similar for Windows.

I started by learning the basics of QML, designing the basic Widget, and then thought this could be a good project to test the current state of AI.

## Features

This is a collection of desktop widgets that float on your screen. Each widget can be positioned, resized, and configured independently.

- System tray integration with show/hide functionality
- Global hotkeys: `Ctrl+Alt+J` (toggle always-on-top), `Ctrl+Alt+H` (show hub)
- Edit mode for repositioning and resizing widgets with mouse
- Always-on-top mode to keep widgets visible
- Widget enable/disable via TOML config (disabled widgets are not loaded, reducing memory usage)
- Full theming system with customizable colors and dimensions
- Persistent settings stored in JSON
- Transparent frameless windows with custom title bars

## Widgets

**Hub** - Central control panel for managing all widgets. Toggle widget visibility, enable edit mode for repositioning/resizing, and control always-on-top behavior.

**Weather** - Current weather conditions with hourly and daily forecasts. Uses Open-Meteo API for weather data and LocationIQ API for location search. Auto-refreshes every 30 minutes.

**Media Control** - Control Windows media sessions (Spotify, browsers, etc.). Displays track info with album art, play/pause/skip controls, seek bar, and supports multiple concurrent sessions.

**Todo** - Hierarchical task management with parent and child tasks. Supports drag-and-drop reordering, inline editing, and separate views for active and completed tasks.

**Notes** - Quick notes with color coding. Features search functionality, drag-and-drop reordering, and persistent storage.

**Pomodoro** - Focus timer with configurable work/break cycles. Sends Windows toast notifications on phase completion and tracks daily sessions.

**Launcher** - Quick application launcher. Add shortcuts via drag-and-drop, automatically extracts icons from .exe and .lnk files, customizable grid layout.

**System Monitor** - Real-time CPU and RAM monitoring with per-core CPU stats and history graphs. Configurable graph duration and colors.

**Network Monitor** - Upload and download speed monitoring with history graphs. Shows current speeds and session totals.

**Battery** - Battery percentage, charging status, and estimated time remaining.

**News** - News aggregation via Kagi News integration. Multiple category tabs with caching.

**General Settings** - Theme customization with full color palette control. Load and save themes as JSON files.


### Dependencies

- PySide6 >= 6.10.1
- psutil >= 5.9.0
- dotenv >= 0.9.9
- Pillow >= 12.1.0
- pywin32 >= 311
- winotify >= 1.1.0
- winrt-windows-media-control >= 3.2.1
- watchfiles >= 1.1.1

## Installation

```bash
# Clone the repository
git clone https://github.com/AmaliaHaible/ADW
cd ADW

# Install dependencies using uv
uv sync

# Create environment file
cp .env.example .env
```

Edit `.env` and add your LocationIQ API key:

```
LOCATIONIQ_KEY=your_api_key_here
```

## Usage

```bash
# Run the application
uv run python main.py
```

To run hidden (useful for Windows startup), use the run.vbs file.

The application starts minimized to the system tray. Double-click the tray icon or use `Ctrl+Alt+H` to show the hub.

## Configuration

### Widget Configuration

`enabled_widgets.toml` controls which widgets are loaded at startup. Disabled widgets are not loaded at all, saving memory.

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

The Hub widget is always enabled and cannot be disabled.

### Settings Persistence

Widget positions, sizes, and per-widget settings are stored in `settings.json` (auto-generated on first run).

### Environment Variables

Create a `.env` file with the following:

```
LOCATIONIQ_KEY=your_api_key_here
```

Required for weather widget location search functionality.

### Themes

The General Settings widget allows customizing all theme colors and dimensions. Themes can be exported and imported as JSON files.

## Architecture

```
qml_shell/
├── main.py              # Application entry point
├── enabled_widgets.toml # Widget enable/disable config
├── settings.json        # Persistent settings (auto-generated)
├── .env                 # Environment variables
├── qml/                 # QML UI files
│   ├── Common/          # Shared components (Theme, WidgetWindow, etc.)
│   ├── Hub.qml
│   ├── Weather.qml
│   └── ...
├── widgets/             # Python backend modules
│   ├── hub/
│   ├── weather/
│   ├── media/
│   └── ...
└── icons/               # SVG icons from https://github.com/lucide-icons/lucide
```

Python backend classes in `widgets/` are registered as context properties on the QML engine, exposing properties and slots to QML for the UI layer.


**Note:** This application is currently Windows-only due to dependencies on Windows Runtime APIs (WinRT) for media control and pywin32 for system integration.
I might do a Linux version in the future, but i am currently using Windows, and Linux has a lot of good looking similar apps.
