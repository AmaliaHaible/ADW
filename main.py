import os
import sys
from pathlib import Path

# Set Qt Quick Controls style before creating QApplication
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

from widgets import HubBackend


def main():
    # QApplication is required for QSystemTrayIcon
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)

    engine = QQmlApplicationEngine()
    engine.quit.connect(app.quit)

    qml_dir = Path(__file__).parent / "qml"
    icons_dir = Path(__file__).parent / "icons"
    engine.addImportPath(qml_dir)

    # Pass icons directory as a context property
    engine.rootContext().setContextProperty("iconsPath", QUrl.fromLocalFile(str(icons_dir) + "/"))

    # Set up hub backend
    hub = HubBackend()
    engine.rootContext().setContextProperty("hubBackend", hub)

    # Set up system tray
    hub.setup_tray(app)

    # Connect exit signal
    hub.exitRequested.connect(app.quit)

    # Load QML files
    hub_qml = qml_dir / "Hub.qml"
    weather_qml = qml_dir / "Weather.qml"

    engine.load(hub_qml)
    engine.load(weather_qml)

    if not engine.rootObjects():
        sys.exit(-1)

    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
