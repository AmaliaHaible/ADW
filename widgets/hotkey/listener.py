"""
Background thread for Windows global hotkey registration and listening.
Uses ctypes to call Windows API directly.
"""

import ctypes
import ctypes.wintypes as wintypes
import queue
import threading
from enum import IntFlag, auto

from PySide6.QtCore import QThread, Signal


# Windows API constants
WM_HOTKEY = 0x0312
PM_REMOVE = 0x0001

# Modifier flags for RegisterHotKey
MOD_ALT = 0x0001
MOD_CONTROL = 0x0002
MOD_SHIFT = 0x0004
MOD_WIN = 0x0008
MOD_NOREPEAT = 0x4000


class HotkeyCommand(IntFlag):
    """Commands that can be sent to the listener thread."""

    REGISTER = auto()
    UNREGISTER = auto()
    STOP = auto()


# Virtual key codes mapping
VK_CODES = {
    # Letters
    **{chr(c): c for c in range(ord("A"), ord("Z") + 1)},
    # Numbers
    **{str(i): 0x30 + i for i in range(10)},
    # Function keys
    **{f"F{i}": 0x70 + i - 1 for i in range(1, 25)},
    # Special keys
    "SPACE": 0x20,
    "ENTER": 0x0D,
    "RETURN": 0x0D,
    "TAB": 0x09,
    "ESCAPE": 0x1B,
    "ESC": 0x1B,
    "BACKSPACE": 0x08,
    "DELETE": 0x2E,
    "INSERT": 0x2D,
    "HOME": 0x24,
    "END": 0x23,
    "PAGEUP": 0x21,
    "PAGEDOWN": 0x22,
    "UP": 0x26,
    "DOWN": 0x28,
    "LEFT": 0x25,
    "RIGHT": 0x27,
    "CAPSLOCK": 0x14,
    "NUMLOCK": 0x90,
    "SCROLLLOCK": 0x91,
    "PRINTSCREEN": 0x2C,
    "PAUSE": 0x13,
    # Numpad
    **{f"NUMPAD{i}": 0x60 + i for i in range(10)},
    "MULTIPLY": 0x6A,
    "ADD": 0x6B,
    "SUBTRACT": 0x6D,
    "DECIMAL": 0x6E,
    "DIVIDE": 0x6F,
    # OEM keys
    "SEMICOLON": 0xBA,
    "EQUALS": 0xBB,
    "COMMA": 0xBC,
    "MINUS": 0xBD,
    "PERIOD": 0xBE,
    "SLASH": 0xBF,
    "BACKTICK": 0xC0,
    "TILDE": 0xC0,
    "LEFTBRACKET": 0xDB,
    "BACKSLASH": 0xDC,
    "RIGHTBRACKET": 0xDD,
    "QUOTE": 0xDE,
}

# Reverse mapping for key names
VK_NAMES = {v: k for k, v in VK_CODES.items()}
# Add lowercase letter names
for c in range(ord("A"), ord("Z") + 1):
    VK_NAMES[c] = chr(c)


def parse_hotkey_string(hotkey_str: str) -> tuple[int, int] | None:
    """
    Parse a hotkey string like "win+c" into (modifiers, virtual_key_code).
    Returns None if parsing fails.
    """
    if not hotkey_str:
        return None

    parts = [p.strip().upper() for p in hotkey_str.split("+")]
    if not parts:
        return None

    modifiers = 0
    key = None

    for part in parts:
        if part in ("WIN", "LWIN", "RWIN", "SUPER", "META"):
            modifiers |= MOD_WIN
        elif part in ("CTRL", "CONTROL"):
            modifiers |= MOD_CONTROL
        elif part == "ALT":
            modifiers |= MOD_ALT
        elif part == "SHIFT":
            modifiers |= MOD_SHIFT
        elif part in VK_CODES:
            key = VK_CODES[part]
        else:
            return None

    if key is None:
        return None

    return (modifiers | MOD_NOREPEAT, key)


