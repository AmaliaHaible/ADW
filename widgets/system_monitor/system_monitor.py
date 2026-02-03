import psutil
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class SystemMonitorBackend(QObject):
    """Backend for system monitor widget (CPU, RAM, GPU)."""

    cpuChanged = Signal()
    memoryChanged = Signal()
    historyChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        # Current values
        self._cpu_percent = 0.0
        self._cpu_per_core = []
        self._memory_percent = 0.0
        self._memory_used = 0
        self._memory_total = 0

        # History for graphs (last 60 data points = 60 seconds)
        self._cpu_history = []
        self._memory_history = []
        self._max_history = 60

        # Update timer
        self._timer = QTimer(self)
        self._timer.setInterval(1000)  # 1 second
        self._timer.timeout.connect(self._update)
        self._timer.start()

        # Initial update
        self._update()

    def _update(self):
        """Update system stats."""
        # CPU
        self._cpu_percent = psutil.cpu_percent(interval=None)
        self._cpu_per_core = psutil.cpu_percent(interval=None, percpu=True)
        self.cpuChanged.emit()

        # Memory
        mem = psutil.virtual_memory()
        self._memory_percent = mem.percent
        self._memory_used = mem.used
        self._memory_total = mem.total
        self.memoryChanged.emit()

        # Update history
        self._cpu_history.append(self._cpu_percent)
        self._memory_history.append(self._memory_percent)

        # Trim history
        if len(self._cpu_history) > self._max_history:
            self._cpu_history = self._cpu_history[-self._max_history :]
        if len(self._memory_history) > self._max_history:
            self._memory_history = self._memory_history[-self._max_history :]

        self.historyChanged.emit()

    # CPU Properties
    @Property(float, notify=cpuChanged)
    def cpuPercent(self):
        return self._cpu_percent

    @Property("QVariantList", notify=cpuChanged)
    def cpuPerCore(self):
        return self._cpu_per_core

    @Property(int, notify=cpuChanged)
    def cpuCoreCount(self):
        return len(self._cpu_per_core)

    # Memory Properties
    @Property(float, notify=memoryChanged)
    def memoryPercent(self):
        return self._memory_percent

    @Property(float, notify=memoryChanged)
    def memoryUsedGB(self):
        return self._memory_used / (1024**3)

    @Property(float, notify=memoryChanged)
    def memoryTotalGB(self):
        return self._memory_total / (1024**3)

    @Property(str, notify=memoryChanged)
    def memoryText(self):
        used_gb = self._memory_used / (1024**3)
        total_gb = self._memory_total / (1024**3)
        return f"{used_gb:.1f} / {total_gb:.1f} GB"

    # History Properties
    @Property("QVariantList", notify=historyChanged)
    def cpuHistory(self):
        return self._cpu_history

    @Property("QVariantList", notify=historyChanged)
    def memoryHistory(self):
        return self._memory_history

    # Slots
    @Slot()
    def refresh(self):
        """Force refresh."""
        self._update()

    def cleanup(self):
        """Stop timer on cleanup."""
        self._timer.stop()
