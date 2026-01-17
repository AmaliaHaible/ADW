import json
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QColor


DEFAULT_SETTINGS = {
    "widgets": {
        "hub": {
            "visible": True,
            "x": 100,
            "y": 100,
            "width": 300,
            "height": 250
        },
        "weather": {
            "visible": False,
            "x": 420,
            "y": 100,
            "width": 250,
            "height": 180
        },
        "theme": {
            "visible": False,
            "x": 100,
            "y": 370,
            "width": 320,
            "height": 450
        }
    },
    "theme": {
        "baseColor": "#9cbfd7",
        "windowBackground": "#1e1e2e",
        "surfaceColor": "#313244",
        "titleBarBackground": "#181825",
        "titleBarText": "#cdd6f4",
        "titleBarButtonHover": "#45475a",
        "titleBarButtonPressed": "#585b70",
        "accentColor": "#89b4fa",
        "accentHover": "#b4befe",
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
        "spacing": 8,
        "padding": 12
    }
}


class SettingsBackend(QObject):
    settingsChanged = Signal()
    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings_path = Path(__file__).parent.parent / "settings.json"
        self._settings = self._load_settings()

    def _load_settings(self) -> dict:
        """Load settings from JSON file or return defaults."""
        if self._settings_path.exists():
            try:
                with open(self._settings_path, "r") as f:
                    loaded = json.load(f)
                    # Merge with defaults to ensure all keys exist
                    return self._merge_defaults(loaded)
            except (json.JSONDecodeError, IOError):
                pass
        return DEFAULT_SETTINGS.copy()

    def _merge_defaults(self, loaded: dict) -> dict:
        """Merge loaded settings with defaults to ensure all keys exist."""
        result = DEFAULT_SETTINGS.copy()

        if "widgets" in loaded:
            for widget, props in loaded["widgets"].items():
                if widget in result["widgets"]:
                    result["widgets"][widget].update(props)
                else:
                    result["widgets"][widget] = props

        if "theme" in loaded:
            result["theme"].update(loaded["theme"])

        return result

    def _save_settings(self):
        """Save current settings to JSON file."""
        try:
            with open(self._settings_path, "w") as f:
                json.dump(self._settings, f, indent=2)
        except IOError as e:
            print(f"Error saving settings: {e}")

    # Widget position/size methods
    @Slot(str, result="QVariant")
    def getWidgetGeometry(self, widget_name: str) -> dict:
        """Get widget geometry (x, y, width, height)."""
        if widget_name in self._settings["widgets"]:
            w = self._settings["widgets"][widget_name]
            return {"x": w["x"], "y": w["y"], "width": w["width"], "height": w["height"]}
        return {"x": 100, "y": 100, "width": 300, "height": 200}

    @Slot(str, int, int, int, int)
    def setWidgetGeometry(self, widget_name: str, x: int, y: int, width: int, height: int):
        """Set widget geometry."""
        if widget_name not in self._settings["widgets"]:
            self._settings["widgets"][widget_name] = {"visible": False}
        self._settings["widgets"][widget_name].update({
            "x": x, "y": y, "width": width, "height": height
        })
        self._save_settings()
        self.settingsChanged.emit()

    @Slot(str, result=bool)
    def getWidgetVisible(self, widget_name: str) -> bool:
        """Get widget visibility."""
        if widget_name in self._settings["widgets"]:
            return self._settings["widgets"][widget_name].get("visible", False)
        return False

    @Slot(str, bool)
    def setWidgetVisible(self, widget_name: str, visible: bool):
        """Set widget visibility."""
        if widget_name not in self._settings["widgets"]:
            self._settings["widgets"][widget_name] = {"x": 100, "y": 100, "width": 300, "height": 200}
        self._settings["widgets"][widget_name]["visible"] = visible
        self._save_settings()
        self.settingsChanged.emit()

    # Theme methods
    @Slot(str, result=str)
    def getThemeColor(self, color_name: str) -> str:
        """Get a theme color value."""
        return self._settings["theme"].get(color_name, "#ffffff")

    @Slot(str, str)
    def setThemeColor(self, color_name: str, color_value: str):
        """Set a theme color value."""
        self._settings["theme"][color_name] = color_value
        self._save_settings()
        self.themeChanged.emit()

    @Slot(str, result=int)
    def getThemeInt(self, prop_name: str) -> int:
        """Get a theme integer value."""
        return self._settings["theme"].get(prop_name, 12)

    @Slot(str, int)
    def setThemeInt(self, prop_name: str, value: int):
        """Set a theme integer value."""
        self._settings["theme"][prop_name] = value
        self._save_settings()
        self.themeChanged.emit()

    @Slot(result="QVariant")
    def getFullTheme(self) -> dict:
        """Get the full theme dictionary."""
        return self._settings["theme"].copy()

    @Slot("QVariant")
    def setFullTheme(self, theme: dict):
        """Set the full theme dictionary."""
        self._settings["theme"].update(theme)
        self._save_settings()
        self.themeChanged.emit()

    @Slot()
    def resetThemeToDefaults(self):
        """Reset theme to default values."""
        self._settings["theme"] = DEFAULT_SETTINGS["theme"].copy()
        self._save_settings()
        self.themeChanged.emit()
