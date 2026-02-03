import os
import json
import urllib.request
import urllib.parse
import urllib.error
from pathlib import Path
from threading import Thread

from dotenv import load_dotenv
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class WeatherBackend(QObject):
    """Backend for weather widget with location search and weather data."""

    # Signals for property changes
    currentTempChanged = Signal()
    currentWeatherCodeChanged = Signal()
    currentPrecipChanged = Signal()
    currentIconChanged = Signal()
    locationNameChanged = Signal()
    forecastHoursChanged = Signal()
    hourlyDataChanged = Signal()
    dailyDataChanged = Signal()
    searchResultsChanged = Signal()
    isSearchingChanged = Signal()
    isLoadingChanged = Signal()
    errorMessageChanged = Signal()
    _weatherDataReady = Signal(dict)
    _searchDataReady = Signal(list)
    _fetchError = Signal(str)

    # Weather code to icon mapping
    WEATHER_CODE_TO_ICON = {
        0: "clear.png",
        1: "mostly-clear.png",
        2: "partly-cloudy.png",
        3: "overcast.png",
        45: "fog.png",
        48: "rime-fog.png",
        51: "light-drizzle.png",
        53: "moderate-drizzle.png",
        55: "dense-drizzle.png",
        56: "light-freezing-drizzle.png",
        57: "dense-freezing-drizzle.png",
        61: "light-rain.png",
        63: "moderate-rain.png",
        65: "heavy-rain.png",
        66: "light-freezing-rain.png",
        67: "heavy-freezing-rain.png",
        71: "light-snowfall.png",
        73: "moderate-snowfall.png",
        75: "heavy-snowfall.png",
        77: "snowflake.png",
        80: "light-rain.png",
        81: "moderate-rain.png",
        82: "heavy-rain.png",
        85: "light-snowfall.png",
        86: "heavy-snowfall.png",
        95: "thunderstorm.png",
        96: "thunderstorm-with-hail.png",
        99: "thunderstorm-with-hail.png",
    }

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)

        self._settings_backend = settings_backend
        self._current_temp = 0.0
        self._current_weather_code = 0
        self._current_precip = 0
        self._current_icon = ""
        self._location_name = ""
        self._forecast_hours = 5
        self._hourly_data = []
        self._daily_data = []
        self._search_results = []
        self._is_searching = False
        self._is_loading = False
        self._error_message = ""

        # Get assets directory for icons
        self._assets_dir = Path(__file__).parent / "assets"

        # Load environment variables from .env file
        load_dotenv()

        # Get LocationIQ API key from environment
        self._locationiq_key = os.getenv("LOCATIONIQ_KEY", "")

        # Connect background thread signals
        self._weatherDataReady.connect(self._on_weather_data_ready)
        self._searchDataReady.connect(self._on_search_data_ready)
        self._fetchError.connect(self._on_fetch_error)

        # Load settings
        self._load_settings()

        # Set up auto-refresh timer (30 minutes)
        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self.refreshWeather)
        self._refresh_timer.start(30 * 60 * 1000)  # 30 minutes in milliseconds

        # Initial weather fetch if location is set (in background)
        if self._location_name:
            self.refreshWeather()

    def _load_settings(self):
        """Load weather settings from SettingsBackend."""
        if not self._settings_backend:
            return

        # Load location
        location = self._settings_backend.getWidgetSetting("weather", "location")
        if location:
            self._location_name = location.get("display_name", "")
            self._lat = location.get("lat")
            self._lon = location.get("lon")
        else:
            self._lat = None
            self._lon = None

        # Load forecast hours (minimum 3)
        forecast_hours = self._settings_backend.getWidgetSetting(
            "weather", "forecast_hours"
        )
        self._forecast_hours = max(
            3, forecast_hours if forecast_hours is not None else 5
        )

    def _save_settings(self):
        """Save weather settings to SettingsBackend."""
        if not self._settings_backend:
            return

        # Save location
        if hasattr(self, "_lat") and self._lat is not None:
            self._settings_backend.setWidgetSetting(
                "weather",
                "location",
                {
                    "display_name": self._location_name,
                    "lat": self._lat,
                    "lon": self._lon,
                },
            )

        # Save forecast hours
        self._settings_backend.setWidgetSetting(
            "weather", "forecast_hours", self._forecast_hours
        )

    def _get_icon_path(self, weather_code: int) -> str:
        """Get full path to weather icon based on weather code."""
        icon_name = self.WEATHER_CODE_TO_ICON.get(weather_code, "overcast.png")
        icon_path = self._assets_dir / icon_name
        return str(icon_path.absolute())

    @Property(float, notify=currentTempChanged)
    def currentTemp(self):
        return self._current_temp

    @Property(int, notify=currentWeatherCodeChanged)
    def currentWeatherCode(self):
        return self._current_weather_code

    @Property(int, notify=currentPrecipChanged)
    def currentPrecip(self):
        return self._current_precip

    @Property(str, notify=currentIconChanged)
    def currentIcon(self):
        return self._current_icon

    @Property(str, notify=locationNameChanged)
    def locationName(self):
        return self._location_name

    @Property(int, notify=forecastHoursChanged)
    def forecastHours(self):
        return self._forecast_hours

    @Property("QVariantList", notify=hourlyDataChanged)
    def hourlyData(self):
        return self._hourly_data

    @Property("QVariantList", notify=dailyDataChanged)
    def dailyData(self):
        return self._daily_data

    @Property("QVariantList", notify=searchResultsChanged)
    def searchResults(self):
        return self._search_results

    @Property(bool, notify=isSearchingChanged)
    def isSearching(self):
        return self._is_searching

    @Property(bool, notify=isLoadingChanged)
    def isLoading(self):
        return self._is_loading

    @Property(str, notify=errorMessageChanged)
    def errorMessage(self):
        return self._error_message

    def _set_error(self, message: str):
        self._error_message = message
        self.errorMessageChanged.emit()

    def _clear_error(self):
        if self._error_message:
            self._error_message = ""
            self.errorMessageChanged.emit()

    def _on_fetch_error(self, message: str):
        self._set_error(message)
        self._is_loading = False
        self._is_searching = False
        self.isLoadingChanged.emit()
        self.isSearchingChanged.emit()

    def _on_search_data_ready(self, results: list):
        self._search_results = results
        self.searchResultsChanged.emit()
        self._is_searching = False
        self.isSearchingChanged.emit()

    def _on_weather_data_ready(self, data: dict):
        current = data.get("current", {})
        self._current_temp = current.get("temperature_2m", 0.0)
        self._current_weather_code = current.get("weather_code", 0)
        self._current_precip = current.get("precipitation_probability", 0)
        self._current_icon = self._get_icon_path(self._current_weather_code)

        self.currentTempChanged.emit()
        self.currentWeatherCodeChanged.emit()
        self.currentPrecipChanged.emit()
        self.currentIconChanged.emit()

        hourly = data.get("hourly", {})
        times = hourly.get("time", [])
        temps = hourly.get("temperature_2m", [])
        precips = hourly.get("precipitation_probability", [])
        codes = hourly.get("weather_code", [])

        self._hourly_data = []
        for i in range(min(self._forecast_hours, len(times))):
            self._hourly_data.append(
                {
                    "time": times[i],
                    "temp": temps[i] if i < len(temps) else 0,
                    "precip": precips[i] if i < len(precips) else 0,
                    "icon": self._get_icon_path(codes[i]) if i < len(codes) else "",
                }
            )
        self.hourlyDataChanged.emit()

        daily = data.get("daily", {})
        d_times = daily.get("time", [])
        d_max_temps = daily.get("temperature_2m_max", [])
        d_min_temps = daily.get("temperature_2m_min", [])
        d_precips = daily.get("precipitation_probability_max", [])
        d_codes = daily.get("weather_code", [])

        self._daily_data = []
        for i in range(min(self._forecast_hours, len(d_times))):
            self._daily_data.append(
                {
                    "date": d_times[i],
                    "maxTemp": d_max_temps[i] if i < len(d_max_temps) else 0,
                    "minTemp": d_min_temps[i] if i < len(d_min_temps) else 0,
                    "precip": d_precips[i] if i < len(d_precips) else 0,
                    "icon": self._get_icon_path(d_codes[i]) if i < len(d_codes) else "",
                }
            )
        self.dailyDataChanged.emit()

        self._is_loading = False
        self.isLoadingChanged.emit()

    @Slot(str)
    def searchLocation(self, query: str):
        if not query.strip():
            return

        if not self._locationiq_key:
            self._set_error(
                "LocationIQ API key not found. Please set LOCATIONIQ_KEY in .env file."
            )
            return

        self._is_searching = True
        self.isSearchingChanged.emit()
        self._clear_error()

        def fetch():
            try:
                encoded_query = urllib.parse.quote(query)
                url = f"https://us1.locationiq.com/v1/search?key={self._locationiq_key}&q={encoded_query}&format=json&limit=3"

                with urllib.request.urlopen(url, timeout=10) as response:
                    data = json.loads(response.read().decode())

                results = []
                for item in data:
                    results.append(
                        {
                            "display_name": item.get("display_name", ""),
                            "lat": float(item.get("lat", 0)),
                            "lon": float(item.get("lon", 0)),
                        }
                    )

                self._searchDataReady.emit(results)

            except urllib.error.URLError as e:
                self._fetchError.emit(f"Network error: {str(e)}")
            except json.JSONDecodeError as e:
                self._fetchError.emit(f"Failed to parse response: {str(e)}")
            except Exception as e:
                self._fetchError.emit(f"Search failed: {str(e)}")

        Thread(target=fetch, daemon=True).start()

    @Slot(int)
    def selectLocation(self, index: int):
        """Select a location from search results."""
        if index < 0 or index >= len(self._search_results):
            return

        location = self._search_results[index]
        self._location_name = location["display_name"]
        self._lat = location["lat"]
        self._lon = location["lon"]

        self.locationNameChanged.emit()

        # Save to settings
        self._save_settings()

        # Clear search results
        self._search_results = []
        self.searchResultsChanged.emit()

        # Fetch weather for new location
        self.refreshWeather()

    @Slot(int)
    def setForecastHours(self, hours: int):
        """Set number of forecast hours (3-7)."""
        if hours < 3:
            hours = 3
        elif hours > 7:
            hours = 7

        if self._forecast_hours != hours:
            self._forecast_hours = hours
            self.forecastHoursChanged.emit()

            # Save to settings
            self._save_settings()

            # Refresh weather data
            self.refreshWeather()

    @Slot()
    def refreshWeather(self):
        if not hasattr(self, "_lat") or self._lat is None or self._lon is None:
            return

        self._is_loading = True
        self.isLoadingChanged.emit()
        self._clear_error()

        lat = self._lat
        lon = self._lon
        forecast_days = self._forecast_hours

        def fetch():
            try:
                url = (
                    f"https://api.open-meteo.com/v1/forecast?"
                    f"latitude={lat}&longitude={lon}"
                    f"&current=temperature_2m,precipitation_probability,weather_code"
                    f"&hourly=temperature_2m,precipitation_probability,weather_code"
                    f"&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code"
                    f"&timezone=auto"
                    f"&forecast_hours={forecast_days * 24}"
                    f"&forecast_days={forecast_days}"
                )

                with urllib.request.urlopen(url, timeout=10) as response:
                    data = json.loads(response.read().decode())

                self._weatherDataReady.emit(data)

            except urllib.error.URLError as e:
                self._fetchError.emit(f"Network error: {str(e)}")
            except json.JSONDecodeError as e:
                self._fetchError.emit(f"Failed to parse weather data: {str(e)}")
            except Exception as e:
                self._fetchError.emit(f"Weather fetch failed: {str(e)}")

        Thread(target=fetch, daemon=True).start()
