# Feature Landscape

**Domain:** GNOME desktop settings/tweaks app
**Researched:** 2026-03-06

## Table Stakes

Features users expect in a settings/tweaks app. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Window management settings (titlebar buttons, click actions, focus mode) | Every tweaks app has these. Most-searched GNOME customizations. | Low | Already implemented in prototype. `org.gnome.desktop.wm.preferences`, `org.gnome.mutter` |
| Font configuration (interface, document, mono, titlebar) | Core tweaks functionality. GNOME Settings removed font options. | Low | Already implemented. Uses `Gtk.FontDialogButton` (GTK4 replacement for old font chooser). |
| Text rendering (scaling, hinting, antialiasing) | Accessibility requirement. Users with HiDPI or vision needs depend on this. | Low | Already implemented. `org.gnome.desktop.interface` keys. |
| Mouse/touchpad settings (acceleration, speed, tap-to-click) | GNOME Settings has basics but hides acceleration profile and fine-grained control. | Low | Already implemented. `org.gnome.desktop.peripherals.mouse/touchpad` |
| Keyboard settings (repeat rate/delay, Caps Lock remap) | Power users remap Caps Lock constantly. Repeat settings affect typing feel. | Low | Already implemented. `org.gnome.desktop.input-sources`, `org.gnome.desktop.peripherals.keyboard` |
| Power management (suspend timeouts, screen blank, dim) | Critical for laptop users. GNOME Settings simplified these significantly. | Low | Already implemented with gsettings bindings. |
| Lid close behavior | Frequently searched. Users want "do nothing on lid close". | Medium | Already implemented via logind helper + pkexec. Does NOT work in Flatpak. |
| Hot corners | GNOME removed from Settings. Users want to enable/disable. | Low | `org.gnome.desktop.interface` `enable-hot-corners` |
| Animations toggle | Accessibility. Some users disable for performance or motion sensitivity. | Low | `org.gnome.desktop.interface` `enable-animations` |
| Clock format/details | 12/24 hour, show seconds, show date, show weekday. | Low | `org.gnome.desktop.interface` clock-* keys |
| Cursor size | Accessibility. Already in prototype. | Low | Already implemented. |
| Dark/light description for each setting | Users need to know what a setting does before changing it. dconf-editor shows raw keys. | Low | `SettingsSchemaKey.get_summary()` and `get_description()` provide this automatically from the schema XML. |
| Reset to default | Users must be able to undo changes. Critical trust signal. | Low | Compare `Settings.get_value()` to `SettingsSchemaKey.get_default_value()`. Call `Settings.reset(key)` to restore. |

## Differentiators

Features that set Shadow Settings apart from Tweaks/Refine/dconf-editor. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Dynamic schema detection** | Self-maintaining. No hardcoded lists. Works across any GNOME version on any distro. | High | Core value prop. `SettingsSchemaSource.list_schemas()` -> filter against known GNOME Settings panels -> show the rest. This is the feature that makes Shadow Settings fundamentally different from Tweaks and Refine. |
| **"Hidden on YOUR system" framing** | Shows only settings that exist but aren't exposed. Not a raw dump of every dconf key. | High | Requires building a detection engine: enumerate all desktop schemas -> compare against GNOME Settings exposed keys -> present only the hidden ones. The "what's hidden" question varies by distro and GNOME version. |
| **Visually distinctive UI** | Every settings app is stock toggle lists. A custom visual identity drives viral sharing (r/unixporn, screenshots, word-of-mouth). | Medium | CSS variables + custom classes + selective Snapshot API. Not a full theme -- just distinctive cards, sidebar, transitions, and color accents within Adwaita's framework. |
| **Changed settings highlighting** | Show which settings have been modified from defaults at a glance. | Low | Compare current value to `get_default_value()`. Add a CSS class to modified rows. Possibly a "Show only changed" filter. |
| **Grouped by concept, not schema** | Settings organized by user intent (power, appearance, input) not by dconf path. | Medium | Schema-to-category mapping. Some schemas like `org.gnome.desktop.interface` span multiple categories (fonts -> Appearance, clock -> Desktop, animations -> Desktop). |
| **Search** | Find any hidden setting by name or description. | Medium | Index `get_summary()` and `get_description()` from all detected keys. `Gtk.SearchBar` + `Gtk.SearchEntry` + filter model. |
| **Per-setting explanations** | Not just "what" but "why you'd want this". Short contextual hints beyond the schema description. | Medium | Can start with schema descriptions, enhance high-value settings with curated copy over time. |
| **Smooth transitions and animations** | `AdwTimedAnimation` for panel transitions, setting changes, value previews. | Medium | Spring animations on expand/collapse, crossfade on panel switch (already using `CROSSFADE`). |

