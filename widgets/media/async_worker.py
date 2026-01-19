import asyncio
import hashlib
from pathlib import Path
from queue import Queue, Empty
from typing import Dict, Any

from PySide6.QtCore import QThread, Signal

try:
    from winrt.windows.media.control import (
        GlobalSystemMediaTransportControlsSessionManager as MediaManager,
    )
    WINRT_AVAILABLE = True
except ImportError:
    WINRT_AVAILABLE = False
    MediaManager = None


class MediaAsyncWorker(QThread):
    """Async worker thread for WinRT media control integration."""

    # Signals to communicate with Qt main thread
    mediaStateChanged = Signal(dict)
    sessionListChanged = Signal(list)
    errorOccurred = Signal(str)

    def __init__(self, assets_dir: Path, parent=None):
        super().__init__(parent)
        self._assets_dir = assets_dir
        self._temp_dir = assets_dir / "temp"
        self._temp_dir.mkdir(parents=True, exist_ok=True)

        self._command_queue = Queue()
        self._loop = None
        self._manager = None
        self._current_session = None
        self._sessions = []
        self._stop_requested = False

        # Album art cache (LRU with max 10 items)
        self._album_art_cache = {}  # {hash: (path, timestamp)}
        self._max_cache_size = 10

        # Position tracking
        self._last_position = 0
        self._last_position_timestamp = 0

    def enqueue_command(self, cmd: Dict[str, Any]):
        """Thread-safe command enqueuing from Qt main thread."""
        self._command_queue.put(cmd)

    def stop(self):
        """Request the worker thread to stop."""
        self._stop_requested = True

    def run(self):
        """Thread entry point - runs asyncio event loop."""
        if not WINRT_AVAILABLE:
            self._emit_to_qt("errorOccurred", "WinRT not available on this system")
            return

        try:
            self._loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self._loop)
            self._loop.run_until_complete(self._async_main())
        except Exception as e:
            self._emit_to_qt("errorOccurred", f"Worker thread error: {str(e)}")
        finally:
            if self._loop:
                self._loop.close()

    async def _async_main(self):
        """Main async loop."""
        try:
            # Initialize WinRT MediaManager
            self._manager = await MediaManager.request_async()

            # Set up event listeners
            self._manager.add_current_session_changed(self._on_current_session_changed)
            self._manager.add_sessions_changed(self._on_sessions_changed)

            # Initial session discovery
            await self._update_sessions()
            await self._switch_to_current_session()

        except Exception as e:
            self._emit_to_qt("errorOccurred", f"Failed to initialize media manager: {str(e)}")
            return

        # Main event loop
        while not self._stop_requested:
            # Process command queue
            try:
                cmd = self._command_queue.get_nowait()
                await self._handle_command(cmd)
            except Empty:
                pass

            # Periodic state refresh (every second)
            await self._refresh_state()

            await asyncio.sleep(1)

    async def _handle_command(self, cmd: Dict[str, Any]):
        """Handle commands from Qt main thread."""
        action = cmd.get("action")

        if not self._current_session:
            return

        try:
            if action == "play_pause":
                await self._current_session.try_toggle_play_pause_async()
            elif action == "next":
                await self._current_session.try_skip_next_async()
            elif action == "previous":
                await self._current_session.try_skip_previous_async()
            elif action == "set_position":
                # Position seeking - WinRT API may not support this directly
                # We'll just update our local state for now
                pass
            elif action == "switch_session":
                index = cmd.get("index", 0)
                if 0 <= index < len(self._sessions):
                    await self._switch_to_session(self._sessions[index])
            elif action == "refresh_sessions":
                await self._update_sessions()
        except Exception as e:
            self._emit_to_qt("errorOccurred", f"Command failed: {str(e)}")

    def _on_current_session_changed(self, manager, args):
        """Event handler for current session changes."""
        if self._loop and not self._stop_requested:
            asyncio.run_coroutine_threadsafe(
                self._switch_to_current_session(),
                self._loop
            )

    def _on_sessions_changed(self, manager, args):
        """Event handler for session list changes."""
        if self._loop and not self._stop_requested:
            asyncio.run_coroutine_threadsafe(
                self._update_sessions(),
                self._loop
            )

    async def _switch_to_current_session(self):
        """Switch to the system's current media session."""
        try:
            session = self._manager.get_current_session()
            await self._switch_to_session(session)
        except Exception:
            # No current session is fine
            await self._switch_to_session(None)

    async def _switch_to_session(self, session):
        """Switch to a specific session."""
        # Unregister old session listeners
        if self._current_session:
            try:
                self._current_session.remove_playback_info_changed(self._on_playback_changed)
                self._current_session.remove_media_properties_changed(self._on_media_properties_changed)
            except Exception:
                pass

        self._current_session = session

        # Register new session listeners
        if self._current_session:
            try:
                self._current_session.add_playback_info_changed(self._on_playback_changed)
                self._current_session.add_media_properties_changed(self._on_media_properties_changed)
            except Exception as e:
                self._emit_to_qt("errorOccurred", f"Failed to register listeners: {str(e)}")

        # Refresh state immediately
        await self._refresh_state()

    async def _update_sessions(self):
        """Update the list of available media sessions."""
        try:
            sessions = self._manager.get_sessions()
            self._sessions = list(sessions) if sessions else []

            # Build session list for Qt with full metadata for each session
            session_list = []
            for i, session in enumerate(self._sessions):
                title = ""
                artist = ""
                album_art_path = str(self._assets_dir / "default-cover.png")

                try:
                    # Get media properties for this session
                    info = await session.try_get_media_properties_async()
                    if info:
                        title = info.title if info.title else f"Session {i+1}"
                        artist = info.artist if info.artist else ""

                        # Get album art for this session
                        if info.thumbnail:
                            album_art_path = await self._get_album_art(info)
                except Exception:
                    title = f"Session {i+1}"

                # Get playback info for this session
                try:
                    playback_info = session.get_playback_info()
                    controls = playback_info.controls if hasattr(playback_info, 'controls') else None

                    can_go_next = getattr(controls, 'is_next_enabled', False) if controls else False
                    can_go_previous = getattr(controls, 'is_previous_enabled', False) if controls else False
                    can_play_pause = getattr(controls, 'is_play_pause_toggle_enabled', False) if controls else False

                    # Get playback state
                    status = playback_info.playback_status
                    is_playing = (status == 4)  # 4 = Playing
                except Exception:
                    can_go_next = False
                    can_go_previous = False
                    can_play_pause = False
                    is_playing = False

                session_list.append({
                    "id": i,
                    "name": title,
                    "title": title,
                    "artist": artist,
                    "albumArtPath": album_art_path,
                    "canGoNext": can_go_next,
                    "canGoPrevious": can_go_previous,
                    "canPlayPause": can_play_pause,
                    "isPlaying": is_playing,
                    "iconPath": ""
                })

            self._emit_to_qt("sessionListChanged", session_list)

        except Exception as e:
            self._emit_to_qt("errorOccurred", f"Failed to update sessions: {str(e)}")

    def _on_playback_changed(self, session, args):
        """Event handler for playback state changes."""
        if self._loop and not self._stop_requested:
            asyncio.run_coroutine_threadsafe(
                self._refresh_state(),
                self._loop
            )

    def _on_media_properties_changed(self, session, args):
        """Event handler for media property changes."""
        if self._loop and not self._stop_requested:
            asyncio.run_coroutine_threadsafe(
                self._refresh_state(),
                self._loop
            )

    async def _refresh_state(self):
        """Refresh and emit the current media state."""
        if not self._current_session:
            # No session - emit empty state
            state = {
                "has_session": False,
                "title": "",
                "artist": "",
                "album_art_path": "",
                "playback_state": "Unknown",
                "is_playing": False,
                "position": 0,
                "duration": 0,
                "can_go_next": False,
                "can_go_previous": False,
                "can_play_pause": False,
                "shuffle_state": "Unknown",
                "repeat_state": "Unknown",
            }
            self._emit_to_qt("mediaStateChanged", state)
            return

        try:
            # Get playback info
            playback_info = self._current_session.get_playback_info()
            controls = playback_info.controls if hasattr(playback_info, 'controls') else None

            # Get media properties
            media_props = await self._current_session.try_get_media_properties_async()

            # Determine playback state
            status = playback_info.playback_status
            playback_state = "Unknown"
            is_playing = False

            if status == 4:  # Playing
                playback_state = "Playing"
                is_playing = True
            elif status == 3:  # Paused
                playback_state = "Paused"
            elif status == 1:  # Stopped
                playback_state = "Stopped"
            elif status == 2:  # Changing
                playback_state = "Changing"

            # Timeline position/duration info - not reliably available in WinRT API
            # Many apps don't report this, so we disable position tracking
            position = 0
            duration = 0

            # Get album art
            album_art_path = await self._get_album_art(media_props)

            # Build state dict with safe attribute access
            can_go_next = False
            can_go_previous = False
            can_play_pause = False

            if controls:
                can_go_next = getattr(controls, 'is_next_enabled', False)
                can_go_previous = getattr(controls, 'is_previous_enabled', False)
                can_play_pause = getattr(controls, 'is_play_pause_toggle_enabled', False)

            # Get shuffle and repeat states from playback_info
            shuffle_state = "Unknown"
            repeat_state = "Unknown"

            if hasattr(playback_info, 'is_shuffle_active'):
                is_shuffle = getattr(playback_info, 'is_shuffle_active', None)
                if is_shuffle is not None:
                    shuffle_state = "On" if is_shuffle else "Off"

            if hasattr(playback_info, 'auto_repeat_mode'):
                repeat_mode = getattr(playback_info, 'auto_repeat_mode', None)
                if repeat_mode is not None:
                    # AutoRepeatMode enum: None=0, Track=1, List=2
                    if repeat_mode == 0:
                        repeat_state = "Off"
                    elif repeat_mode == 1:
                        repeat_state = "Track"
                    elif repeat_mode == 2:
                        repeat_state = "List"

            state = {
                "has_session": True,
                "title": media_props.title if media_props and media_props.title else "",
                "artist": media_props.artist if media_props and media_props.artist else "",
                "album_art_path": album_art_path,
                "playback_state": playback_state,
                "is_playing": is_playing,
                "position": int(position),
                "duration": int(duration),
                "can_go_next": can_go_next,
                "can_go_previous": can_go_previous,
                "can_play_pause": can_play_pause,
                "shuffle_state": shuffle_state,
                "repeat_state": repeat_state,
            }

            self._emit_to_qt("mediaStateChanged", state)

        except Exception as e:
            self._emit_to_qt("errorOccurred", f"Failed to refresh state: {str(e)}")

    async def _get_album_art(self, media_props) -> str:
        """Download and cache album art, return absolute path."""
        if not media_props or not media_props.thumbnail:
            return str(self._assets_dir / "default-cover.png")

        try:
            # Create hash from thumbnail reference
            thumbnail_uri = str(media_props.thumbnail)
            art_hash = hashlib.md5(thumbnail_uri.encode()).hexdigest()
            cache_path = self._temp_dir / f"{art_hash}.png"

            # Check cache
            if cache_path.exists():
                return str(cache_path.absolute())

            # Download album art
            stream_ref = media_props.thumbnail
            stream = await stream_ref.open_read_async()

            # Read using DataReader for simpler buffer handling
            from winrt.windows.storage.streams import DataReader

            reader = DataReader(stream.get_input_stream_at(0))
            await reader.load_async(stream.size)

            # Read bytes into Python bytes object
            data = bytearray(stream.size)
            reader.read_bytes(data)

            # Save to cache
            with open(cache_path, 'wb') as f:
                f.write(data)

            # Maintain LRU cache
            self._cleanup_cache()

            return str(cache_path.absolute())

        except Exception:
            # Return default on error - silently fail for album art
            return str(self._assets_dir / "default-cover.png")

    def _cleanup_cache(self):
        """Remove oldest cached album art if cache exceeds max size."""
        cache_files = list(self._temp_dir.glob("*.png"))

        if len(cache_files) > self._max_cache_size:
            # Sort by modification time
            cache_files.sort(key=lambda p: p.stat().st_mtime)

            # Remove oldest
            for f in cache_files[:-self._max_cache_size]:
                try:
                    f.unlink()
                except Exception:
                    pass

    def _emit_to_qt(self, signal_name: str, *args):
        """Thread-safe signal emission to Qt main thread."""
        # Qt signals are inherently thread-safe, so we can emit directly
        # Qt will automatically use QueuedConnection for cross-thread emission
        if signal_name == "mediaStateChanged":
            self.mediaStateChanged.emit(args[0])
        elif signal_name == "sessionListChanged":
            self.sessionListChanged.emit(args[0])
        elif signal_name == "errorOccurred":
            self.errorOccurred.emit(args[0])
