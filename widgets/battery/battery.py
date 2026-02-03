import psutil
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class BatteryBackend(QObject):
    """Backend for battery monitor widget."""

    batteryChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        # Battery state
        self._percent = 0
        self._is_plugged = False
        self._time_remaining = -1  # seconds, -1 if unknown
        self._has_battery = False

        # Update timer
        self._timer = QTimer(self)
        self._timer.setInterval(30000)  # 30 seconds
        self._timer.timeout.connect(self._update)
        self._timer.start()

        # Initial update
        self._update()

    def _update(self):
        """Update battery stats."""
        battery = psutil.sensors_battery()

        if battery is None:
            self._has_battery = False
            self._percent = 0
            self._is_plugged = True
            self._time_remaining = -1
        else:
            self._has_battery = True
            self._percent = int(battery.percent)
            self._is_plugged = battery.power_plugged
            self._time_remaining = (
                battery.secsleft
                if battery.secsleft != psutil.POWER_TIME_UNLIMITED
                else -1
            )

        self.batteryChanged.emit()

    # Properties
    @Property(bool, notify=batteryChanged)
    def hasBattery(self):
        return self._has_battery

    @Property(int, notify=batteryChanged)
    def percent(self):
        return self._percent

    @Property(bool, notify=batteryChanged)
    def isPlugged(self):
        return self._is_plugged

    @Property(bool, notify=batteryChanged)
    def isCharging(self):
        return self._is_plugged and self._percent < 100

    @Property(int, notify=batteryChanged)
    def timeRemaining(self):
        """Time remaining in seconds, -1 if unknown."""
        return self._time_remaining

    @Property(str, notify=batteryChanged)
    def timeRemainingText(self):
        """Formatted time remaining."""
        if self._time_remaining < 0:
            return "Calculating..."
        if self._is_plugged and self._percent >= 100:
            return "Fully charged"
        if self._is_plugged:
            return "Charging"

        hours = self._time_remaining // 3600
        minutes = (self._time_remaining % 3600) // 60

        if hours > 0:
            return f"{hours}h {minutes}m remaining"
        return f"{minutes}m remaining"

    @Property(str, notify=batteryChanged)
    def statusText(self):
        """Status text for display."""
        if not self._has_battery:
            return "No battery"
        if self._is_plugged:
            if self._percent >= 100:
                return "Fully charged"
            return "Charging"
        return "On battery"

    @Property(str, notify=batteryChanged)
    def icon(self):
        """Return appropriate icon name based on state."""
        if not self._has_battery:
            return "plug.svg"
        if self._is_plugged:
            return "battery-charging.svg"
        if self._percent > 80:
            return "battery-full.svg"
        if self._percent > 50:
            return "battery-medium.svg"
        if self._percent > 20:
            return "battery-low.svg"
        return "battery-warning.svg"

    # Slots
    @Slot()
    def refresh(self):
        """Force refresh."""
        self._update()

    def cleanup(self):
        """Stop timer on cleanup."""
        self._timer.stop()
