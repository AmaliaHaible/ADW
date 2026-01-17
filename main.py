import os
import sys
from pathlib import Path

# Set Qt Quick Controls style before creating QApplication
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

from widgets import HubBackend, SettingsBackend, ThemeProvider


def main():
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

    # Set up hub backend (with settings for persistence)
    hub = HubBackend(settings_backend=settings)
    engine.rootContext().setContextProperty("hubBackend", hub)

    # Set up system tray
    hub.setup_tray(app)

    # Connect exit signal
    hub.exitRequested.connect(app.quit)

    # Load QML files
    hub_qml = qml_dir / "Hub.qml"
    weather_qml = qml_dir / "Weather.qml"
    theme_qml = qml_dir / "ThemeEditor.qml"

    engine.load(hub_qml)
    engine.load(weather_qml)
    engine.load(theme_qml)

    if not engine.rootObjects():
        sys.exit(-1)

    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
