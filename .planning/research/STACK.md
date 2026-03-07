# Technology Stack

**Project:** Shadow Settings
**Researched:** 2026-03-06

## Recommended Stack

### Core Language & Framework

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Vala | 0.56.18 (LTS) | Application language | Already committed with working prototype. Compiles to native C via GObject, 50-200KB binaries, <50ms startup. First-class GLib/GTK bindings -- no FFI layer, no runtime. The right choice for a GSettings-heavy app: `GLib.SettingsSchemaSource`, `GLib.SettingsSchema`, `GLib.SettingsSchemaKey` are all native Vala types, not wrapped foreign objects. | HIGH |
| GTK4 | 4.20.3 (installed) | UI toolkit | Current stable release. Target minimum 4.12+ for GNOME 45 compat. Key capabilities: CSS custom properties, Snapshot API for programmatic drawing, `Gsk.BlurNode` for blur effects, `Gtk.CssProvider` for app-level styling. | HIGH |
| libadwaita | 1.8.4 (installed) | GNOME HIG widgets | Current stable (ships with GNOME 49). Target minimum 1.4+ for GNOME 45 compat. Key capabilities for this project: `AdwNavigationSplitView` (already using), `AdwPreferencesPage/Group/Row`, `AdwSwitchRow`, `AdwComboRow`, `AdwSpinRow`, CSS variables for all named colors, `AdwTimedAnimation` for spring animations, `AdwShortcutsDialog` (new in 1.8). | HIGH |
| GLib/GIO | 2.86.4 (installed) | Core platform | Provides `GLib.SettingsSchemaSource` for runtime schema discovery, `GLib.Settings` for read/write, `GLib.SettingsSchemaKey` for key introspection (type, summary, description, range, default). Target minimum 2.74+ (GNOME 43). | HIGH |

### Build System

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Meson | 1.8.5 (installed) | Build system | Standard for GNOME ecosystem. Already in use. Handles Vala compilation, GResource bundling, install targets, polkit policy installation. Target `meson_version: '>= 0.62.0'` for broad distro compat. | HIGH |
| GResource (gnome.compile_resources) | via Meson gnome module | Asset bundling | Bundle CSS, icons, UI files into the binary. `Gtk.CssProvider.load_from_resource()` loads from the compiled GResource -- no external file paths needed. Required for Flatpak (no filesystem access to app data). | HIGH |

### Schema Introspection (Dynamic Detection Engine)

| API | Vala Type | Purpose | Why | Confidence |
|-----|-----------|---------|-----|------------|
| `SettingsSchemaSource.get_default()` | `GLib.SettingsSchemaSource` | Get system schema source | Entry point -- returns the source that contains all installed schemas from all providers. | HIGH |
| `SettingsSchemaSource.list_schemas(recursive)` | `string[]` out params | Enumerate all installed schemas | Returns two arrays: non-relocatable and relocatable schemas. With `recursive=true`, gets everything. This is how you discover what exists on the system. | HIGH |
| `SettingsSchemaSource.lookup(schema_id, recursive)` | `GLib.SettingsSchema?` | Look up specific schema | Returns null if schema doesn't exist -- graceful degradation built in. No try/catch needed, just null-check. | HIGH |
| `SettingsSchema.list_keys()` | `string[]` | Get all keys in a schema | Enumerate every setting key in a schema. Combined with `has_key()`, this is how you detect which settings exist. | HIGH |
| `SettingsSchema.get_key(name)` | `GLib.SettingsSchemaKey` | Get key metadata | Returns a key object with full introspection: type, summary, description, range, default value. | HIGH |
| `SettingsSchemaKey.get_value_type()` | `GLib.VariantType` | Key's data type | Determines what widget to render: boolean -> SwitchRow, string with range -> ComboRow, int with range -> SpinRow, etc. | HIGH |
| `SettingsSchemaKey.get_summary()` | `string?` | Human-readable title | Use as the row title. Built into every gsettings key. | HIGH |
| `SettingsSchemaKey.get_description()` | `string?` | Detailed description | Use as the row subtitle. More verbose than summary. | HIGH |
| `SettingsSchemaKey.get_range()` | `GLib.Variant` | Valid value range | Returns a variant describing valid values -- "enum" with choices, "range" with min/max, or "type" for unconstrained. Critical for building appropriate UI widgets. | HIGH |
| `SettingsSchemaKey.get_default_value()` | `GLib.Variant` | Factory default | Enables "Reset to Default" functionality. Compare current value to default to highlight changed settings. | HIGH |

**Note:** `GLib.Settings.list_schemas()` (the static method) is deprecated since GLib 2.40. Use `SettingsSchemaSource.list_schemas()` instead -- the prototype code correctly uses `new GLib.Settings(schema_id)` for reads/writes, but schema *discovery* must go through `SettingsSchemaSource`.