def hotkey_to_string(modifiers: int, vk: int) -> str:
    """
    Convert modifiers and virtual key code back to a hotkey string.
    """
    parts = []

    # Remove NOREPEAT flag for display
    mods = modifiers & ~MOD_NOREPEAT

    if mods & MOD_WIN:
        parts.append("Win")
    if mods & MOD_CONTROL:
        parts.append("Ctrl")
    if mods & MOD_ALT:
        parts.append("Alt")
    if mods & MOD_SHIFT:
        parts.append("Shift")

    key_name = VK_NAMES.get(vk, f"0x{vk:02X}")
    parts.append(key_name)

    return "+".join(parts)


class HotkeyListener(QThread):
    """
    Background thread that registers global hotkeys and listens for them.
    Uses Windows RegisterHotKey/UnregisterHotKey API.
    """

    hotkeyPressed = Signal(int)  # Emits hotkey ID when pressed

    def __init__(self, parent=None):
        super().__init__(parent)
        self._command_queue = queue.Queue()
        self._response_queue = queue.Queue()
        self._running = False
        self._hotkeys = {}  # id -> (modifiers, vk)
        self._next_id = 1
        self._thread_id = None
        self._lock = threading.Lock()

    def run(self):
        """Main thread loop - runs Windows message pump."""
        # Get the current thread ID for posting messages
        self._thread_id = ctypes.windll.kernel32.GetCurrentThreadId()
        self._running = True

        # Load Windows API functions
        user32 = ctypes.windll.user32
        RegisterHotKey = user32.RegisterHotKey
        UnregisterHotKey = user32.UnregisterHotKey
        PeekMessageW = user32.PeekMessageW

        msg = wintypes.MSG()

        while self._running:
            # Process any pending commands
            try:
                while True:
                    cmd, args = self._command_queue.get_nowait()
                    if cmd == HotkeyCommand.REGISTER:
                        hotkey_id, modifiers, vk = args
                        result = RegisterHotKey(None, hotkey_id, modifiers, vk)
                        if result:
                            self._hotkeys[hotkey_id] = (modifiers, vk)
                        self._response_queue.put(bool(result))
                    elif cmd == HotkeyCommand.UNREGISTER:
                        hotkey_id = args
                        if hotkey_id in self._hotkeys:
                            UnregisterHotKey(None, hotkey_id)
                            del self._hotkeys[hotkey_id]
                        self._response_queue.put(True)
                    elif cmd == HotkeyCommand.STOP:
                        self._running = False
                        break
            except queue.Empty:
                pass

            # Check for hotkey messages
            if PeekMessageW(ctypes.byref(msg), None, 0, 0, PM_REMOVE):
                if msg.message == WM_HOTKEY:
                    hotkey_id = msg.wParam
                    self.hotkeyPressed.emit(hotkey_id)

            # Small sleep to prevent CPU spinning
            self.msleep(10)

        # Cleanup: unregister all hotkeys
        for hotkey_id in list(self._hotkeys.keys()):
            UnregisterHotKey(None, hotkey_id)
        self._hotkeys.clear()

    def register_hotkey(self, modifiers: int, vk: int) -> int | None:
        """
        Register a global hotkey. Returns the hotkey ID on success, None on failure.
        Thread-safe: can be called from any thread.
        """
        if not self._running:
            return None

        with self._lock:
            hotkey_id = self._next_id
            self._next_id += 1

        self._command_queue.put((HotkeyCommand.REGISTER, (hotkey_id, modifiers, vk)))

        try:
            success = self._response_queue.get(timeout=1.0)
            if success:
                return hotkey_id
            return None
        except queue.Empty:
            return None

    def unregister_hotkey(self, hotkey_id: int):
        """
        Unregister a previously registered hotkey.
        Thread-safe: can be called from any thread.
        """
        if not self._running:
            return

        self._command_queue.put((HotkeyCommand.UNREGISTER, hotkey_id))
        try:
            self._response_queue.get(timeout=1.0)
        except queue.Empty:
            pass

    def stop(self):
        """Stop the listener thread."""
        self._command_queue.put((HotkeyCommand.STOP, None))
        self.wait(2000)  # Wait up to 2 seconds for thread to finish
