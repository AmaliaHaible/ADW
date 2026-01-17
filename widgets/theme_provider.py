import json
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QColor


DEFAULT_THEME = {
    "baseColor": "#9cbfd7",
    "windowBackground": "#1e1e2e",
    "surfaceColor": "#313244",
    "titleBarBackground": "#181825",
    "titleBarText": "#cdd6f4",
    "titleBarButtonHover": "#45475a",
    "titleBarButtonPressed": "#585b70",
    "accentColor": "#89b4fa",
    "accentHover": "#b4befe",
    "accentInactive": "#45475a",
    "textPrimary": "#cdd6f4",
    "textSecondary": "#a6adc8",
    "textMuted": "#6c7086",
    "success": "#a6e3a1",
    "warning": "#f9e2af",
    "error": "#f38ba8",
    "fontSizeSmall": 11,
    "fontSizeNormal": 13,
    "fontSizeLarge": 16,
    "fontSizeTitle": 14,
    "titleBarHeight": 32,
    "buttonSize": 24,
    "borderRadius": 8,
    "windowRadius": 12,
    "spacing": 8,
    "padding": 12
}


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
    successChanged = Signal()
    warningChanged = Signal()
    errorChanged = Signal()

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
        self.successChanged.emit()
        self.warningChanged.emit()
        self.errorChanged.emit()
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

    @Property(QColor, notify=successChanged)
    def success(self):
        return QColor(self._theme["success"])

    @Property(QColor, notify=warningChanged)
    def warning(self):
        return QColor(self._theme["warning"])

    @Property(QColor, notify=errorChanged)
    def error(self):
        return QColor(self._theme["error"])

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