### CSS & Visual Design

| Technology | Mechanism | Purpose | Why | Confidence |
|------------|-----------|---------|-----|------------|
| GTK4 CSS via `Gtk.CssProvider` | `load_from_resource()` / `load_from_string()` | App-level custom styling | Register at `GTK_STYLE_PROVIDER_PRIORITY_APPLICATION` to override Adwaita defaults while respecting user overrides. This is the sanctioned way to have a distinctive look within libadwaita -- you're not "theming", you're styling your own app. | HIGH |
| libadwaita CSS variables | `var(--accent-bg-color)`, `var(--window-bg-color)`, etc. | Semantic color access | 60+ CSS variables for colors, fonts, opacity, borders. Reference these in your CSS instead of hardcoding colors -- your custom styling automatically adapts to light/dark/high-contrast. | HIGH |
| CSS media queries (libadwaita 1.8+) | `@media` | Light/dark/HC variants in one file | New in 1.8: `@media(prefers-color-scheme: dark)` and `@media(prefers-contrast: high)` in a single stylesheet instead of multiple files. | HIGH |
| GTK4 Snapshot API | `Gtk.Widget.snapshot()` override | Programmatic drawing | For widgets that need more than CSS: animated progress indicators, custom graphs, blur effects via `Gsk.BlurNode`. Use `Adw.TimedAnimation` to drive redraws. | HIGH |
| CSS custom classes | `widget.add_css_class("shadow-card")` | Scoped styling | Add custom CSS classes to your widgets, then target them in CSS. Keeps your styles isolated from Adwaita internals. | HIGH |

### Flatpak Packaging

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Flatpak | 1.16.1 (installed) | Runtime sandbox | Already installed. Standard Linux app distribution. | HIGH |
| flatpak-builder | needs install | Build tool | `sudo dnf install flatpak-builder` -- not currently installed. Builds the Flatpak from a manifest file. | HIGH |
| org.gnome.Platform//48 | Runtime 48 | Runtime platform | Target GNOME 48 runtime for broad compatibility. Includes GTK 4.16+, libadwaita 1.7+, GLib 2.82+. Use `org.gnome.Sdk//48` for build. | MEDIUM |
| org.freedesktop.Sdk.Extension.vala | SDK extension | Vala compiler in Flatpak | Needed for building Vala apps in Flatpak (valac moved out of base SDK since GNOME 45). Note: reportedly no longer needed with runtime 49, but target 48 for compatibility. | MEDIUM |
| Manifest (JSON/YAML) | Flatpak manifest | Build definition | Defines app-id, runtime, SDK, permissions (`finish-args`), and build modules. JSON format is more common on Flathub. | HIGH |

### Privileged Operations (logind config)

| Technology | Mechanism | Purpose | Why | Confidence |
|------------|-----------|---------|-----|------------|
| polkit / pkexec | `Subprocess` call to `pkexec` | Root writes to `/etc/systemd/logind.conf.d/` | Already working in prototype. pkexec prompts for auth, writes config via shell. Polkit `.policy` file installed to `/usr/share/polkit-1/actions/`. | HIGH |
| D-Bus (systemd-logind) | `org.freedesktop.login1` | Reload logind config | After writing config, logind re-reads on next lid event. No service restart needed for lid switch settings. | MEDIUM |

**Flatpak constraint:** pkexec does NOT work inside a Flatpak sandbox. Flatpak apps cannot install polkit policy files or escalate privileges. This means logind configuration (lid close behavior, etc.) will only work when installed natively (RPM/DEB), not via Flatpak. The app must detect Flatpak and hide/disable logind settings. Detect with: `FileUtils.test("/.flatpak-info", FileTest.EXISTS)`.

### GSettings Access in Flatpak

| Mechanism | Status | Notes |
|-----------|--------|-------|
| Direct dconf access | Legacy | Old way: `--filesystem=xdg-run/dconf`, `--talk-name=ca.desrt.dconf` |
| GSettings portal (keyfile backend) | Current standard | Since xdg-desktop-portal 1.1.0 + GLib 2.60: GSettings automatically uses keyfile backend in Flatpak. Works transparently for reading/writing `org.gnome.desktop.*` schemas. |
| `--metadata=X-DConf=migrate-path=` | Migration | For migrating existing dconf settings into the Flatpak sandbox. Path must match app-id. |

