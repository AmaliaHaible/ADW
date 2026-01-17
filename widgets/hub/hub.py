from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QIcon, QAction
from PySide6.QtWidgets import QSystemTrayIcon, QMenu


class HubBackend(QObject):
    weatherVisibleChanged = Signal(bool)
    editModeChanged = Signal(bool)
    showHubRequested = Signal()
    exitRequested = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._weather_visible = False
        self._edit_mode = False
        self._tray_icon = None
        self._tray_menu = None

    def setup_tray(self, app):
        """Set up the system tray icon and menu."""
        icons_dir = Path(__file__).parent.parent.parent / "icons"
        icon_path = icons_dir / "sun.svg"

        self._tray_icon = QSystemTrayIcon(QIcon(str(icon_path)), app)

        # Create context menu
        self._tray_menu = QMenu()

        show_action = QAction("Show Hub", self._tray_menu)
        show_action.triggered.connect(self._on_show_hub)
        self._tray_menu.addAction(show_action)

        self._tray_menu.addSeparator()

        exit_action = QAction("Exit", self._tray_menu)
        exit_action.triggered.connect(self._on_exit)
        self._tray_menu.addAction(exit_action)

        self._tray_icon.setContextMenu(self._tray_menu)
        self._tray_icon.activated.connect(self._on_tray_activated)
        self._tray_icon.show()

    def _on_tray_activated(self, reason):
        """Handle tray icon activation (double-click to show)."""
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            self._on_show_hub()

    def _on_show_hub(self):
        """Emit signal to show the hub window."""
        self.showHubRequested.emit()

    def _on_exit(self):
        """Emit signal to exit the application."""
        self.exitRequested.emit()

    @Property(bool, notify=weatherVisibleChanged)
    def weatherVisible(self):
        return self._weather_visible

    @weatherVisible.setter
    def weatherVisible(self, value):
        if self._weather_visible != value:
            self._weather_visible = value
            self.weatherVisibleChanged.emit(value)

    @Slot()
    def minimizeToTray(self):
        """Minimize the hub to the system tray."""
        # This is called from QML; the actual hiding is handled in QML
        pass

    @Slot()
    def showHub(self):
        """Request to show the hub window."""
        self.showHubRequested.emit()

    @Slot()
    def exitApp(self):
        """Request to exit the application."""
        self.exitRequested.emit()

    @Slot(bool)
    def setWeatherVisible(self, visible):
        """Set weather widget visibility."""
        self.weatherVisible = visible

    @Property(bool, notify=editModeChanged)
    def editMode(self):
        return self._edit_mode

    @editMode.setter
    def editMode(self, value):
        if self._edit_mode != value:
            self._edit_mode = value
            self.editModeChanged.emit(value)

    @Slot(bool)
    def setEditMode(self, enabled):
        """Set edit mode (allows moving/resizing windows)."""
        self.editMode = enabled
