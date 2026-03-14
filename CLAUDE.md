# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Shadow Settings — a GTK4/libadwaita settings app for GNOME that dynamically detects and surfaces hidden desktop settings. Written in Vala. App ID: `io.github.matrixshader.ShadowSettings`. Made by Matrix Shader.

Currently at Phase 5 (Search, Polish & Distribution). Phases 1-4 complete. See `.planning/STATE.md` for current progress and `.planning/ROADMAP.md` for the full plan.

## Build & Run

```bash
# Configure (first time or after meson.build changes)
meson setup builddir

# Build
meson compile -C builddir

# Run
./builddir/shadow-settings

# Reconfigure + build + run (one-liner)
meson setup builddir --wipe && meson compile -C builddir && ./builddir/shadow-settings
```

Dependencies: `gtk4 >= 4.12`, `libadwaita-1 >= 1.4`, `glib-2.0`, `gio-2.0`, Vala compiler, Meson >= 0.62.0.

On Fedora: `sudo dnf install vala meson gtk4-devel libadwaita-devel`

No test suite exists yet. No linter configured.

## Architecture

The app follows a **registry → scanner → mapper → factory → window** pipeline:

1. **Registry** (`src/registry/*.vala`) — Curated `SettingDef[]` arrays defining known hidden GSettings keys with metadata (schema, key, label, category, widget hint, range constraints). One file per category. To add a new hidden setting, add a `SettingDef` entry to the appropriate registry file.

2. **SchemaScanner** (`src/core/schema-scanner.vala`) — Filters the registry at runtime: only settings whose schema+key actually exist on the running system pass through. This is what makes the app self-maintaining across distros/GNOME versions.

3. **CategoryMapper** (`src/core/category-mapper.vala`) — Groups filtered settings into `CategoryInfo` structs ordered by `CATEGORY_ORDER` in `setting-def.vala`. Empty categories are omitted.

4. **WidgetFactory** (`src/core/widget-factory.vala`) — Maps `SettingDef` + `SettingsSchemaKey` type info to appropriate Adwaita widgets (SwitchRow, ComboRow, SpinRow, EntryRow, FontDialog). Handles reset-to-default, changed-settings highlighting, and range constraints.

5. **Window** (`src/window.vala`) — Assembles the UI: `NavigationSplitView` with sidebar `ListBox` and `Stack` content area. Panels are lazily constructed on first sidebar visit. First panel is built eagerly to avoid blank content.

### Other Key Components

- **SafeSettings** (`src/helpers/safe-settings.vala`) — All GSettings access must go through `SafeSettings.try_get()`. Never call `new GLib.Settings()` directly — it crashes on missing schemas.
- **PowerPanel** (`src/panels/power.vala`) — Special-cased logind panel using pkexec, not the registry pipeline. Auto-hidden in Flatpak (`/.flatpak-info` check).
- **ThemeManager** (`src/core/theme-manager.vala`) — Manages 3 Art Deco themes (Gotham Night, Gotham Day, Wayne Manor) + auto mode via CSS class switching on the window.
- **Animator** (`src/core/animator.vala`) — Row cascade entrance animations, glow pulse, spring reveal. Respects reduce-motion preference.
- **CSS** (`data/style.css`, `style-dark.css`, `style-hc.css`, `style-hc-dark.css`) — Compiled into GResource binary. Custom visual identity, not stock Adwaita.

### Data Files

- `data/*.desktop` — Desktop entry
- `data/*.gschema.xml` — App's own GSettings schema (theme + reduce-motion prefs)
- `data/*.gresource.xml` — GResource manifest for CSS
- `data/icons/` — App icons (SVG, scalable + symbolic)
- `polkit/*.policy` — PolicyKit policy for logind writes via pkexec

### Dead Code

`src/panels/` has old hardcoded panel files (appearance, desktop, input, windows) that are not in `meson.build` but kept on disk as reference. Only `power.vala` is still compiled and used.

## Key Patterns

- **Never use `new GLib.Settings()` directly** — always `SafeSettings.try_get()` which returns null on missing schemas
- **All source files live in the `ShadowSettings` namespace**
- **Adding a new hidden setting**: Add a `SettingDef` struct to the right `src/registry/*.vala` file. The scanner/mapper/factory pipeline handles the rest automatically.
- **`WidgetHint.AUTO`** tells the factory to infer widget type from the GSettings schema key type. Use specific hints (SWITCH, COMBO, SPIN_INT, etc.) only when AUTO picks wrong.
- **`WidgetHint.CUSTOM`** skips factory generation — used for Power/logind settings that need special handling.
- **Vala ownership**: Use `owned get` for properties returning GSettings strings. Vala ownership rules require explicit transfer.
- **CATEGORY_ORDER** in `setting-def.vala` controls sidebar ordering. Must be `const string[]` (not static — Vala rejects non-constant initializers for static arrays).
