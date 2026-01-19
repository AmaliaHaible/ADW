"""
Hotkey backend QObject for QML bridge.
Manages global hotkeys and connects to HubBackend for toggling alwaysOnTop.
"""
from PySide6.QtCore import QObject, Property, Signal, Slot

from .listener import (
    HotkeyListener,
    parse_hotkey_string,
    hotkey_to_string,
    MOD_WIN,
    MOD_CONTROL,
    MOD_ALT,
    MOD_SHIFT,
)


class HotkeyBackend(QObject):
    """
    Backend for managing global hotkeys.
    Exposes properties and slots for QML to configure hotkeys.
    """
    alwaysOnTopHotkeyChanged = Signal(str)
    recordingChanged = Signal(bool)
    recordedHotkeyChanged = Signal(str)

    def __init__(self, settings_backend=None, hub_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._hub = hub_backend
        self._listener = None
        self._always_on_top_hotkey_id = None
        self._recording = False
        self._recorded_modifiers = 0
        self._recorded_vk = 0
        self._recorded_hotkey = ""

        # Load hotkey from settings
        if self._settings:
            hotkeys = self._settings._settings.get("hotkeys", {})
            self._always_on_top_hotkey = hotkeys.get("always_on_top", "ctrl+alt+j")
        else:
            self._always_on_top_hotkey = "ctrl+alt+j"

        # Start the listener
        self._start_listener()

    def _start_listener(self):
        """Start the hotkey listener thread and register initial hotkeys."""
        self._listener = HotkeyListener(self)
        self._listener.hotkeyPressed.connect(self._on_hotkey_pressed)
        self._listener.start()

        # Wait for thread to start
        self._listener.msleep(100)

        # Register the always-on-top hotkey
        self._register_always_on_top_hotkey()

    def _register_always_on_top_hotkey(self):
        """Register the always-on-top hotkey with the listener."""
        if not self._listener or not self._always_on_top_hotkey:
            return

        # Unregister previous hotkey if exists
        if self._always_on_top_hotkey_id is not None:
            self._listener.unregister_hotkey(self._always_on_top_hotkey_id)
            self._always_on_top_hotkey_id = None

        # Parse and register new hotkey
        parsed = parse_hotkey_string(self._always_on_top_hotkey)
        if parsed:
            modifiers, vk = parsed
            self._always_on_top_hotkey_id = self._listener.register_hotkey(modifiers, vk)
            if self._always_on_top_hotkey_id is None:
                print(f"Failed to register hotkey: {self._always_on_top_hotkey}")

    def _on_hotkey_pressed(self, hotkey_id: int):
        """Handle hotkey press events from the listener."""
        if hotkey_id == self._always_on_top_hotkey_id and self._hub:
            # Toggle always on top
            current = self._hub.alwaysOnTop
            self._hub.setAlwaysOnTop(not current)

    def cleanup(self):
        """Stop the listener thread. Call before application exit."""
        if self._listener:
            self._listener.stop()
            self._listener = None

    # Properties for QML

    @Property(str, notify=alwaysOnTopHotkeyChanged)
    def alwaysOnTopHotkey(self) -> str:
        """The current always-on-top hotkey string."""
        return self._always_on_top_hotkey

    @alwaysOnTopHotkey.setter
    def alwaysOnTopHotkey(self, value: str):
        if self._always_on_top_hotkey != value:
            self._always_on_top_hotkey = value
            self._save_hotkey_setting()
            self._register_always_on_top_hotkey()
            self.alwaysOnTopHotkeyChanged.emit(value)

    @Property(bool, notify=recordingChanged)
    def recording(self) -> bool:
        """Whether we're currently recording a new hotkey."""
        return self._recording

    @recording.setter
    def recording(self, value: bool):
        if self._recording != value:
            self._recording = value
            self.recordingChanged.emit(value)

    @Property(str, notify=recordedHotkeyChanged)
    def recordedHotkey(self) -> str:
        """The hotkey being recorded."""
        return self._recorded_hotkey

    def _save_hotkey_setting(self):
        """Save the current hotkey to settings."""
        if self._settings:
            if "hotkeys" not in self._settings._settings:
                self._settings._settings["hotkeys"] = {}
            self._settings._settings["hotkeys"]["always_on_top"] = self._always_on_top_hotkey
            self._settings._save_settings()

    # Slots for QML

    @Slot(str)
    def setAlwaysOnTopHotkey(self, hotkey: str):
        """Set a new always-on-top hotkey."""
        # Validate the hotkey first
        if parse_hotkey_string(hotkey):
            self.alwaysOnTopHotkey = hotkey.lower()

    @Slot()
    def startRecording(self):
        """Start recording a new hotkey combination."""
        self._recorded_modifiers = 0
        self._recorded_vk = 0
        self._recorded_hotkey = ""
        self.recordedHotkeyChanged.emit("")
        self.recording = True

    @Slot()
    def cancelRecording(self):
        """Cancel hotkey recording."""
        self._recorded_modifiers = 0
        self._recorded_vk = 0
        self._recorded_hotkey = ""
        self.recordedHotkeyChanged.emit("")
        self.recording = False

    @Slot()
    def confirmRecording(self):
        """Confirm the recorded hotkey and apply it."""
        if self._recorded_hotkey:
            self.alwaysOnTopHotkey = self._recorded_hotkey.lower()
        self.recording = False

    @Slot(int, int)
    def recordKeyPress(self, key: int, modifiers: int):
        """
        Record a key press during recording mode.
        Called from QML with Qt key and modifier values.

        Args:
            key: Qt key code
            modifiers: Qt modifier flags
        """
        if not self._recording:
            return

        # Convert Qt modifiers to Windows modifiers
        win_mods = 0
        if modifiers & 0x04000000:  # Qt.ControlModifier
            win_mods |= MOD_CONTROL
        if modifiers & 0x08000000:  # Qt.AltModifier
            win_mods |= MOD_ALT
        if modifiers & 0x02000000:  # Qt.ShiftModifier
            win_mods |= MOD_SHIFT
        if modifiers & 0x10000000:  # Qt.MetaModifier (Win key)
            win_mods |= MOD_WIN

        # Convert Qt key to virtual key code
        vk = self._qt_key_to_vk(key)

        if vk is None:
            # Key is a modifier only, just update display
            self._recorded_modifiers = win_mods
            self._update_recorded_display()
            return

        # We have a real key - update and auto-confirm
        self._recorded_modifiers = win_mods
        self._recorded_vk = vk
        self._update_recorded_display()
        self.confirmRecording()

    def _qt_key_to_vk(self, qt_key: int) -> int | None:
        """Convert a Qt key code to a Windows virtual key code."""
        # Check for modifier-only keys
        if qt_key in (0x01000020, 0x01000021, 0x01000022, 0x01000023,  # Shift keys
                      0x01000024, 0x01000025,  # Control keys
                      0x01000026, 0x01000027,  # Meta/Win keys
                      0x01000028, 0x01000029):  # Alt keys
            return None

        # Letters (Qt: A=0x41, Windows: A=0x41)
        if 0x41 <= qt_key <= 0x5A:
            return qt_key

        # Numbers (Qt: 0=0x30, Windows: 0=0x30)
        if 0x30 <= qt_key <= 0x39:
            return qt_key

        # Function keys (Qt: F1=0x01000030, Windows: F1=0x70)
        if 0x01000030 <= qt_key <= 0x01000047:
            return 0x70 + (qt_key - 0x01000030)

        # Special keys mapping
        qt_to_vk = {
            0x01000000: 0x1B,   # Escape
            0x01000001: 0x09,   # Tab
            0x01000003: 0x08,   # Backspace
            0x01000004: 0x0D,   # Return
            0x01000005: 0x0D,   # Enter
            0x01000006: 0x2D,   # Insert
            0x01000007: 0x2E,   # Delete
            0x01000008: 0x13,   # Pause
            0x01000009: 0x2C,   # Print Screen
            0x01000010: 0x24,   # Home
            0x01000011: 0x23,   # End
            0x01000012: 0x25,   # Left
            0x01000013: 0x26,   # Up
            0x01000014: 0x27,   # Right
            0x01000015: 0x28,   # Down
            0x01000016: 0x21,   # Page Up
            0x01000017: 0x22,   # Page Down
            0x20: 0x20,         # Space
        }

        return qt_to_vk.get(qt_key)

    def _update_recorded_display(self):
        """Update the recorded hotkey display string."""
        if self._recorded_vk:
            self._recorded_hotkey = hotkey_to_string(self._recorded_modifiers, self._recorded_vk)
        else:
            # Show just modifiers
            parts = []
            if self._recorded_modifiers & MOD_WIN:
                parts.append('Win')
            if self._recorded_modifiers & MOD_CONTROL:
                parts.append('Ctrl')
            if self._recorded_modifiers & MOD_ALT:
                parts.append('Alt')
            if self._recorded_modifiers & MOD_SHIFT:
                parts.append('Shift')
            self._recorded_hotkey = '+'.join(parts) + ('+...' if parts else '...')

        self.recordedHotkeyChanged.emit(self._recorded_hotkey)

    @Slot(result=str)
    def getDisplayHotkey(self) -> str:
        """Get a display-friendly version of the hotkey."""
        parsed = parse_hotkey_string(self._always_on_top_hotkey)
        if parsed:
            return hotkey_to_string(parsed[0], parsed[1])
        return self._always_on_top_hotkey
