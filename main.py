import sys
from pathlib import Path

from PySide6.QtCore import QStringListModel
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# Example from my last project
#from widgets import WeatherBackend

def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    engine.quit.connect(app.quit)
    qml_dir = Path(__file__).parent / "qml/"

    # set this as soon as you know the project layout
    # qml_file = qml_dir / "Weather.qml"
    
    engine.addImportPath(qml_dir)

    # Example from my last project
    # weather = WeatherBackend()
    # engine.rootContext().setContextProperty("weatherBackend", weather)
    
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)
    
    c = app.exec()
    print(f"Quitting with exit code {c}")
    sys.exit(c)


if __name__ == "__main__":
    main()
