from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

from .async_worker import MediaAsyncWorker


class MediaBackend(QObject):
    """Backend for media control widget."""

    # Property change signals
    titleChanged = Signal()
    artistChanged = Signal()
    albumArtPathChanged = Signal()
    playbackStateChanged = Signal()
    isPlayingChanged = Signal()
    positionChanged = Signal()
    durationChanged = Signal()
    positionTextChanged = Signal()
    durationTextChanged = Signal()
    canGoNextChanged = Signal()
    canGoPreviousChanged = Signal()
    canPlayPauseChanged = Signal()
    shuffleStateChanged = Signal()
    repeatStateChanged = Signal()
    sessionListChanged = Signal()
    currentSessionIndexChanged = Signal()
    hasSessionChanged = Signal()
    errorMessageChanged = Signal()
    isLoadingChanged = Signal()
    maxSessionsChanged = Signal()
    anchorTopChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)

        self._settings = settings_backend

        # Media state properties
        self._title = ""
        self._artist = ""
        self._album_art_path = ""
        self._playback_state = "Unknown"
        self._is_playing = False
        self._position = 0
        self._duration = 0
        self._can_go_next = False
        self._can_go_previous = False
        self._can_play_pause = False
        self._shuffle_state = "Unknown"
        self._repeat_state = "Unknown"

        # Session state
        self._session_list = []
        self._current_session_index = 0
        self._has_session = False

        # UI state
        self._error_message = ""
        self._is_loading = True

        # Settings
        if self._settings:
            self._max_sessions = self._settings.getWidgetSetting("media", "max_sessions") or 3
            self._anchor_top = self._settings.getWidgetSetting("media", "anchor_top")
            if self._anchor_top is None:
                self._anchor_top = True
        else:
            self._max_sessions = 3
            self._anchor_top = True

        # Position tracking
        self._local_position = 0
        self._position_sync_counter = 0

        # Assets directory
        self._assets_dir = Path(__file__).parent / "assets"
        self._default_cover = str((self._assets_dir / "default-cover.png").absolute())

        # Initialize async worker
        self._async_thread = MediaAsyncWorker(self._assets_dir)
        self._async_thread.mediaStateChanged.connect(self._on_media_state_changed)
        self._async_thread.sessionListChanged.connect(self._on_session_list_changed)
        self._async_thread.errorOccurred.connect(self._on_error_occurred)
        self._async_thread.start()

        # Position update timer (500ms when playing)
        self._position_timer = QTimer()
        self._position_timer.timeout.connect(self._update_local_position)
        self._position_timer.setInterval(500)

        # Session refresh timer (5 seconds)
        self._session_refresh_timer = QTimer()
        self._session_refresh_timer.timeout.connect(self.refreshSessions)
        self._session_refresh_timer.start(5000)

        # Initial loading state
        QTimer.singleShot(2000, lambda: self._set_loading(False))

    # Properties
    @Property(str, notify=titleChanged)
    def title(self):
        return self._title

    @Property(str, notify=artistChanged)
    def artist(self):
        return self._artist

    @Property(str, notify=albumArtPathChanged)
    def albumArtPath(self):
        return self._album_art_path or self._default_cover

    @Property(str, notify=playbackStateChanged)
    def playbackState(self):
        return self._playback_state

    @Property(bool, notify=isPlayingChanged)
    def isPlaying(self):
        return self._is_playing

    @Property(int, notify=positionChanged)
    def position(self):
        return self._local_position if self._is_playing else self._position

    @Property(int, notify=durationChanged)
    def duration(self):
        return self._duration

    @Property(str, notify=positionTextChanged)
    def positionText(self):
        pos = self._local_position if self._is_playing else self._position
        return self._format_time(pos)

    @Property(str, notify=durationTextChanged)
    def durationText(self):
        return self._format_time(self._duration)

    @Property(bool, notify=canGoNextChanged)
    def canGoNext(self):
        return self._can_go_next

    @Property(bool, notify=canGoPreviousChanged)
    def canGoPrevious(self):
        return self._can_go_previous

    @Property(bool, notify=canPlayPauseChanged)
    def canPlayPause(self):
        return self._can_play_pause

    @Property(str, notify=shuffleStateChanged)
    def shuffleState(self):
        return self._shuffle_state

    @Property(str, notify=repeatStateChanged)
    def repeatState(self):
        return self._repeat_state

    @Property(list, notify=sessionListChanged)
    def sessionList(self):
        return self._session_list

    @Property(int, notify=currentSessionIndexChanged)
    def currentSessionIndex(self):
        return self._current_session_index

    @Property(bool, notify=hasSessionChanged)
    def hasSession(self):
        return self._has_session

    @Property(str, notify=errorMessageChanged)
    def errorMessage(self):
        return self._error_message

    @Property(bool, notify=isLoadingChanged)
    def isLoading(self):
        return self._is_loading

    @Property(int, notify=maxSessionsChanged)
    def maxSessions(self):
        return self._max_sessions

    @Property(bool, notify=anchorTopChanged)
    def anchorTop(self):
        return self._anchor_top

    # Slots
    @Slot()
    def playPause(self):
        """Toggle play/pause."""
        if self._async_thread:
            self._async_thread.enqueue_command({"action": "play_pause"})

    @Slot()
    def next(self):
        """Skip to next track."""
        if self._async_thread:
            self._async_thread.enqueue_command({"action": "next"})

    @Slot()
    def previous(self):
        """Skip to previous track."""
        if self._async_thread:
            self._async_thread.enqueue_command({"action": "previous"})

    @Slot()
    def toggleShuffle(self):
        """Toggle shuffle mode."""
        # Not implemented - WinRT API may not support this
        pass

    @Slot()
    def cycleRepeat(self):
        """Cycle through repeat modes."""
        # Not implemented - WinRT API may not support this
        pass

    @Slot(int)
    def setPosition(self, seconds):
        """Seek to position in seconds."""
        self._local_position = seconds
        self.positionChanged.emit()
        self.positionTextChanged.emit()

        if self._async_thread:
            self._async_thread.enqueue_command({
                "action": "set_position",
                "position": seconds
            })

    @Slot(int)
    def switchSession(self, index):
        """Switch to a different media session."""
        if 0 <= index < len(self._session_list):
            self._current_session_index = index
            self.currentSessionIndexChanged.emit()

            if self._async_thread:
                self._async_thread.enqueue_command({
                    "action": "switch_session",
                    "index": index
                })

    @Slot()
    def refreshSessions(self):
        """Manually refresh session list."""
        if self._async_thread:
            self._async_thread.enqueue_command({"action": "refresh_sessions"})

    @Slot(int)
    def setMaxSessions(self, count):
        """Set maximum number of sessions to display."""
        if self._max_sessions != count:
            self._max_sessions = count
            if self._settings:
                self._settings.setWidgetSetting("media", "max_sessions", count)
            self.maxSessionsChanged.emit()

    @Slot(bool)
    def setAnchorTop(self, anchor_top):
        """Set whether to anchor top or bottom when resizing."""
        if self._anchor_top != anchor_top:
            self._anchor_top = anchor_top
            if self._settings:
                self._settings.setWidgetSetting("media", "anchor_top", anchor_top)
            self.anchorTopChanged.emit()

    # Internal slots
    @Slot(dict)
    def _on_media_state_changed(self, state):
        """Handle media state updates from async thread."""
        # Update has_session
        has_session = state.get("has_session", False)
        if self._has_session != has_session:
            self._has_session = has_session
            self.hasSessionChanged.emit()

        # Update title
        title = state.get("title", "")
        if self._title != title:
            self._title = title
            self.titleChanged.emit()

        # Update artist
        artist = state.get("artist", "")
        if self._artist != artist:
            self._artist = artist
            self.artistChanged.emit()

        # Update album art
        album_art = state.get("album_art_path", "")
        if self._album_art_path != album_art:
            self._album_art_path = album_art
            self.albumArtPathChanged.emit()

        # Update playback state
        playback_state = state.get("playback_state", "Unknown")
        if self._playback_state != playback_state:
            self._playback_state = playback_state
            self.playbackStateChanged.emit()

        # Update is_playing
        is_playing = state.get("is_playing", False)
        if self._is_playing != is_playing:
            self._is_playing = is_playing
            self.isPlayingChanged.emit()

            # Start/stop position timer
            if is_playing:
                self._local_position = state.get("position", 0)
                self._position_timer.start()
            else:
                self._position_timer.stop()

        # Update position (if not playing, use actual value)
        if not is_playing:
            position = state.get("position", 0)
            if self._position != position:
                self._position = position
                self._local_position = position
                self.positionChanged.emit()
                self.positionTextChanged.emit()

        # Resync position every 5 seconds when playing
        if is_playing:
            self._position_sync_counter += 1
            if self._position_sync_counter >= 10:  # ~5 seconds at 500ms intervals
                self._position = state.get("position", 0)
                self._local_position = self._position
                self._position_sync_counter = 0
                self.positionChanged.emit()
                self.positionTextChanged.emit()

        # Update duration
        duration = state.get("duration", 0)
        if self._duration != duration:
            self._duration = duration
            self.durationChanged.emit()
            self.durationTextChanged.emit()

        # Update controls
        can_go_next = state.get("can_go_next", False)
        if self._can_go_next != can_go_next:
            self._can_go_next = can_go_next
            self.canGoNextChanged.emit()

        can_go_previous = state.get("can_go_previous", False)
        if self._can_go_previous != can_go_previous:
            self._can_go_previous = can_go_previous
            self.canGoPreviousChanged.emit()

        can_play_pause = state.get("can_play_pause", False)
        if self._can_play_pause != can_play_pause:
            self._can_play_pause = can_play_pause
            self.canPlayPauseChanged.emit()

        # Update shuffle/repeat states
        shuffle_state = state.get("shuffle_state", "Unknown")
        if self._shuffle_state != shuffle_state:
            self._shuffle_state = shuffle_state
            self.shuffleStateChanged.emit()

        repeat_state = state.get("repeat_state", "Unknown")
        if self._repeat_state != repeat_state:
            self._repeat_state = repeat_state
            self.repeatStateChanged.emit()

    @Slot(list)
    def _on_session_list_changed(self, session_list):
        """Handle session list updates from async thread."""
        self._session_list = session_list
        self.sessionListChanged.emit()

    @Slot(str)
    def _on_error_occurred(self, error_msg):
        """Handle errors from async thread."""
        self._error_message = error_msg
        self.errorMessageChanged.emit()

        # Clear error after 5 seconds
        QTimer.singleShot(5000, lambda: self._clear_error())

    def _clear_error(self):
        """Clear error message."""
        self._error_message = ""
        self.errorMessageChanged.emit()

    def _set_loading(self, loading):
        """Set loading state."""
        if self._is_loading != loading:
            self._is_loading = loading
            self.isLoadingChanged.emit()

    def _update_local_position(self):
        """Increment local position counter (called by timer when playing)."""
        self._local_position += 0.5  # 500ms interval
        if self._local_position > self._duration and self._duration > 0:
            self._local_position = self._duration

        self.positionChanged.emit()
        self.positionTextChanged.emit()

    @staticmethod
    def _format_time(seconds: int) -> str:
        """Format seconds as M:SS."""
        if seconds < 0:
            seconds = 0

        minutes = int(seconds // 60)
        secs = int(seconds % 60)
        return f"{minutes}:{secs:02d}"

    def __del__(self):
        """Cleanup on deletion."""
        if hasattr(self, '_async_thread') and self._async_thread:
            self._async_thread.stop()
            self._async_thread.wait(1000)
