import os
import sys
import tomllib
from pathlib import Path

# Set Qt Quick Controls style before creating QApplication
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

from widgets import (
    BatteryBackend,
    HotkeyBackend,
    HubBackend,
    LauncherBackend,
    MediaBackend,
    NetworkMonitorBackend,
    NewsBackend,
    NotesBackend,
    PomodoroBackend,
    SettingsBackend,
    SystemMonitorBackend,
    ThemeProvider,
    TodoBackend,
    WeatherBackend,
)


def load_widget_config() -> dict:
    """Load enabled_widgets.toml config, creating it with defaults if not found."""
    config_path = Path(__file__).parent / "enabled_widgets.toml"
    defaults = {
        "widgets": {
            "weather": True,
            "media": True,
            "general_settings": True,
            "todo": True,
            "notes": True,
            "pomodoro": True,
            "launcher": True,
            "system_monitor": True,
            "network_monitor": True,
            "battery": True,
            "news": True,
        }
    }

    if config_path.exists():
        try:
            with open(config_path, "rb") as f:
                return tomllib.load(f)
        except (tomllib.TOMLDecodeError, IOError) as e:
            print(f"Error loading enabled_widgets.toml: {e}")
            return defaults

    # File doesn't exist - create it with all widgets enabled
    default_content = """# Widget Configuration
# Set to false to completely disable a widget (won't be loaded, saves memory)
# The Hub widget is always enabled and cannot be disabled.

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
"""
    try:
        config_path.write_text(default_content)
        print("Created enabled_widgets.toml with default configuration")
    except IOError as e:
        print(f"Warning: Could not create enabled_widgets.toml: {e}")

    return defaults


def main():
    # Load widget configuration
    config = load_widget_config()
    enabled = config.get("widgets", {})

    # QApplication is required for QSystemTrayIcon
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)

    engine = QQmlApplicationEngine()
    engine.quit.connect(app.quit)

    qml_dir = Path(__file__).parent / "qml"
    icons_dir = Path(__file__).parent / "icons"
    settings_path = Path(__file__).parent / "settings.json"

    engine.addImportPath(qml_dir)

    # Pass icons directory as a context property
    engine.rootContext().setContextProperty(
        "iconsPath", QUrl.fromLocalFile(str(icons_dir) + "/")
    )

    # Pass enabled widgets config to QML
    engine.rootContext().setContextProperty("enabledWidgets", enabled)

    # Set up settings backend
    settings = SettingsBackend()
    engine.rootContext().setContextProperty("settingsBackend", settings)

    # Set up theme provider
    theme_provider = ThemeProvider(settings_path)
    engine.rootContext().setContextProperty("themeProvider", theme_provider)

    # Set up hub backend (with settings for persistence) - always enabled
    hub = HubBackend(settings_backend=settings)
    engine.rootContext().setContextProperty("hubBackend", hub)

    # Set up weather backend (if enabled)
    weather = None
    if enabled.get("weather", True):
        weather = WeatherBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("weatherBackend", weather)

    # Set up media control backend (if enabled)
    media = None
    if enabled.get("media", True):
        media = MediaBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("mediaBackend", media)

    # Set up todo backend (if enabled)
    todo = None
    if enabled.get("todo", True):
        todo = TodoBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("todoBackend", todo)

    # Set up notes backend (if enabled)
    notes = None
    if enabled.get("notes", True):
        notes = NotesBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("notesBackend", notes)

    # Set up pomodoro backend (if enabled)
    pomodoro = None
    if enabled.get("pomodoro", True):
        pomodoro = PomodoroBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("pomodoroBackend", pomodoro)

    # Set up launcher backend (if enabled)
    launcher = None
    if enabled.get("launcher", True):
        launcher = LauncherBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("launcherBackend", launcher)

    # Set up system monitor backend (if enabled)
    system_monitor = None
    if enabled.get("system_monitor", True):
        system_monitor = SystemMonitorBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("systemMonitorBackend", system_monitor)

    # Set up network monitor backend (if enabled)
    network_monitor = None
    if enabled.get("network_monitor", True):
        network_monitor = NetworkMonitorBackend(settings_backend=settings)
        engine.rootContext().setContextProperty(
            "networkMonitorBackend", network_monitor
        )

    # Set up battery backend (if enabled)
    battery = None
    if enabled.get("battery", True):
        battery = BatteryBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("batteryBackend", battery)

    # Set up news backend (if enabled)
    news = None
    if enabled.get("news", True):
        news = NewsBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("newsBackend", news)

    # Set up hotkey backend
    hotkey = HotkeyBackend(settings_backend=settings, hub_backend=hub)
    engine.rootContext().setContextProperty("hotkeyBackend", hotkey)

    # Set up system tray
    hub.setup_tray(app)

    # Connect exit signal
    hub.exitRequested.connect(app.quit)

    # Connect cleanup handlers
    app.aboutToQuit.connect(hotkey.cleanup)
    if media:
        app.aboutToQuit.connect(media.cleanup)
    if system_monitor:
        app.aboutToQuit.connect(system_monitor.cleanup)
    if network_monitor:
        app.aboutToQuit.connect(network_monitor.cleanup)
    if battery:
        app.aboutToQuit.connect(battery.cleanup)

    # Load QML files - Hub is always loaded
    engine.load(qml_dir / "Hub.qml")

    if enabled.get("weather", True):
        engine.load(qml_dir / "Weather.qml")

    if enabled.get("media", True):
        engine.load(qml_dir / "Media.qml")

    if enabled.get("general_settings", True):
        engine.load(qml_dir / "GeneralSettings.qml")

    if enabled.get("todo", True):
        engine.load(qml_dir / "Todo.qml")

    if enabled.get("notes", True):
        engine.load(qml_dir / "Notes.qml")

    if enabled.get("pomodoro", True):
        engine.load(qml_dir / "Pomodoro.qml")

    if enabled.get("launcher", True):
        engine.load(qml_dir / "Launcher.qml")

    if enabled.get("system_monitor", True):
        engine.load(qml_dir / "SystemMonitor.qml")

    if enabled.get("network_monitor", True):
        engine.load(qml_dir / "NetworkMonitor.qml")

    if enabled.get("battery", True):
        engine.load(qml_dir / "Battery.qml")

    if enabled.get("news", True):
        engine.load(qml_dir / "News.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
