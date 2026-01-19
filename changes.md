# Code Review Notes

## Mistakes / Bugs
- `widgets/settings.py`: `_load_settings` returns `DEFAULT_SETTINGS.copy()` which is a shallow copy; nested dicts are shared and mutated across instances. Use `copy.deepcopy(DEFAULT_SETTINGS)` to avoid corrupting defaults.
- `widgets/media/media.py`: `_position_timer` is set to 300ms but `_update_local_position` increments by 0.5 seconds. This makes playback position drift. Align the timer interval with the increment or compute delta via elapsed time.
- `widgets/media/async_worker.py`: the event-loop sleep is 0.1s but comments and refresh counter assume 0.5s, so `_update_sessions` runs every ~0.4s instead of 2s. Fix the interval or counter math to match intended cadence.

## Bad Practices / Design Issues
- `widgets/theme_provider.py` and `widgets/settings.py` both write `settings.json` independently with no coordination. This risks lost updates (last write wins). Centralize writes in `SettingsBackend` or add file locking/atomic write + merge logic.
- `widgets/hotkey/hotkey.py`: direct access to `settings_backend._settings` and `_save_settings` breaks encapsulation. Provide public getters/setters in `SettingsBackend`.
- `widgets/weather/weather.py`: network calls (LocationIQ/Open-Meteo) run on the UI thread, which can freeze QML. Move to `QNetworkAccessManager` or a worker thread and emit results back.

## Potential Memory / Resource Leaks
- `widgets/media/async_worker.py`: WinRT event handlers are added but never removed on shutdown, which can keep objects alive. Unregister listeners during `stop` or thread teardown.
- `widgets/media/async_worker.py`: `DataReader` and the thumbnail stream are not closed after reading album art. Close/dispose them to avoid handle leaks.
- `widgets/media/media.py`: cleanup relies on `__del__`, which is not reliable under Qt; the worker thread can outlive the app. Add an explicit shutdown method and call it from `main.py` on `aboutToQuit`.

## What I Would Do Differently
- Adopt a single settings layer (or `QSettings`) to avoid concurrent writers and to simplify schema evolution and validation.
- Normalize all async/background work (weather fetches, media polling) into QThread or Qt network APIs to keep the UI thread free.
- Add explicit lifecycle hooks for backends (start/stop) and wire them in `main.py` so threads, timers, and event handlers are always released deterministically.
