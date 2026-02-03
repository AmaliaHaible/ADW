import psutil
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class NetworkMonitorBackend(QObject):
    """Backend for network monitor widget."""

    statsChanged = Signal()
    historyChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        # Current values
        self._bytes_sent = 0
        self._bytes_recv = 0
        self._upload_speed = 0.0  # bytes/sec
        self._download_speed = 0.0  # bytes/sec

        # Previous values for speed calculation
        self._prev_bytes_sent = 0
        self._prev_bytes_recv = 0

        # History for graphs (last 60 data points)
        self._upload_history = []
        self._download_history = []
        self._max_history = 60

        # Update timer
        self._timer = QTimer(self)
        self._timer.setInterval(1000)  # 1 second
        self._timer.timeout.connect(self._update)

        # Get initial values
        counters = psutil.net_io_counters()
        self._prev_bytes_sent = counters.bytes_sent
        self._prev_bytes_recv = counters.bytes_recv

        self._timer.start()

    def _update(self):
        """Update network stats."""
        counters = psutil.net_io_counters()

        # Calculate speed (bytes per second)
        self._upload_speed = counters.bytes_sent - self._prev_bytes_sent
        self._download_speed = counters.bytes_recv - self._prev_bytes_recv

        # Update previous values
        self._prev_bytes_sent = counters.bytes_sent
        self._prev_bytes_recv = counters.bytes_recv

        # Total bytes
        self._bytes_sent = counters.bytes_sent
        self._bytes_recv = counters.bytes_recv

        self.statsChanged.emit()

        # Update history
        self._upload_history.append(self._upload_speed)
        self._download_history.append(self._download_speed)

        # Trim history
        if len(self._upload_history) > self._max_history:
            self._upload_history = self._upload_history[-self._max_history :]
        if len(self._download_history) > self._max_history:
            self._download_history = self._download_history[-self._max_history :]

        self.historyChanged.emit()

    def _format_speed(self, bytes_per_sec):
        """Format speed in human readable format."""
        if bytes_per_sec < 1024:
            return f"{bytes_per_sec:.0f} B/s"
        elif bytes_per_sec < 1024 * 1024:
            return f"{bytes_per_sec / 1024:.1f} KB/s"
        elif bytes_per_sec < 1024 * 1024 * 1024:
            return f"{bytes_per_sec / (1024 * 1024):.1f} MB/s"
        else:
            return f"{bytes_per_sec / (1024 * 1024 * 1024):.2f} GB/s"

    def _format_bytes(self, bytes_val):
        """Format bytes in human readable format."""
        if bytes_val < 1024:
            return f"{bytes_val} B"
        elif bytes_val < 1024 * 1024:
            return f"{bytes_val / 1024:.1f} KB"
        elif bytes_val < 1024 * 1024 * 1024:
            return f"{bytes_val / (1024 * 1024):.1f} MB"
        else:
            return f"{bytes_val / (1024 * 1024 * 1024):.2f} GB"

    # Properties
    @Property(float, notify=statsChanged)
    def uploadSpeed(self):
        return self._upload_speed

    @Property(float, notify=statsChanged)
    def downloadSpeed(self):
        return self._download_speed

    @Property(str, notify=statsChanged)
    def uploadSpeedText(self):
        return self._format_speed(self._upload_speed)

    @Property(str, notify=statsChanged)
    def downloadSpeedText(self):
        return self._format_speed(self._download_speed)

    @Property(str, notify=statsChanged)
    def totalSentText(self):
        return self._format_bytes(self._bytes_sent)

    @Property(str, notify=statsChanged)
    def totalReceivedText(self):
        return self._format_bytes(self._bytes_recv)

    # History Properties
    @Property("QVariantList", notify=historyChanged)
    def uploadHistory(self):
        return self._upload_history

    @Property("QVariantList", notify=historyChanged)
    def downloadHistory(self):
        return self._download_history

    @Property(float, notify=historyChanged)
    def maxUploadHistory(self):
        """Max value in upload history for graph scaling."""
        return max(self._upload_history) if self._upload_history else 1

    @Property(float, notify=historyChanged)
    def maxDownloadHistory(self):
        """Max value in download history for graph scaling."""
        return max(self._download_history) if self._download_history else 1

    # Slots
    @Slot()
    def refresh(self):
        """Force refresh."""
        self._update()

    def cleanup(self):
        """Stop timer on cleanup."""
        self._timer.stop()
