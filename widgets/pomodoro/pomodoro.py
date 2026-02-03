import time
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

# Try to import Windows toast notifications
try:
    import winrt.windows.ui.notifications as wun
    from winrt.windows.data.xml.dom import XmlDocument

    HAS_TOAST = True
except ImportError:
    HAS_TOAST = False


class PomodoroBackend(QObject):
    """Backend for Pomodoro timer widget."""

    # State signals
    stateChanged = Signal()
    timeRemainingChanged = Signal()
    progressChanged = Signal()
    sessionsCompletedChanged = Signal()
    settingsChanged = Signal()

    # Timer states
    STATE_IDLE = "idle"
    STATE_WORK = "work"
    STATE_BREAK = "break"
    STATE_LONG_BREAK = "long_break"
    STATE_PAUSED = "paused"

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        # Timer state
        self._state = self.STATE_IDLE
        self._paused_state = None  # State before pause
        self._time_remaining = 0  # Seconds
        self._total_time = 0
        self._sessions_completed = 0
        self._sessions_today = 0
        self._today_date = None

        # Settings (defaults)
        self._work_duration = 25  # minutes
        self._break_duration = 5
        self._long_break_duration = 15
        self._sessions_before_long_break = 4

        # Load settings
        self._load_settings()

        # Timer for countdown
        self._timer = QTimer(self)
        self._timer.setInterval(1000)  # 1 second
        self._timer.timeout.connect(self._tick)

    def _load_settings(self):
        """Load settings from backend."""
        if not self._settings:
            return

        self._work_duration = (
            self._settings.getWidgetSetting("pomodoro", "work_duration") or 25
        )
        self._break_duration = (
            self._settings.getWidgetSetting("pomodoro", "break_duration") or 5
        )
        self._long_break_duration = (
            self._settings.getWidgetSetting("pomodoro", "long_break_duration") or 15
        )
        self._sessions_before_long_break = (
            self._settings.getWidgetSetting("pomodoro", "sessions_before_long_break")
            or 4
        )

        # Load today's sessions
        saved_date = self._settings.getWidgetSetting("pomodoro", "today_date")
        today = time.strftime("%Y-%m-%d")
        if saved_date == today:
            self._sessions_today = (
                self._settings.getWidgetSetting("pomodoro", "sessions_today") or 0
            )
        else:
            self._sessions_today = 0

        self._today_date = today

    def _save_settings(self):
        """Save settings to backend."""
        if not self._settings:
            return

        self._settings.setWidgetSetting(
            "pomodoro", "work_duration", self._work_duration
        )
        self._settings.setWidgetSetting(
            "pomodoro", "break_duration", self._break_duration
        )
        self._settings.setWidgetSetting(
            "pomodoro", "long_break_duration", self._long_break_duration
        )
        self._settings.setWidgetSetting(
            "pomodoro", "sessions_before_long_break", self._sessions_before_long_break
        )
        self._settings.setWidgetSetting(
            "pomodoro", "sessions_today", self._sessions_today
        )
        self._settings.setWidgetSetting("pomodoro", "today_date", self._today_date)

    def _show_notification(self, title, message):
        """Show Windows toast notification."""
        if not HAS_TOAST:
            return

        try:
            xml = XmlDocument()
            xml.load_xml(f"""
                <toast>
                    <visual>
                        <binding template="ToastGeneric">
                            <text>{title}</text>
                            <text>{message}</text>
                        </binding>
                    </visual>
                    <audio src="ms-winsoundevent:Notification.Default"/>
                </toast>
            """)
            manager = wun.ToastNotificationManager.get_default()
            notifier = manager.create_toast_notifier_with_id(
                "Microsoft.Windows.PowerShell"
            )
            notifier.show(wun.ToastNotification(xml))
        except Exception:
            pass

    def _tick(self):
        """Timer tick - called every second."""
        if self._time_remaining > 0:
            self._time_remaining -= 1
            self.timeRemainingChanged.emit()
            self.progressChanged.emit()
        else:
            self._timer.stop()
            self._on_timer_complete()

    def _on_timer_complete(self):
        """Handle timer completion."""
        if self._state == self.STATE_WORK:
            self._sessions_completed += 1
            self._sessions_today += 1
            self._save_settings()
            self.sessionsCompletedChanged.emit()

            # Determine break type
            if self._sessions_completed % self._sessions_before_long_break == 0:
                self._show_notification(
                    "Pomodoro Complete!",
                    f"Great work! Take a {self._long_break_duration} minute break.",
                )
                self._start_long_break()
            else:
                self._show_notification(
                    "Pomodoro Complete!",
                    f"Good job! Take a {self._break_duration} minute break.",
                )
                self._start_break()

        elif self._state in (self.STATE_BREAK, self.STATE_LONG_BREAK):
            self._show_notification("Break Over!", "Ready for another focus session?")
            self._state = self.STATE_IDLE
            self.stateChanged.emit()

    def _start_break(self):
        """Start short break."""
        self._state = self.STATE_BREAK
        self._time_remaining = self._break_duration * 60
        self._total_time = self._time_remaining
        self.stateChanged.emit()
        self.timeRemainingChanged.emit()
        self.progressChanged.emit()
        self._timer.start()

    def _start_long_break(self):
        """Start long break."""
        self._state = self.STATE_LONG_BREAK
        self._time_remaining = self._long_break_duration * 60
        self._total_time = self._time_remaining
        self.stateChanged.emit()
        self.timeRemainingChanged.emit()
        self.progressChanged.emit()
        self._timer.start()

    # Properties
    @Property(str, notify=stateChanged)
    def state(self):
        return self._state

    @Property(int, notify=timeRemainingChanged)
    def timeRemaining(self):
        return self._time_remaining

    @Property(str, notify=timeRemainingChanged)
    def timeRemainingText(self):
        """Format time as MM:SS."""
        minutes = self._time_remaining // 60
        seconds = self._time_remaining % 60
        return f"{minutes:02d}:{seconds:02d}"

    @Property(float, notify=progressChanged)
    def progress(self):
        """Return progress as 0.0 to 1.0."""
        if self._total_time == 0:
            return 0.0
        return 1.0 - (self._time_remaining / self._total_time)

    @Property(int, notify=sessionsCompletedChanged)
    def sessionsCompleted(self):
        return self._sessions_completed

    @Property(int, notify=sessionsCompletedChanged)
    def sessionsToday(self):
        return self._sessions_today

    @Property(int, notify=settingsChanged)
    def workDuration(self):
        return self._work_duration

    @Property(int, notify=settingsChanged)
    def breakDuration(self):
        return self._break_duration

    @Property(int, notify=settingsChanged)
    def longBreakDuration(self):
        return self._long_break_duration

    @Property(int, notify=settingsChanged)
    def sessionsBeforeLongBreak(self):
        return self._sessions_before_long_break

    # Slots
    @Slot()
    def startWork(self):
        """Start a work session."""
        self._state = self.STATE_WORK
        self._time_remaining = self._work_duration * 60
        self._total_time = self._time_remaining
        self.stateChanged.emit()
        self.timeRemainingChanged.emit()
        self.progressChanged.emit()
        self._timer.start()

    @Slot()
    def pause(self):
        """Pause the timer."""
        if self._state in (self.STATE_WORK, self.STATE_BREAK, self.STATE_LONG_BREAK):
            self._paused_state = self._state
            self._state = self.STATE_PAUSED
            self._timer.stop()
            self.stateChanged.emit()

    @Slot()
    def resume(self):
        """Resume the timer."""
        if self._state == self.STATE_PAUSED and self._paused_state:
            self._state = self._paused_state
            self._paused_state = None
            self._timer.start()
            self.stateChanged.emit()

    @Slot()
    def stop(self):
        """Stop and reset the timer."""
        self._timer.stop()
        self._state = self.STATE_IDLE
        self._paused_state = None
        self._time_remaining = 0
        self._total_time = 0
        self.stateChanged.emit()
        self.timeRemainingChanged.emit()
        self.progressChanged.emit()

    @Slot()
    def skip(self):
        """Skip current phase."""
        self._timer.stop()
        self._on_timer_complete()

    @Slot()
    def resetSessionCount(self):
        """Reset session count."""
        self._sessions_completed = 0
        self._sessions_today = 0
        self._save_settings()
        self.sessionsCompletedChanged.emit()

    @Slot(int)
    def setWorkDuration(self, minutes):
        """Set work duration in minutes."""
        if 1 <= minutes <= 60:
            self._work_duration = minutes
            self._save_settings()
            self.settingsChanged.emit()

    @Slot(int)
    def setBreakDuration(self, minutes):
        """Set break duration in minutes."""
        if 1 <= minutes <= 30:
            self._break_duration = minutes
            self._save_settings()
            self.settingsChanged.emit()

    @Slot(int)
    def setLongBreakDuration(self, minutes):
        """Set long break duration in minutes."""
        if 1 <= minutes <= 60:
            self._long_break_duration = minutes
            self._save_settings()
            self.settingsChanged.emit()

    @Slot(int)
    def setSessionsBeforeLongBreak(self, count):
        """Set sessions before long break."""
        if 1 <= count <= 10:
            self._sessions_before_long_break = count
            self._save_settings()
            self.settingsChanged.emit()
