import json
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl
from PySide6.QtGui import QColor

from .theme_constants import DEFAULT_THEME


class ThemeProvider(QObject):
    themeChanged = Signal()

    # Color signals
    baseColorChanged = Signal()
    windowBackgroundChanged = Signal()
    surfaceColorChanged = Signal()
    titleBarBackgroundChanged = Signal()
    titleBarTextChanged = Signal()
    titleBarButtonHoverChanged = Signal()
    titleBarButtonPressedChanged = Signal()
    accentColorChanged = Signal()
    accentHoverChanged = Signal()
    accentInactiveChanged = Signal()
    textPrimaryChanged = Signal()
    textSecondaryChanged = Signal()
    textMutedChanged = Signal()
    textPrimaryDarkChanged = Signal()
    textSecondaryDarkChanged = Signal()
    borderColorChanged = Signal()
    successChanged = Signal()
    warningChanged = Signal()
    errorChanged = Signal()
    colorRedChanged = Signal()
    colorOrangeChanged = Signal()
    colorYellowChanged = Signal()
    colorGreenChanged = Signal()
    colorBlueChanged = Signal()
    colorPurpleChanged = Signal()

    # Int signals
    fontSizeSmallChanged = Signal()
    fontSizeNormalChanged = Signal()
    fontSizeLargeChanged = Signal()
    fontSizeTitleChanged = Signal()
    titleBarHeightChanged = Signal()
    buttonSizeChanged = Signal()
    borderRadiusChanged = Signal()
    windowRadiusChanged = Signal()
    spacingChanged = Signal()
    paddingChanged = Signal()
    textScrollSpeedChanged = Signal()

    def __init__(self, settings_path: Path, parent=None):
        super().__init__(parent)
        self._settings_path = settings_path
        self._theme = self._load_theme()

    def _load_theme(self) -> dict:
        """Load theme from settings file."""
        if self._settings_path.exists():
            try:
                with open(self._settings_path, "r") as f:
                    data = json.load(f)
                    if "theme" in data:
                        result = DEFAULT_THEME.copy()
                        result.update(data["theme"])
                        return result
            except (json.JSONDecodeError, IOError):
                pass
        return DEFAULT_THEME.copy()

    def _save_theme(self):
        """Save theme to settings file."""
        try:
            # Load existing settings
            data = {}
            if self._settings_path.exists():
                try:
                    with open(self._settings_path, "r") as f:
                        data = json.load(f)
                except (json.JSONDecodeError, IOError):
                    pass

            data["theme"] = self._theme

            with open(self._settings_path, "w") as f:
                json.dump(data, f, indent=2)
        except IOError as e:
            print(f"Error saving theme: {e}")

    def _emit_all_signals(self):
        """Emit all property change signals."""
        self.baseColorChanged.emit()
        self.windowBackgroundChanged.emit()
        self.surfaceColorChanged.emit()
        self.titleBarBackgroundChanged.emit()
        self.titleBarTextChanged.emit()
        self.titleBarButtonHoverChanged.emit()
        self.titleBarButtonPressedChanged.emit()
        self.accentColorChanged.emit()
        self.accentHoverChanged.emit()
        self.accentInactiveChanged.emit()
        self.textPrimaryChanged.emit()
        self.textSecondaryChanged.emit()
        self.textMutedChanged.emit()
        self.textPrimaryDarkChanged.emit()
        self.textSecondaryDarkChanged.emit()
        self.borderColorChanged.emit()
        self.successChanged.emit()
        self.warningChanged.emit()
        self.errorChanged.emit()
        self.colorRedChanged.emit()
        self.colorOrangeChanged.emit()
        self.colorYellowChanged.emit()
        self.colorGreenChanged.emit()
        self.colorBlueChanged.emit()
        self.colorPurpleChanged.emit()
        self.fontSizeSmallChanged.emit()
        self.fontSizeNormalChanged.emit()
        self.fontSizeLargeChanged.emit()
        self.fontSizeTitleChanged.emit()
        self.titleBarHeightChanged.emit()
        self.buttonSizeChanged.emit()
        self.borderRadiusChanged.emit()
        self.windowRadiusChanged.emit()
        self.spacingChanged.emit()
        self.paddingChanged.emit()
        self.textScrollSpeedChanged.emit()
        self.themeChanged.emit()

    # Color properties
    @Property(QColor, notify=baseColorChanged)
    def baseColor(self):
        return QColor(self._theme["baseColor"])

    @Property(QColor, notify=windowBackgroundChanged)
    def windowBackground(self):
        return QColor(self._theme["windowBackground"])

    @Property(QColor, notify=surfaceColorChanged)
    def surfaceColor(self):
        return QColor(self._theme["surfaceColor"])

    @Property(QColor, notify=titleBarBackgroundChanged)
    def titleBarBackground(self):
        return QColor(self._theme["titleBarBackground"])

    @Property(QColor, notify=titleBarTextChanged)
    def titleBarText(self):
        return QColor(self._theme["titleBarText"])

    @Property(QColor, notify=titleBarButtonHoverChanged)
    def titleBarButtonHover(self):
        return QColor(self._theme["titleBarButtonHover"])

    @Property(QColor, notify=titleBarButtonPressedChanged)
    def titleBarButtonPressed(self):
        return QColor(self._theme["titleBarButtonPressed"])

    @Property(QColor, notify=accentColorChanged)
    def accentColor(self):
        return QColor(self._theme["accentColor"])

    @Property(QColor, notify=accentHoverChanged)
    def accentHover(self):
        return QColor(self._theme["accentHover"])

    @Property(QColor, notify=accentInactiveChanged)
    def accentInactive(self):
        return QColor(self._theme["accentInactive"])

    @Property(QColor, notify=textPrimaryChanged)
    def textPrimary(self):
        return QColor(self._theme["textPrimary"])

    @Property(QColor, notify=textSecondaryChanged)
    def textSecondary(self):
        return QColor(self._theme["textSecondary"])

    @Property(QColor, notify=textMutedChanged)
    def textMuted(self):
        return QColor(self._theme["textMuted"])

    @Property(QColor, notify=textPrimaryDarkChanged)
    def textPrimaryDark(self):
        return QColor(self._theme.get("textPrimaryDark", "#1e1e2e"))

    @Property(QColor, notify=textSecondaryDarkChanged)
    def textSecondaryDark(self):
        return QColor(self._theme.get("textSecondaryDark", "#313244"))

    @Property(QColor, notify=borderColorChanged)
    def borderColor(self):
        return QColor(self._theme["borderColor"])

    @Property(QColor, notify=successChanged)
    def success(self):
        return QColor(self._theme["success"])

    @Property(QColor, notify=warningChanged)
    def warning(self):
        return QColor(self._theme["warning"])

    @Property(QColor, notify=errorChanged)
    def error(self):
        return QColor(self._theme["error"])

    @Property(QColor, notify=colorRedChanged)
    def colorRed(self):
        return QColor(self._theme.get("colorRed", "#f38ba8"))

    @Property(QColor, notify=colorOrangeChanged)
    def colorOrange(self):
        return QColor(self._theme.get("colorOrange", "#fab387"))

    @Property(QColor, notify=colorYellowChanged)
    def colorYellow(self):
        return QColor(self._theme.get("colorYellow", "#f9e2af"))

    @Property(QColor, notify=colorGreenChanged)
    def colorGreen(self):
        return QColor(self._theme.get("colorGreen", "#a6e3a1"))

    @Property(QColor, notify=colorBlueChanged)
    def colorBlue(self):
        return QColor(self._theme.get("colorBlue", "#89b4fa"))

    @Property(QColor, notify=colorPurpleChanged)
    def colorPurple(self):
        return QColor(self._theme.get("colorPurple", "#cba6f7"))

    # Int properties
    @Property(int, notify=fontSizeSmallChanged)
    def fontSizeSmall(self):
        return self._theme["fontSizeSmall"]

    @Property(int, notify=fontSizeNormalChanged)
    def fontSizeNormal(self):
        return self._theme["fontSizeNormal"]

    @Property(int, notify=fontSizeLargeChanged)
    def fontSizeLarge(self):
        return self._theme["fontSizeLarge"]

    @Property(int, notify=fontSizeTitleChanged)
    def fontSizeTitle(self):
        return self._theme["fontSizeTitle"]

    @Property(int, notify=titleBarHeightChanged)
    def titleBarHeight(self):
        return self._theme["titleBarHeight"]

    @Property(int, notify=buttonSizeChanged)
    def buttonSize(self):
        return self._theme["buttonSize"]

    @Property(int, notify=borderRadiusChanged)
    def borderRadius(self):
        return self._theme["borderRadius"]

    @Property(int, notify=windowRadiusChanged)
    def windowRadius(self):
        return self._theme["windowRadius"]

    @Property(int, notify=spacingChanged)
    def spacing(self):
        return self._theme["spacing"]

    @Property(int, notify=paddingChanged)
    def padding(self):
        return self._theme["padding"]

    @Property(int, notify=textScrollSpeedChanged)
    def textScrollSpeed(self):
        return self._theme["textScrollSpeed"]

    # Setters
    @Slot(str, str)
    def setColor(self, name: str, value: str):
        """Set a color value by name."""
        if name in self._theme:
            self._theme[name] = value
            self._save_theme()
            # Emit specific signal
            signal = getattr(self, f"{name}Changed", None)
            if signal:
                signal.emit()
            self.themeChanged.emit()

    @Slot(str, int)
    def setInt(self, name: str, value: int):
        """Set an integer value by name."""
        if name in self._theme:
            self._theme[name] = value
            self._save_theme()
            signal = getattr(self, f"{name}Changed", None)
            if signal:
                signal.emit()
            self.themeChanged.emit()

    @Slot()
    def resetToDefaults(self):
        """Reset all theme values to defaults."""
        self._theme = DEFAULT_THEME.copy()
        self._save_theme()
        self._emit_all_signals()

    @Slot(str)
    def resetValue(self, name: str):
        """Reset a single theme value to default."""
        if name in DEFAULT_THEME:
            self._theme[name] = DEFAULT_THEME[name]
            self._save_theme()
            signal = getattr(self, f"{name}Changed", None)
            if signal:
                signal.emit()
            self.themeChanged.emit()

    @Slot(str)
    def saveThemeToPath(self, path: str):
        """Save the current theme to a JSON file."""
        file_path = self._normalize_path(path)
        if not file_path:
            return
        try:
            with open(file_path, "w") as f:
                json.dump(self._theme, f, indent=2)
        except IOError as e:
            print(f"Error saving theme to {file_path}: {e}")

    @Slot(str)
    def loadThemeFromPath(self, path: str):
        """Load a theme from a JSON file."""
        file_path = self._normalize_path(path)
        if not file_path:
            return
        try:
            with open(file_path, "r") as f:
                data = json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error loading theme from {file_path}: {e}")
            return

        if not isinstance(data, dict):
            return

        updated = DEFAULT_THEME.copy()
        updated.update(data)
        self._theme = updated
        self._save_theme()
        self._emit_all_signals()

    def _normalize_path(self, path: str) -> str:
        """Normalize file paths coming from QML."""
        if not path:
            return ""
        url = QUrl(path)
        if url.isValid() and url.scheme() == "file":
            return url.toLocalFile()
        return path

    @Slot(result="QVariant")
    def getAllColors(self):
        """Get all color names and values."""
        colors = {}
        for key, value in self._theme.items():
            if isinstance(value, str) and value.startswith("#"):
                colors[key] = value
        return colors

    @Slot(result="QVariant")
    def getAllInts(self):
        """Get all integer property names and values."""
        ints = {}
        for key, value in self._theme.items():
            if isinstance(value, int):
                ints[key] = value
        return ints
