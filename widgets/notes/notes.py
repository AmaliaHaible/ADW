import uuid
from PySide6.QtCore import QObject, Property, Signal, Slot


class NotesBackend(QObject):
    """Backend for quick notes widget."""

    notesChanged = Signal()
    currentNoteChanged = Signal()
    searchQueryChanged = Signal()
    colorsChanged = Signal()

    def __init__(self, settings_backend=None, theme_provider=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._theme = theme_provider
        self._notes = []
        self._current_note_id = None
        self._search_query = ""
        self._newly_created_note_id = None
        self._load_notes()
        if self._theme:
            self._theme.themeChanged.connect(self._on_theme_changed)

    def _on_theme_changed(self):
        self.colorsChanged.emit()

    def _load_notes(self):
        """Load notes from settings."""
        if self._settings:
            data = self._settings.getWidgetSetting("notes", "notes")
            if data and isinstance(data, list):
                self._notes = data
            else:
                self._notes = []
            # Load last selected note
            last_id = self._settings.getWidgetSetting("notes", "current_note_id")
            if last_id and any(n.get("id") == last_id for n in self._notes):
                self._current_note_id = last_id
        else:
            self._notes = []

    def _save_notes(self):
        """Save notes to settings."""
        if self._settings:
            self._settings.setWidgetSetting("notes", "notes", self._notes)
            self._settings.setWidgetSetting(
                "notes", "current_note_id", self._current_note_id
            )
        self.notesChanged.emit()

    @Property("QVariantList", notify=notesChanged)
    def notes(self):
        """Return all notes, optionally filtered by search query."""
        if not self._search_query:
            return sorted(self._notes, key=lambda n: n.get("updated", 0), reverse=True)
        query = self._search_query.lower()
        filtered = [
            n
            for n in self._notes
            if query in n.get("title", "").lower()
            or query in n.get("content", "").lower()
        ]
        return sorted(filtered, key=lambda n: n.get("updated", 0), reverse=True)

    @Property(str, notify=currentNoteChanged)
    def currentNoteId(self):
        return self._current_note_id or ""

    @Property("QVariant", notify=currentNoteChanged)
    def currentNote(self):
        """Return the currently selected note."""
        if not self._current_note_id:
            return None
        return next(
            (n for n in self._notes if n.get("id") == self._current_note_id), None
        )

    @Property(str, notify=searchQueryChanged)
    def searchQuery(self):
        return self._search_query

    @Property("QVariantList", notify=colorsChanged)
    def availableColors(self):
        if self._settings:
            colors = self._settings.getWidgetSetting("notes", "colors")
            if colors and len(colors) > 0:
                return colors
        if self._theme:
            return [
                self._theme._theme.get("surfaceColor", "#313244"),
                self._theme._theme.get("colorRed", "#f38ba8"),
                self._theme._theme.get("colorOrange", "#fab387"),
                self._theme._theme.get("colorYellow", "#f9e2af"),
                self._theme._theme.get("colorGreen", "#a6e3a1"),
                self._theme._theme.get("colorBlue", "#89b4fa"),
                self._theme._theme.get("colorPurple", "#cba6f7"),
            ]
        return [
            "#313244",
            "#f38ba8",
            "#fab387",
            "#f9e2af",
            "#a6e3a1",
            "#89b4fa",
            "#cba6f7",
        ]

    @Slot(int, str)
    def setColor(self, index, color):
        if self._settings:
            colors = list(self.availableColors)
            if 0 <= index < len(colors):
                colors[index] = color
                self._settings.setWidgetSetting("notes", "colors", colors)
                self.colorsChanged.emit()

    @Slot(str)
    def setSearchQuery(self, query):
        """Set search filter."""
        if self._search_query != query:
            self._search_query = query
            self.searchQueryChanged.emit()
            self.notesChanged.emit()

    @Slot(result=str)
    def createNote(self):
        """Create a new note and return its ID."""
        import time

        note_id = str(uuid.uuid4())
        now = int(time.time())
        note = {
            "id": note_id,
            "title": "New Note",
            "content": "",
            "color": "#313244",
            "created": now,
            "updated": now,
        }
        self._notes.append(note)
        self._current_note_id = note_id
        self._newly_created_note_id = note_id
        self._save_notes()
        self.currentNoteChanged.emit()
        return note_id

    @Slot(str)
    def selectNote(self, note_id):
        """Select a note by ID."""
        if self._current_note_id != note_id:
            self._cleanup_empty_note()
            self._current_note_id = note_id
            if self._settings:
                self._settings.setWidgetSetting("notes", "current_note_id", note_id)
            self.currentNoteChanged.emit()

    def _cleanup_empty_note(self):
        if not self._newly_created_note_id:
            return
        if self._current_note_id != self._newly_created_note_id:
            self._newly_created_note_id = None
            return
        note = next(
            (n for n in self._notes if n.get("id") == self._newly_created_note_id), None
        )
        if note and note.get("title") == "New Note" and not note.get("content"):
            self._notes = [
                n for n in self._notes if n.get("id") != self._newly_created_note_id
            ]
            self.notesChanged.emit()
        self._newly_created_note_id = None

    @Slot(str, str)
    def updateNoteTitle(self, note_id, title):
        """Update note title."""
        import time

        note = next((n for n in self._notes if n.get("id") == note_id), None)
        if note:
            note["title"] = title
            note["updated"] = int(time.time())
            if note_id == self._newly_created_note_id and title != "New Note":
                self._newly_created_note_id = None
            self._save_notes()
            if note_id == self._current_note_id:
                self.currentNoteChanged.emit()

    @Slot(str, str)
    def updateNoteContent(self, note_id, content):
        """Update note content."""
        import time

        note = next((n for n in self._notes if n.get("id") == note_id), None)
        if note:
            note["content"] = content
            note["updated"] = int(time.time())
            if note_id == self._newly_created_note_id and content:
                self._newly_created_note_id = None
            self._save_notes()
            if note_id == self._current_note_id:
                self.currentNoteChanged.emit()

    @Slot(str, str)
    def updateNoteColor(self, note_id, color):
        """Update note color."""
        import time

        note = next((n for n in self._notes if n.get("id") == note_id), None)
        if note:
            note["color"] = color
            note["updated"] = int(time.time())
            self._save_notes()
            if note_id == self._current_note_id:
                self.currentNoteChanged.emit()

    @Slot(str)
    def deleteNote(self, note_id):
        """Delete a note."""
        self._notes = [n for n in self._notes if n.get("id") != note_id]
        if self._current_note_id == note_id:
            self._current_note_id = None
            self.currentNoteChanged.emit()
        self._save_notes()
