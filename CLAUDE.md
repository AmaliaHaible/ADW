# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A PySide6/QML desktop shell application for displaying widgets. The project uses Qt Quick (QML) for UI with Python backends via PySide6.

## Commands

```bash
# Install dependencies (uses uv package manager)
uv sync

# Run the application
uv run python main.py
```

## Architecture

**Entry Point**: `main.py` - Sets up QGuiApplication and QQmlApplicationEngine, loads QML files from `qml/` directory.

**Python-QML Bridge Pattern**: Python backend classes (in `widgets/`) are registered as context properties on the QML engine. See commented example in `main.py`:
```python
weather = WeatherBackend()
engine.rootContext().setContextProperty("weatherBackend", weather)
```

**Directory Structure**:
- `qml/` - QML UI files; added as import path for the engine
- `qml/Common/` - Shared QML modules (Theme singleton for colors/styling)
- `widgets/` - Python backend modules for widgets (weather, hub)
- `widgets/<name>/assets/` - Widget-specific assets (images, icons)
- `icons/` - SVG icon library

**QML Modules**: Use `qmldir` files to define modules. See `qml/Common/qmldir` for singleton pattern example.

## Widget Configuration

The `enabled_widgets.toml` file controls which widgets are loaded at startup. Disabled widgets are not loaded at all, reducing memory consumption.

```toml
[widgets]
weather = true
media = true
general_settings = true
```

The Hub widget is always enabled and cannot be disabled (not listed in config). When adding new widgets, add them to:
1. `enabled_widgets.toml` with default `true`
2. `main.py` `load_widget_config()` defaults
3. Conditional loading logic in `main.py`

## Environment

Requires `.env` file with `LOCATIONIQ_KEY` for geocoding (see `.env.example`).