## Anti-Features

Features to explicitly NOT build. Scope traps.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Theme/icon pack switching | Gradience and dedicated theming tools cover this. Massive scope. Controversial in GNOME community (libadwaita intentionally limits theming). | Link to Gradience/Colloid/etc. if user asks. |
| GNOME Extensions management | Extension Manager app exists and is excellent. Different problem domain entirely. | Out of scope. |
| dconf raw editor | dconf-editor already exists. Showing raw keys defeats the purpose of a curated settings app. | Surface the *useful* hidden settings, not every dconf key. |
| System settings replacement | Not replacing GNOME Settings. Complementing it with what GNOME chose to hide. | Clear "hidden settings" positioning. Don't duplicate what GNOME Settings already exposes. |
| Multi-desktop support | KDE, XFCE, etc. have completely different settings systems. | GNOME-only. Clear in branding. |
| Autostart/services management | Different problem domain. systemctl/systemd tooling exists. | Out of scope. |
| Backup/restore all settings | Tempting but complex (dconf dump/load). Edge cases with schema version changes across GNOME upgrades. | Defer to later. Per-setting "Reset to Default" is the MVP version of undo. |

## Feature Dependencies

```
Dynamic Schema Detection
  -> Category Mapping (which panel does this key belong to?)
  -> Widget Factory (render appropriate widget for key type)
  -> Settings Read/Write (GLib.Settings bind/get/set)

Widget Factory
  -> Boolean keys -> AdwSwitchRow
  -> Enum keys -> AdwComboRow
  -> Integer range keys -> AdwSpinRow
  -> Double range keys -> AdwSpinRow (with decimal digits)
  -> String keys -> AdwEntryRow or AdwComboRow if choices exist
  -> String array keys -> Custom multi-select widget

Custom Visual Design
  -> GResource bundling (CSS files in binary)
  -> CssProvider registration at APPLICATION priority
  -> CSS variables referencing libadwaita named colors

Flatpak Distribution
  -> Manifest file (JSON)
  -> App metadata (desktop file, icons, appdata XML)
  -> GSettings portal access (automatic in modern runtimes)
  -> Detect-and-disable logind features (pkexec unavailable)

Changed Settings Highlighting
  -> Dynamic Schema Detection (need default values)
  -> Custom CSS class for modified rows

Search
  -> Dynamic Schema Detection (need summary/description index)
```

## MVP Recommendation

Prioritize in this order:

1. **Dynamic schema detection engine** -- this is the core product. Without it, Shadow Settings is just another hardcoded toggle list (Tweaks/Refine already exist).
2. **Widget factory** -- auto-render the right widget for each key type. Boolean -> switch, enum -> combo, int range -> spin, etc.
3. **Category mapping** -- organize detected keys into the existing 5 panels (Power, Windows, Desktop, Appearance, Input).
4. **Reset to default per-setting** -- critical trust signal. Users need to undo changes safely.
5. **Changed settings highlighting** -- low effort, high value. Users want to see what they've changed.
6. **Custom visual identity** -- CSS pass over the stock Adwaita look. Distinctive cards, sidebar, color accents.
7. **Search** -- index summaries/descriptions, filter across all panels.

**Defer:**
- Flatpak packaging: get the native app polished first, Flatpak adds complexity (pkexec, schema access testing).
- Animations beyond crossfade: polish, not function.
- Per-setting curated explanations: schema descriptions are good enough for MVP. Enhance later.

## Sources

- [GNOME Settings (gnome-control-center)](https://gitlab.gnome.org/GNOME/gnome-control-center) - reference for what's "exposed"
- [Refine](https://gitlab.gnome.org/itsEve/Refine) - competitor, Python/PyGObject, hardcoded settings
- [GNOME Tweaks](https://github.com/GNOME/gnome-tweaks) - competitor, GTK3, barely maintained
- [dconf-editor](https://gitlab.gnome.org/GNOME/dconf-editor) - raw key browser, not user-facing
- [gsettings-desktop-schemas](https://github.com/GNOME/gsettings-desktop-schemas) - the schemas Shadow Settings will introspect
- [Valadoc - GLib.SettingsSchemaKey](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.html) - key metadata API
