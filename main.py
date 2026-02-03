import os
import sys
import time
import tomllib
from pathlib import Path

# Set Qt Quick Controls style before creating QApplication
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

_start_time = time.time()


def debug_timing(label):
    elapsed = (time.time() - _start_time) * 1000
    print(f"[{elapsed:7.1f}ms] {label}")


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
    debug_timing("main() started")

    config = load_widget_config()
    enabled = config.get("widgets", {})
    debug_timing("Config loaded")

    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    debug_timing("QApplication created")

    engine = QQmlApplicationEngine()
    engine.quit.connect(app.quit)
    debug_timing("QQmlApplicationEngine created")

    qml_dir = Path(__file__).parent / "qml"
    icons_dir = Path(__file__).parent / "icons"
    settings_path = Path(__file__).parent / "settings.json"

    engine.addImportPath(qml_dir)
    engine.rootContext().setContextProperty(
        "iconsPath", QUrl.fromLocalFile(str(icons_dir) + "/")
    )
    engine.rootContext().setContextProperty("enabledWidgets", enabled)

    settings = SettingsBackend()
    engine.rootContext().setContextProperty("settingsBackend", settings)
    debug_timing("SettingsBackend initialized")

    theme_provider = ThemeProvider(settings_path)
    engine.rootContext().setContextProperty("themeProvider", theme_provider)
    debug_timing("ThemeProvider initialized")

    hub = HubBackend(settings_backend=settings)
    engine.rootContext().setContextProperty("hubBackend", hub)
    debug_timing("HubBackend initialized")

    weather = None
    if enabled.get("weather", True):
        weather = WeatherBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("weatherBackend", weather)
        debug_timing("WeatherBackend initialized")

    media = None
    if enabled.get("media", True):
        media = MediaBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("mediaBackend", media)
        debug_timing("MediaBackend initialized")

    todo = None
    if enabled.get("todo", True):
        todo = TodoBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("todoBackend", todo)
        debug_timing("TodoBackend initialized")

    notes = None
    if enabled.get("notes", True):
        notes = NotesBackend(settings_backend=settings, theme_provider=theme_provider)
        engine.rootContext().setContextProperty("notesBackend", notes)
        debug_timing("NotesBackend initialized")

    pomodoro = None
    if enabled.get("pomodoro", True):
        pomodoro = PomodoroBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("pomodoroBackend", pomodoro)
        debug_timing("PomodoroBackend initialized")

    launcher = None
    if enabled.get("launcher", True):
        launcher = LauncherBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("launcherBackend", launcher)
        debug_timing("LauncherBackend initialized")

    system_monitor = None
    if enabled.get("system_monitor", True):
        system_monitor = SystemMonitorBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("systemMonitorBackend", system_monitor)
        debug_timing("SystemMonitorBackend initialized")

    network_monitor = None
    if enabled.get("network_monitor", True):
        network_monitor = NetworkMonitorBackend(settings_backend=settings)
        engine.rootContext().setContextProperty(
            "networkMonitorBackend", network_monitor
        )
        debug_timing("NetworkMonitorBackend initialized")

    battery = None
    if enabled.get("battery", True):
        battery = BatteryBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("batteryBackend", battery)
        debug_timing("BatteryBackend initialized")

    news = None
    if enabled.get("news", True):
        news = NewsBackend(settings_backend=settings)
        engine.rootContext().setContextProperty("newsBackend", news)
        debug_timing("NewsBackend initialized")

    hotkey = HotkeyBackend(settings_backend=settings, hub_backend=hub)
    engine.rootContext().setContextProperty("hotkeyBackend", hotkey)
    debug_timing("HotkeyBackend initialized")

    hub.setup_tray(app)
    debug_timing("System tray setup")

    hub.exitRequested.connect(app.quit)
    app.aboutToQuit.connect(hotkey.cleanup)
    if media:
        app.aboutToQuit.connect(media.cleanup)
    if system_monitor:
        app.aboutToQuit.connect(system_monitor.cleanup)
    if network_monitor:
        app.aboutToQuit.connect(network_monitor.cleanup)
    if battery:
        app.aboutToQuit.connect(battery.cleanup)

    engine.load(qml_dir / "Hub.qml")
    debug_timing("Hub.qml loaded")

    if enabled.get("weather", True):
        engine.load(qml_dir / "Weather.qml")
        debug_timing("Weather.qml loaded")

    if enabled.get("media", True):
        engine.load(qml_dir / "Media.qml")
        debug_timing("Media.qml loaded")

    if enabled.get("general_settings", True):
        engine.load(qml_dir / "GeneralSettings.qml")
        debug_timing("GeneralSettings.qml loaded")

    if enabled.get("todo", True):
        engine.load(qml_dir / "Todo.qml")
        debug_timing("Todo.qml loaded")

    if enabled.get("notes", True):
        engine.load(qml_dir / "Notes.qml")
        debug_timing("Notes.qml loaded")

    if enabled.get("pomodoro", True):
        engine.load(qml_dir / "Pomodoro.qml")
        debug_timing("Pomodoro.qml loaded")

    if enabled.get("launcher", True):
        engine.load(qml_dir / "Launcher.qml")
        debug_timing("Launcher.qml loaded")

    if enabled.get("system_monitor", True):
        engine.load(qml_dir / "SystemMonitor.qml")
        debug_timing("SystemMonitor.qml loaded")

    if enabled.get("network_monitor", True):
        engine.load(qml_dir / "NetworkMonitor.qml")
        debug_timing("NetworkMonitor.qml loaded")

    if enabled.get("battery", True):
        engine.load(qml_dir / "Battery.qml")
        debug_timing("Battery.qml loaded")

    if enabled.get("news", True):
        engine.load(qml_dir / "News.qml")
        debug_timing("News.qml loaded")

    if not engine.rootObjects():
        sys.exit(-1)

    debug_timing("All QML loaded, starting event loop")
    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
