import copy
import json
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QColor

from .theme_constants import DEFAULT_THEME


DEFAULT_SETTINGS = {
    "widgets": {
        "hub": {"visible": True, "x": 100, "y": 100, "width": 300, "height": 250},
        "weather": {"visible": False, "x": 420, "y": 100, "width": 320, "height": 280},
        "media": {
            "visible": False,
            "x": 780,
            "y": 100,
            "width": 350,
            "height": 140,
            "max_sessions": 3,
            "anchor_top": True,
        },
        "theme": {"visible": False, "x": 100, "y": 370, "width": 320, "height": 450},
        "notes": {
            "colors": ["#313244", "#f38ba8", "#fab387", "#a6e3a1", "#89b4fa", "#cba6f7"]
        },
    },
    "hotkeys": {"always_on_top": "ctrl+alt+j"},
    "theme": DEFAULT_THEME,
}


class SettingsBackend(QObject):
    settingsChanged = Signal()

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
        return copy.deepcopy(DEFAULT_SETTINGS)

    def _merge_defaults(self, loaded: dict) -> dict:
        """Merge loaded settings with defaults to ensure all keys exist."""
        # Use deepcopy to avoid modifying the shared DEFAULT_THEME constant
        result = copy.deepcopy(DEFAULT_SETTINGS)

        if "widgets" in loaded:
            for widget, props in loaded["widgets"].items():
                if widget in result["widgets"]:
                    result["widgets"][widget].update(props)
                else:
                    result["widgets"][widget] = props

        if "hotkeys" in loaded:
            result["hotkeys"].update(loaded["hotkeys"])

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
            return {
                "x": w["x"],
                "y": w["y"],
                "width": w["width"],
                "height": w["height"],
            }
        return {"x": 100, "y": 100, "width": 300, "height": 200}

    @Slot(str, int, int, int, int)
    def setWidgetGeometry(
        self, widget_name: str, x: int, y: int, width: int, height: int
    ):
        """Set widget geometry."""
        if widget_name not in self._settings["widgets"]:
            self._settings["widgets"][widget_name] = {"visible": False}
        self._settings["widgets"][widget_name].update(
            {"x": x, "y": y, "width": width, "height": height}
        )
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
            self._settings["widgets"][widget_name] = {
                "x": 100,
                "y": 100,
                "width": 300,
                "height": 200,
            }
        self._settings["widgets"][widget_name]["visible"] = visible
        self._save_settings()
        self.settingsChanged.emit()

    @Slot(str, str, result="QVariant")
    def getWidgetSetting(self, widget_name: str, key: str):
        """Get a specific widget setting value."""
        return self._settings.get("widgets", {}).get(widget_name, {}).get(key)

    @Slot(str, str, "QVariant")
    def setWidgetSetting(self, widget_name: str, key: str, value):
        """Set a specific widget setting value."""
        if widget_name not in self._settings["widgets"]:
            self._settings["widgets"][widget_name] = {}
        self._settings["widgets"][widget_name][key] = value
        self._save_settings()
        self.settingsChanged.emit()

    # Hotkey settings methods
    def getHotkey(self, name: str) -> str:
        """Get a hotkey setting value."""
        return self._settings.get("hotkeys", {}).get(name, "")

    def setHotkey(self, name: str, value: str):
        """Set a hotkey setting value."""
        if "hotkeys" not in self._settings:
            self._settings["hotkeys"] = {}
        self._settings["hotkeys"][name] = value
        self._save_settings()
        self.settingsChanged.emit()
