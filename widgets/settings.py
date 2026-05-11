import copy
import json
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot

DEFAULT_LAYOUT = {
    "widgets": {
        "hub": {"visible": True, "x": 100, "y": 100, "width": 300, "height": 250},
        "weather": {"visible": False, "x": 420, "y": 100, "width": 320, "height": 280},
        "media": {"visible": False, "x": 780, "y": 100, "width": 350, "height": 140},
        "theme": {"visible": False, "x": 100, "y": 370, "width": 320, "height": 450},
        "notes": {"visible": False, "x": 100, "y": 700, "width": 300, "height": 400},
    },
    "hotkeys": {"always_on_top": "ctrl+alt+j"},
}

DEFAULT_WIDGET_CONFIGS: dict[str, dict] = {
    "media": {"max_sessions": 3, "anchor_top": True},
    "notes": {"colors": []},
}

GEOMETRY_KEYS = {"x", "y", "width", "height", "visible"}


class SettingsBackend(QObject):
    settingsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data_dir = Path(__file__).parent.parent / "data"
        self._widgets_dir = self._data_dir / "widgets"
        self._layout = self._load_layout()
        self._widget_configs: dict[str, dict] = {}
        self._load_all_widget_configs()

    # ── Layout I/O ──────────────────────────────────────────────────

    def _load_layout(self) -> dict:
        """Load layout.json, merging with defaults."""
        self._data_dir.mkdir(parents=True, exist_ok=True)
        path = self._data_dir / "layout.json"
        if path.exists():
            try:
                with open(path) as f:
                    loaded = json.load(f)
                return self._merge_layout_defaults(loaded)
            except (json.JSONDecodeError, IOError):
                pass
        result = copy.deepcopy(DEFAULT_LAYOUT)
        self._save_json(path, result)
        return result

    def _merge_layout_defaults(self, loaded: dict) -> dict:
        result = copy.deepcopy(DEFAULT_LAYOUT)
        if "widgets" in loaded:
            for widget, props in loaded["widgets"].items():
                if widget in result["widgets"]:
                    result["widgets"][widget].update(props)
                else:
                    result["widgets"][widget] = props
        if "hotkeys" in loaded:
            result["hotkeys"].update(loaded["hotkeys"])
        return result

    def _save_layout(self):
        self._save_json(self._data_dir / "layout.json", self._layout)

    # ── Per-widget config I/O ───────────────────────────────────────

    def _load_all_widget_configs(self):
        """Load all per-widget config files from data/widgets/."""
        self._widgets_dir.mkdir(parents=True, exist_ok=True)
        for path in self._widgets_dir.glob("*.json"):
            name = path.stem
            if name in ("layout", "theme"):
                continue
            self._widget_configs[name] = self._load_widget_config(name)

    def _load_widget_config(self, widget_name: str) -> dict:
        """Load a single widget config file, applying defaults."""
        defaults = DEFAULT_WIDGET_CONFIGS.get(widget_name, {})
        path = self._widgets_dir / f"{widget_name}.json"
        if path.exists():
            try:
                with open(path) as f:
                    loaded = json.load(f)
                result = copy.deepcopy(defaults)
                result.update(loaded)
                return result
            except (json.JSONDecodeError, IOError):
                pass
        result = copy.deepcopy(defaults)
        self._save_json(path, result)
        return result

    def _save_widget_config(self, widget_name: str):
        path = self._widgets_dir / f"{widget_name}.json"
        self._save_json(path, self._widget_configs.get(widget_name, {}))

    # ── Generic JSON helper ─────────────────────────────────────────

    @staticmethod
    def _save_json(path: Path, data: dict):
        try:
            with open(path, "w") as f:
                json.dump(data, f, indent=2)
        except IOError as e:
            print(f"Error saving {path}: {e}")

    # ── Public API: Widget geometry ─────────────────────────────────

    @Slot(str, result="QVariant")
    def getWidgetGeometry(self, widget_name: str) -> dict:
        """Get widget geometry (x, y, width, height)."""
        if widget_name in self._layout["widgets"]:
            w = self._layout["widgets"][widget_name]
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
        if widget_name not in self._layout["widgets"]:
            self._layout["widgets"][widget_name] = {"visible": False}
        self._layout["widgets"][widget_name].update(
            {"x": x, "y": y, "width": width, "height": height}
        )
        self._save_layout()
        self.settingsChanged.emit()

    # ── Public API: Widget visibility ──────────────────────────────

    @Slot(str, result=bool)
    def getWidgetVisible(self, widget_name: str) -> bool:
        """Get widget visibility."""
        if widget_name in self._layout["widgets"]:
            return self._layout["widgets"][widget_name].get("visible", False)
        return False

    @Slot(str, bool)
    def setWidgetVisible(self, widget_name: str, visible: bool):
        """Set widget visibility."""
        if widget_name not in self._layout["widgets"]:
            self._layout["widgets"][widget_name] = {
                "x": 100,
                "y": 100,
                "width": 300,
                "height": 200,
            }
        self._layout["widgets"][widget_name]["visible"] = visible
        self._save_layout()
        self.settingsChanged.emit()

    # ── Public API: Per-widget settings ────────────────────────────

    @Slot(str, str, result="QVariant")
    def getWidgetSetting(self, widget_name: str, key: str):
        """Get a specific widget setting value."""
        if widget_name not in self._widget_configs:
            self._widget_configs[widget_name] = self._load_widget_config(widget_name)
        return self._widget_configs[widget_name].get(key)

    @Slot(str, str, "QVariant")
    def setWidgetSetting(self, widget_name: str, key: str, value):
        """Set a specific widget setting value."""
        if widget_name not in self._widget_configs:
            self._widget_configs[widget_name] = self._load_widget_config(widget_name)
        self._widget_configs[widget_name][key] = value
        self._save_widget_config(widget_name)
        self.settingsChanged.emit()

    # ── Public API: Hotkeys ────────────────────────────────────────

    def getHotkey(self, name: str) -> str:
        """Get a hotkey setting value."""
        return self._layout.get("hotkeys", {}).get(name, "")

    def setHotkey(self, name: str, value: str):
        """Set a hotkey setting value."""
        if "hotkeys" not in self._layout:
            self._layout["hotkeys"] = {}
        self._layout["hotkeys"][name] = value
        self._save_layout()
        self.settingsChanged.emit()
