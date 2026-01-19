import os
import sys
import tomllib
from pathlib import Path

# Set Qt Quick Controls style before creating QApplication
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

from widgets import HotkeyBackend, HubBackend, MediaBackend, SettingsBackend, ThemeProvider, WeatherBackend


def load_widget_config() -> dict:
    """Load enabled_widgets.toml config, returning defaults if not found."""
    config_path = Path(__file__).parent / "enabled_widgets.toml"
    defaults = {"widgets": {"weather": True, "media": True, "general_settings": True}}

    if config_path.exists():
        try:
            with open(config_path, "rb") as f:
                return tomllib.load(f)
        except (tomllib.TOMLDecodeError, IOError) as e:
            print(f"Error loading enabled_widgets.toml: {e}")
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
    engine.rootContext().setContextProperty("iconsPath", QUrl.fromLocalFile(str(icons_dir) + "/"))

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

    # Set up hotkey backend
    hotkey = HotkeyBackend(settings_backend=settings, hub_backend=hub)
    engine.rootContext().setContextProperty("hotkeyBackend", hotkey)

    # Set up system tray
    hub.setup_tray(app)

    # Connect exit signal
    hub.exitRequested.connect(app.quit)

    # Connect hotkey cleanup
    app.aboutToQuit.connect(hotkey.cleanup)

    # Load QML files - Hub is always loaded
    engine.load(qml_dir / "Hub.qml")

    if enabled.get("weather", True):
        engine.load(qml_dir / "Weather.qml")

    if enabled.get("media", True):
        engine.load(qml_dir / "Media.qml")

    if enabled.get("general_settings", True):
        engine.load(qml_dir / "GeneralSettings.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
