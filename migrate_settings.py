"""Migrate settings.json to split data/ folder structure."""

import json
from pathlib import Path

GEOMETRY_KEYS = {"x", "y", "width", "height", "visible"}


def migrate():
    project_root = Path(__file__).parent
    old_path = project_root / "settings.json"

    if not old_path.exists():
        print("No settings.json found at project root. Nothing to migrate.")
        return

    with open(old_path) as f:
        old = json.load(f)

    data_dir = project_root / "data"
    data_dir.mkdir(parents=True, exist_ok=True)

    widgets_data = old.get("widgets", {})
    hotkeys_data = old.get("hotkeys", {})
    theme_data = old.get("theme", {})

    # ── theme.json ──────────────────────────────────────────────
    theme_path = data_dir / "theme.json"
    if theme_path.exists():
        print(f"  SKIP {theme_path} (already exists)")
    else:
        with open(theme_path, "w") as f:
            json.dump(theme_data, f, indent=2)
        print(f"  WROTE {theme_path}")

    # ── layout.json ─────────────────────────────────────────────
    layout = {"widgets": {}, "hotkeys": hotkeys_data}
    for widget_name, props in widgets_data.items():
        entry = {}
        for k in GEOMETRY_KEYS:
            if k in props:
                entry[k] = props[k]
        if entry:
            layout["widgets"][widget_name] = entry

    layout_path = data_dir / "layout.json"
    if layout_path.exists():
        print(f"  SKIP {layout_path} (already exists)")
    else:
        with open(layout_path, "w") as f:
            json.dump(layout, f, indent=2)
        print(f"  WROTE {layout_path}")

    # ── Per-widget config files ─────────────────────────────────
    widgets_dir = data_dir / "widgets"
    widgets_dir.mkdir(parents=True, exist_ok=True)
    for widget_name, props in widgets_data.items():
        config = {k: v for k, v in props.items() if k not in GEOMETRY_KEYS}
        widget_path = widgets_dir / f"{widget_name}.json"
        if widget_path.exists():
            print(f"  SKIP {widget_path} (already exists)")
        else:
            with open(widget_path, "w") as f:
                json.dump(config, f, indent=2)
            print(f"  WROTE {widget_path}")

    # ── Backup old file ─────────────────────────────────────────
    backup_path = project_root / "settings.json.bak"
    if backup_path.exists():
        print(f"\n  SKIP backup {backup_path} (already exists)")
    else:
        old_path.rename(backup_path)
        print("\n  RENAMED settings.json -> settings.json.bak")

    print("\nMigration complete.")


if __name__ == "__main__":
    migrate()
