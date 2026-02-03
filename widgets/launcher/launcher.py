import os
import subprocess
import uuid
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot

from .icon_extractor import get_icon_url, get_lnk_info


class LauncherBackend(QObject):
    """Backend for quick launcher widget."""

    shortcutsChanged = Signal()
    searchQueryChanged = Signal()
    columnsChanged = Signal()
    showSearchBarChanged = Signal()
    iconSizeChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._shortcuts = []
        self._search_query = ""
        self._load_shortcuts()

    @Property(int, notify=columnsChanged)
    def columns(self):
        if self._settings:
            val = self._settings.getWidgetSetting("launcher", "columns")
            if val is not None:
                return val
        return 3

    @Slot(int)
    def setColumns(self, value):
        if self._settings and 1 <= value <= 8:
            self._settings.setWidgetSetting("launcher", "columns", value)
            self.columnsChanged.emit()

    @Property(bool, notify=showSearchBarChanged)
    def showSearchBar(self):
        if self._settings:
            val = self._settings.getWidgetSetting("launcher", "showSearchBar")
            if val is not None:
                return val
        return True

    @Slot(bool)
    def setShowSearchBar(self, value):
        if self._settings:
            self._settings.setWidgetSetting("launcher", "showSearchBar", value)
            self.showSearchBarChanged.emit()

    @Property(int, notify=iconSizeChanged)
    def iconSize(self):
        if self._settings:
            val = self._settings.getWidgetSetting("launcher", "iconSize")
            if val is not None:
                return val
        return 28

    @Slot(int)
    def setIconSize(self, value):
        if self._settings and 16 <= value <= 64:
            self._settings.setWidgetSetting("launcher", "iconSize", value)
            self.iconSizeChanged.emit()

    def _load_shortcuts(self):
        """Load shortcuts from settings."""
        if self._settings:
            data = self._settings.getWidgetSetting("launcher", "shortcuts")
            if data and isinstance(data, list):
                self._shortcuts = data
            else:
                self._shortcuts = []
        else:
            self._shortcuts = []

    def _save_shortcuts(self):
        """Save shortcuts to settings."""
        if self._settings:
            self._settings.setWidgetSetting("launcher", "shortcuts", self._shortcuts)
        self.shortcutsChanged.emit()

    @Property("QVariantList", notify=shortcutsChanged)
    def shortcuts(self):
        """Return shortcuts, optionally filtered by search."""
        if not self._search_query:
            return self._shortcuts
        query = self._search_query.lower()
        return [s for s in self._shortcuts if query in s.get("name", "").lower()]

    @Property(str, notify=searchQueryChanged)
    def searchQuery(self):
        return self._search_query

    @Slot(str)
    def setSearchQuery(self, query):
        """Set search filter."""
        if self._search_query != query:
            self._search_query = query
            self.searchQueryChanged.emit()
            self.shortcutsChanged.emit()

    @Slot(str, str, str, bool, str, str)
    def addShortcut(
        self,
        name,
        path,
        icon="",
        use_custom_icon=False,
        custom_image="",
        working_dir="",
    ):
        extracted_url = get_icon_url(path)

        if Path(path).suffix.lower() == ".lnk" and not working_dir:
            lnk_info = get_lnk_info(path)
            if lnk_info.get("workingDir"):
                working_dir = lnk_info["workingDir"]

        shortcut = {
            "id": str(uuid.uuid4()),
            "name": name,
            "path": path,
            "icon": icon or self._get_default_icon(path),
            "extractedIcon": extracted_url,
            "useCustomIcon": use_custom_icon,
            "customImagePath": custom_image,
            "workingDir": working_dir,
        }
        self._shortcuts.append(shortcut)
        self._save_shortcuts()

    @Slot(str)
    def removeShortcut(self, shortcut_id):
        """Remove a shortcut by ID."""
        self._shortcuts = [s for s in self._shortcuts if s.get("id") != shortcut_id]
        self._save_shortcuts()

    @Slot(str, str)
    def updateShortcutName(self, shortcut_id, name):
        """Update shortcut name."""
        for s in self._shortcuts:
            if s.get("id") == shortcut_id:
                s["name"] = name
                break
        self._save_shortcuts()

    @Slot(str, str, str, bool, str, str)
    def updateShortcut(
        self, shortcut_id, name, icon, use_custom_icon, custom_image="", working_dir=""
    ):
        for s in self._shortcuts:
            if s.get("id") == shortcut_id:
                s["name"] = name
                s["icon"] = icon
                s["useCustomIcon"] = use_custom_icon
                s["customImagePath"] = custom_image
                s["workingDir"] = working_dir
                break
        self._save_shortcuts()

    @Slot(str, int)
    def moveShortcut(self, shortcut_id, new_index):
        """Reorder shortcut to new index."""
        current_index = next(
            (i for i, s in enumerate(self._shortcuts) if s.get("id") == shortcut_id),
            None,
        )
        if current_index is None or new_index < 0 or new_index >= len(self._shortcuts):
            return
        shortcut = self._shortcuts.pop(current_index)
        self._shortcuts.insert(new_index, shortcut)
        self._save_shortcuts()

    @Slot(str)
    def launchShortcut(self, shortcut_id):
        shortcut = next(
            (s for s in self._shortcuts if s.get("id") == shortcut_id), None
        )
        if not shortcut:
            return

        path = shortcut.get("path", "")
        if not path:
            return

        working_dir = shortcut.get("workingDir", "")
        if not working_dir:
            path_obj = Path(path)
            if path_obj.suffix.lower() in (".exe", ".bat", ".cmd"):
                working_dir = str(path_obj.parent)

        try:
            if os.name == "nt":
                if working_dir and Path(working_dir).exists():
                    subprocess.Popen(
                        f'start "" "{path}"',
                        shell=True,
                        cwd=working_dir,
                    )
                else:
                    os.startfile(path)
            else:
                if working_dir and Path(working_dir).exists():
                    subprocess.Popen(["xdg-open", path], cwd=working_dir)
                else:
                    subprocess.Popen(["xdg-open", path])
        except Exception as e:
            print(f"Failed to launch {path}: {e}")

    @Slot(str, result=bool)
    def launchPath(self, path):
        """Launch a path directly (for drag-drop)."""
        if not path:
            return False

        try:
            if os.name == "nt":
                os.startfile(path)
            else:
                subprocess.Popen(["xdg-open", path])
            return True
        except Exception as e:
            print(f"Failed to launch {path}: {e}")
            return False

    def _get_default_icon(self, path):
        """Get default icon based on path type."""
        path_obj = Path(path)

        if path_obj.suffix.lower() == ".lnk":
            return "link.svg"
        elif path_obj.is_dir() if path_obj.exists() else False:
            return "folder.svg"
        elif path_obj.suffix.lower() in (".exe", ".bat", ".cmd"):
            return "terminal.svg"
        elif path_obj.suffix.lower() in (".url",):
            return "globe.svg"
        else:
            return "file.svg"

    @Slot(str, result=str)
    def getNameFromPath(self, path):
        """Extract a name from a file path."""
        path_obj = Path(path)
        return path_obj.stem

    @Slot(str, result=str)
    def getIconForPath(self, path):
        """Get appropriate icon for a file path."""
        return self._get_default_icon(path)

    @Slot(str, result=str)
    def getExtractedIconUrl(self, path):
        """Get extracted icon URL from exe/lnk file, or empty if not available."""
        return get_icon_url(path)

    @Slot(result=str)
    def getDesktopPath(self):
        """Get the user's desktop path."""
        if os.name == "nt":
            return os.path.join(os.environ.get("USERPROFILE", ""), "Desktop")
        return os.path.expanduser("~/Desktop")