**Key finding:** Reading `org.gnome.desktop.*` schemas (interface, wm, peripherals, etc.) works automatically in modern Flatpak runtimes via the settings portal. No special `finish-args` needed for GSettings reads/writes of desktop schemas. However, schema *introspection* (listing all installed schemas) may behave differently in the sandbox -- the Flatpak runtime has its own schema source that includes the desktop schemas. This needs testing.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Language | Vala | Rust (gtk4-rs) | Existing codebase. Rust would be a full rewrite for no functional gain. Vala's GObject integration is tighter for GSettings work. |
| Language | Vala | Python (PyGObject) | Refine uses Python, but: 300ms+ startup vs <50ms, runtime dependency (Python interpreter), 10-50x larger install size. Vala compiles to native. |
| Language | Vala | C | Vala compiles to C. Writing raw C gains nothing but verbosity. |
| UI | libadwaita | Plain GTK4 | libadwaita provides `AdwPreferencesPage/Group/Row` which are exactly what settings apps need. Also provides spring animations, navigation patterns, dark/light adaptation. |
| Build | Meson | CMake | Meson is the GNOME standard. GTK4, libadwaita, and all GNOME apps use Meson. CMake would fight the ecosystem. |
| Packaging | Flatpak | Snap | Flathub is the standard for GNOME apps. Snap is Canonical/Ubuntu-only in practice and has worse GNOME integration. |
| Packaging | Flatpak | AppImage | No auto-updates, no sandbox, no Flathub discovery. Not suitable for a GNOME app. |

## Version Compatibility Matrix

| GNOME Version | GTK4 | libadwaita | GLib | Fedora | Ubuntu |
|---------------|------|------------|------|--------|--------|
| 43 (min target) | 4.8 | 1.2 | 2.74 | 37 | 23.04 |
| 45 | 4.12 | 1.4 | 2.78 | 39 | 24.04 LTS |
| 47 | 4.16 | 1.6 | 2.82 | 41 | 24.10 |
| 48 | 4.18 | 1.7 | 2.84 | 42 | 25.04 |
| 49 (current) | 4.20 | 1.8 | 2.86 | 43 | - |

**Recommended minimum:** GNOME 45 / GTK4 4.12 / libadwaita 1.4 -- covers Fedora 39+ and Ubuntu 24.04 LTS. This gives us `AdwNavigationSplitView`, `AdwSpinRow`, and the core preferences widgets the prototype already uses.

**Nice-to-have minimum:** GNOME 47 / libadwaita 1.6 -- adds CSS variables for all named colors, `AdwSpinner`, `AdwBottomSheet`, and `AdwMultiLayoutView` for responsive layouts.

## Installation (Development)

```bash
# Core build dependencies (Fedora)
sudo dnf install vala gcc meson gtk4-devel libadwaita-devel glib2-devel

# Flatpak build tool
sudo dnf install flatpak-builder

# Flatpak SDK (for Flatpak builds)
flatpak install flathub org.gnome.Sdk//48
flatpak install flathub org.gnome.Platform//48
flatpak install flathub org.freedesktop.Sdk.Extension.vala//48
```

## Sources

- [Valadoc - GLib.SettingsSchemaSource](https://valadoc.org/gio-2.0/GLib.SettingsSchemaSource.html) - Schema introspection API
- [Valadoc - GLib.SettingsSchema](https://valadoc.org/gio-2.0/GLib.SettingsSchema.html) - Schema key listing
- [Valadoc - GLib.SettingsSchemaKey](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.html) - Key metadata (summary, description, range, type)
- [Valadoc - Gtk.CssProvider](https://valadoc.org/gtk4/Gtk.CssProvider.html) - CSS loading for app-level styling
- [GTK4 CSS Properties](https://docs.gtk.org/gtk4/css-properties.html) - Available CSS properties
- [libadwaita CSS Variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.2/css-variables.html) - Named colors and CSS custom properties
- [libadwaita 1.8 Blog](https://nyaa.place/blog/libadwaita-1-8/) - New features in 1.8 (CSS media queries, AdwShortcutsDialog)
- [libadwaita 1.7 Blog](https://nyaa.place/blog/libadwaita-1-7/) - AdwToggleGroup, font CSS variables
- [libadwaita 1.6 Blog](https://blogs.gnome.org/alicem/2024/09/13/libadwaita-1-6/) - CSS variables, AdwBottomSheet, AdwSpinner
- [CSS vs Snapshot API in GTK4](https://geopjr.dev/blog/css-snapshot-api-in-gtk4) - When to use CSS vs Snapshot for custom visuals
- [Flatpak Sandbox Permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html) - GSettings/dconf access in Flatpak
- [Flatpak PolicyKit issue #4789](https://github.com/flatpak/flatpak/issues/4789) - pkexec not possible in Flatpak sandbox
- [Flathub Submission](https://docs.flathub.org/docs/for-app-authors/submission) - App submission requirements
- [Refine on GitLab](https://gitlab.gnome.org/itsEve/Refine) - Competitor: Python/PyGObject/dconf approach
- [Vala SDK Extension discussion](https://discourse.gnome.org/t/does-org-freedesktop-sdk-extension-vala-extension-no-more-required-for-runtime-49/33935) - Vala in Flatpak runtimes
