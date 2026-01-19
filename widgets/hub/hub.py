from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QIcon, QAction
from PySide6.QtWidgets import QSystemTrayIcon, QMenu


class HubBackend(QObject):
    weatherVisibleChanged = Signal(bool)
    mediaVisibleChanged = Signal(bool)
    themeVisibleChanged = Signal(bool)
    editModeChanged = Signal(bool)
    alwaysOnTopChanged = Signal(bool)
    hubVisibleChanged = Signal(bool)
    showHubRequested = Signal()
    exitRequested = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._edit_mode = False
        self._tray_icon = None
        self._tray_menu = None
        self._hub_visible = True  # Hub starts visible by default

        # Load initial visibility states from settings
        if self._settings:
            self._weather_visible = self._settings.getWidgetVisible("weather")
            self._media_visible = self._settings.getWidgetVisible("media")
            self._theme_visible = self._settings.getWidgetVisible("theme")
            # Load always on top setting
            self._always_on_top = self._settings.getWidgetSetting("hub", "always_on_top") or False
        else:
            self._weather_visible = False
            self._media_visible = False
            self._theme_visible = False
            self._always_on_top = False

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

    # Weather visibility
    @Property(bool, notify=weatherVisibleChanged)
    def weatherVisible(self):
        return self._weather_visible

    @weatherVisible.setter
    def weatherVisible(self, value):
        if self._weather_visible != value:
            self._weather_visible = value
            if self._settings:
                self._settings.setWidgetVisible("weather", value)
            self.weatherVisibleChanged.emit(value)

    @Slot(bool)
    def setWeatherVisible(self, visible):
        """Set weather widget visibility."""
        self.weatherVisible = visible

    # Media visibility
    @Property(bool, notify=mediaVisibleChanged)
    def mediaVisible(self):
        return self._media_visible

    @mediaVisible.setter
    def mediaVisible(self, value):
        if self._media_visible != value:
            self._media_visible = value
            if self._settings:
                self._settings.setWidgetVisible("media", value)
            self.mediaVisibleChanged.emit(value)

    @Slot(bool)
    def setMediaVisible(self, visible):
        """Set media widget visibility."""
        self.mediaVisible = visible

    # Theme widget visibility
    @Property(bool, notify=themeVisibleChanged)
    def themeVisible(self):
        return self._theme_visible

    @themeVisible.setter
    def themeVisible(self, value):
        if self._theme_visible != value:
            self._theme_visible = value
            if self._settings:
                self._settings.setWidgetVisible("theme", value)
            self.themeVisibleChanged.emit(value)

    @Slot(bool)
    def setThemeVisible(self, visible):
        """Set theme widget visibility."""
        self.themeVisible = visible

    # Edit mode
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

    # Always on top
    @Property(bool, notify=alwaysOnTopChanged)
    def alwaysOnTop(self):
        return self._always_on_top

    @alwaysOnTop.setter
    def alwaysOnTop(self, value):
        if self._always_on_top != value:
            self._always_on_top = value
            if self._settings:
                self._settings.setWidgetSetting("hub", "always_on_top", value)
            self.alwaysOnTopChanged.emit(value)

    @Slot(bool)
    def setAlwaysOnTop(self, enabled):
        """Set always on top mode for widgets."""
        self.alwaysOnTop = enabled

    # Hub visibility
    @Property(bool, notify=hubVisibleChanged)
    def hubVisible(self):
        return self._hub_visible

    @hubVisible.setter
    def hubVisible(self, value):
        if self._hub_visible != value:
            self._hub_visible = value
            self.hubVisibleChanged.emit(value)

    @Slot(bool)
    def setHubVisible(self, visible):
        """Set hub window visibility state."""
        self.hubVisible = visible

    @Slot()
    def minimizeToTray(self):
        """Minimize the hub to the system tray."""
        pass

    @Slot()
    def showHub(self):
        """Request to show the hub window."""
        self.showHubRequested.emit()

    @Slot()
    def exitApp(self):
        """Request to exit the application."""
        self.exitRequested.emit()
