# Architecture Patterns

**Domain:** GNOME desktop settings/tweaks application
**Researched:** 2026-03-06

## Current State (Prototype)

The existing prototype at `/home/neo/shadow-settings/` has a flat architecture:

```
Application -> Window -> [PowerPanel, WindowsPanel, DesktopPanel, AppearancePanel, InputPanel]
                          Each panel hardcodes its own GSettings bindings
```

**Problems with current architecture:**
1. Every panel is a monolithic class that hardcodes schema IDs, key names, labels, and widget types
2. Adding a new setting means writing ~20 lines of boilerplate Vala per setting
3. No schema detection -- if a key doesn't exist on the user's system, the app crashes
4. No separation between data (what settings exist) and presentation (how to show them)
5. Zero custom CSS -- looks identical to every other Adwaita app

## Recommended Architecture

### Architecture Overview

```
+--------------------------------------------------------------+
|                        Application                            |
|  (Adw.Application, CSS loading, resource base path)          |
+---------------+----------------------------------------------+
                |
+---------------v----------------------------------------------+
|                     Main Window                               |
|  NavigationSplitView: sidebar <-> content stack               |
|  Sidebar dynamically populated from discovered categories     |
+----------+---------------------+-----------------------------+
           |                      |
+----------v----------+  +-------v----------------------------+
|   Schema Scanner     |  |   Panel Builder                    |
|   (startup query)    |  |   (builds UI from SettingDef[])   |
|                      |  |                                    |
| GSettingsSchemaSource|  | For each SettingDef:               |
|   .get_default()     |  |   type=bool   -> Adw.SwitchRow    |
|   .lookup()          |  |   type=enum   -> Adw.ComboRow     |
|   .list_keys()       |  |   type=int    -> Adw.SpinRow      |
|   .get_key()         |  |   type=double -> Adw.SpinRow      |
|                      |  |   type=string -> Adw.EntryRow     |
+----------+----------+  |   type=font   -> FontDialogButton  |
           |              +-------^----------------------------+
           |                      |
+----------v----------------------+----------------------------+
|                    Settings Registry                          |
|                                                               |
|  Curated knowledge base: list of SettingDef structs           |
|  Each defines: schema, key, label, subtitle, category,       |
|                widget_hint, value constraints                 |
|                                                               |
|  At startup: Scanner checks each SettingDef against system   |
|  Result: only settings that EXIST on this system get built   |
+--------------------------------------------------------------+
           |
+----------v------------------------------------------------------+
|               Privileged Operations Helper                       |
|                                                                  |
|  LogindHelper: reads/writes /etc/systemd/logind.conf.d/         |
|  Uses pkexec for writes (polkit auth)                            |
|  Separate from gsettings (those are user-space, no root needed) |
+------------------------------------------------------------------+
           |
+----------v------------------------------------------------------+
|                    CSS Theme Layer                                |
|                                                                  |
|  GResource-bundled style.css + style-dark.css                   |
|  Loaded automatically by Adw.Application                         |
|  Uses libadwaita CSS variables for theme compatibility           |
|  Custom CSS classes (.shadow-*) for distinctive visual identity |
+------------------------------------------------------------------+
```

### Component Boundaries

| Component | Responsibility | Communicates With | Owns |
|-----------|---------------|-------------------|------|
| **Application** | Lifecycle, CSS loading, resource path setup | Window | App ID, GResource bundle |
| **Main Window** | Navigation chrome, sidebar, content stack | Schema Scanner, Panel Builder | Layout structure |
| **Schema Scanner** | Queries system for available schemas/keys at startup | Settings Registry | Runtime availability cache |
| **Settings Registry** | Curated knowledge base of setting definitions | Schema Scanner, Panel Builder | SettingDef structs |
| **Panel Builder** | Creates UI widgets from SettingDef arrays | GSettings, Window | Widget instances |
| **Widget Factory** | Creates the correct Adw widget for a given SettingDef | Panel Builder | Widget construction logic |
| **Privileged Ops Helper** | Root-level config writes via pkexec | Polkit, logind config files | System config state |
| **CSS Theme Layer** | Visual identity, custom styling | GTK4 CSS engine, libadwaita | style.css resources |

### Data Flow

#### Startup Flow

```
1. Application launches
   +-> Adw.Application auto-loads style.css from GResource

2. Window constructs
   +-> Schema Scanner runs once
       +-> GSettingsSchemaSource.get_default()
       +-> For each SettingDef in Registry:
           +-> source.lookup(schema_id, true)  -> null means skip
           +-> schema.list_keys()              -> check key exists
       +-> Result: List<SettingDef> filtered to what exists on THIS system

3. Panel Builder receives filtered SettingDefs grouped by category
   +-> Creates Adw.PreferencesPage per category
   +-> Creates Adw.PreferencesGroup per subcategory
   +-> Creates appropriate widget per SettingDef type
   +-> Binds widget to GLib.Settings(schema_id)

4. Sidebar populated from categories that have >= 1 available setting
```

#### User Interaction Flow

```
User toggles switch
  +-> GLib.Settings.bind() auto-writes to dconf
      +-> Setting takes effect immediately (GNOME reads dconf live)

User changes logind setting
  +-> LogindHelper.write_config(key, value)
      +-> pkexec bash -c "write to /etc/systemd/logind.conf.d/"
          +-> Polkit auth dialog appears
              +-> Config written, takes effect on next lid event
```

## Core Data Structure: SettingDef

Every setting the app knows about is described declaratively by one of these structs. This is the architectural centerpiece.

```vala
public struct SettingDef {
    string schema_id;       // "org.gnome.desktop.interface"
    string key;             // "enable-hot-corners"
    string label;           // "Hot Corners"
    string subtitle;        // "Trigger Activities when mouse hits top-left"
    string category;        // "Desktop"       (determines sidebar entry)
    string group;           // "Shell"          (determines PreferencesGroup)
    string icon;            // "desktop-symbolic" (for sidebar)
    WidgetHint widget_hint; // SWITCH, COMBO, SPIN, FONT, ENTRY

    // Optional constraints for spin rows
    double spin_min;
    double spin_max;
    double spin_step;
    int spin_digits;

    // Optional for combo rows (override schema enum labels)
    string[]? combo_labels;

    // Optional: multiplier for display (e.g., seconds to minutes)
    double display_factor;
}

public enum WidgetHint {
    SWITCH,      // bool keys -> Adw.SwitchRow
    COMBO,       // enum/string keys -> Adw.ComboRow
    SPIN_INT,    // int keys -> Adw.SpinRow
    SPIN_DOUBLE, // double keys -> Adw.SpinRow
    FONT,        // font string keys -> FontDialogButton
    ENTRY,       // free-text string keys -> Adw.EntryRow
    CUSTOM,      // delegate to custom builder (logind, xkb, etc.)
}
```

**Confidence: HIGH** -- This pattern is proven by the GLib.SettingsSchemaSource introspection API (verified on this Fedora 43 system: 81 relevant schemas, 942 keys detected programmatically via Python GI).

## Key Architectural Decisions

### 1. Curated Registry, Not Full Auto-Discovery

**Decision:** Maintain a curated list of ~100-200 interesting settings with human-written labels and descriptions, NOT enumerate all 942 keys automatically.

**Rationale:**
- Full auto-detection surfaces hundreds of useless keys (e.g., `gtk-color-palette`, `gtk-im-preedit-style`, internal tracking state, deprecated keys)
- Users want curated, labeled settings with human-readable descriptions -- not raw key names and schema summaries
- The "dynamic" part is checking which curated settings exist on THIS system, not auto-discovering every key
- Refine (competitor) also uses a curated approach -- their widgets reference specific schemas and keys
- dconf-editor already does full raw introspection; duplicating that is not the product's value proposition

**How it stays "self-maintaining":**
- If a key gets removed in GNOME 48, it silently disappears from the UI (schema lookup returns null)
- If a key gets added, a one-line registry entry addition surfaces it
- No hardcoded panel code needs changing when GNOME evolves -- only the data registry
- The registry is centralized, not scattered across 5 panel classes

**Why NOT a HiddenFilter / "known exposed" exclusion approach:**
- GNOME Settings (gnome-control-center) does not publish a machine-readable list of which gsettings keys it exposes
- The mapping from "GNOME Settings panel" to "gsettings keys" is embedded in C source code and UI XML across hundreds of files in gnome-control-center
- Attempting to parse gnome-control-center source or reverse-engineer its key usage is extremely brittle and version-dependent
- A "scan everything then exclude known exposed" approach produces an unreliable, shifting set of settings that changes every GNOME release
- Instead: the curated registry IS the editorial decision of "what settings are worth surfacing." This is a product decision, not a technical detection problem

**What "dynamic" actually means in this architecture:**
- Registry says: `org.gnome.desktop.interface/enable-hot-corners` should be shown
- At runtime, scanner checks: does this schema+key exist on THIS system? Yes/No
- If yes, build the widget. If no, skip silently
- The "hidden" classification is editorial (curated by developer)
- The "availability" check is dynamic (runs on user's actual system)

### 2. Schema Detection via GSettingsSchemaSource (Vala API)

**Confidence: HIGH** -- Verified working on this system. The Vala API maps 1:1 with the GLib C API.

```vala
// Check if a schema exists on this system
var source = SettingsSchemaSource.get_default ();
var schema = source.lookup ("org.gnome.desktop.interface", true);
if (schema == null) {
    // Schema not installed on this system -- skip all settings from it
    return;
}

// Check if a specific key exists within the schema
var keys = schema.list_keys ();
bool has_key = false;
foreach (var k in keys) {
    if (k == "enable-hot-corners") {
        has_key = true;
        break;
    }
}

// Get key metadata for auto-configuring widgets
var schema_key = schema.get_key ("enable-hot-corners");
var value_type = schema_key.get_value_type ();    // VariantType ("b", "s", "i", etc.)
var range = schema_key.get_range ();              // Variant tuple (range_type, values)
var default_val = schema_key.get_default_value (); // Variant
var summary = schema_key.get_summary ();           // string (can be null)
var description = schema_key.get_description ();   // string (can be null)
```

**Key range types** (from `get_range()` first tuple element):
- `"type"` = any value of that GVariant type is valid (booleans, unconstrained integers)
- `"enum"` = restricted to specific string values (second element is array of allowed values)
- `"range"` = numeric range with min/max bounds (second element is tuple of min, max)

This metadata is sufficient to auto-determine widget types when WidgetHint is not explicitly set in the registry.

**Verified key count by schema category (Fedora 43, GNOME):**

| Schema Prefix | Schema Count | Key Count |
|---------------|-------------|-----------|
| org.gnome.desktop.* | 46 | 426 |
| org.gnome.mutter.* | 4 | 35 |
| org.gnome.settings-daemon.* | 10 | 126 |
| org.gnome.shell.* | 21 | 355 |
| **Total** | **81** | **942** |

### 3. Custom CSS Architecture

**Confidence: HIGH** -- Verified against official libadwaita documentation.

**Primary mechanism:** `Adw.Application` automatically loads CSS from the app's GResource bundle when the resource base path matches the app ID.

```
Resource path: /com/matrixshader/ShadowSettings/
Files loaded automatically:
  style.css          <- always loaded
  style-dark.css     <- loaded when Adw.StyleManager:dark == true
  style-hc.css       <- loaded when high contrast preference active
  style-hc-dark.css  <- loaded for dark + high contrast
```

**Alternative mechanism (explicit, for more control):**

```vala
protected override void startup () {
    base.startup ();

    var provider = new Gtk.CssProvider ();
    provider.load_from_resource ("/com/matrixshader/ShadowSettings/style.css");
    Gtk.StyleContext.add_provider_for_display (
        Gdk.Display.get_default (),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );
}
```

`PRIORITY_APPLICATION` means your CSS overrides Adwaita defaults but user's `~/.config/gtk-4.0/gtk.css` still wins. This is the correct priority for app-level styling.

**GResource XML (`data/com.matrixshader.ShadowSettings.gresource.xml`):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/com/matrixshader/ShadowSettings">
    <file>style.css</file>
    <file>style-dark.css</file>
  </gresource>
</gresources>
```

**Meson integration:**
```meson
gnome = import('gnome')
resources = gnome.compile_resources(
  'shadow-settings-resources',
  'data/com.matrixshader.ShadowSettings.gresource.xml',
  source_dir: 'data',
)
# Add 'resources' to executable sources list
```

**CSS strategy -- enhance Adwaita, don't replace it:**

```css
/* style.css */

/* Custom sidebar styling */
.navigation-sidebar row:selected {
    background-color: alpha(var(--accent-bg-color), 0.15);
}

/* Panel header with subtle gradient */
.shadow-panel-header {
    padding: 24px 16px;
    background: linear-gradient(
        to bottom,
        alpha(var(--accent-bg-color), 0.08),
        transparent
    );
    border-radius: 12px;
}

/* Category icons with accent tinting */
.shadow-category-icon {
    color: var(--accent-color);
    -gtk-icon-size: 32px;
}

/* Changed-from-default indicator */
.setting-changed {
    border-left: 3px solid var(--accent-color);
}
```

**Available CSS variables (all auto-switch for dark mode):**

| Variable | Purpose |
|----------|---------|
| `--accent-bg-color`, `--accent-fg-color`, `--accent-color` | Accent colors (follows user's choice) |
| `--window-bg-color`, `--window-fg-color` | Main window surfaces |
| `--view-bg-color`, `--view-fg-color` | Content areas |
| `--headerbar-bg-color`, `--headerbar-fg-color` | Header bars |
| `--sidebar-bg-color`, `--sidebar-fg-color` | Sidebar panels |
| `--card-bg-color`, `--card-fg-color` | Card containers |
| `--success-color`, `--warning-color`, `--error-color` | Semantic colors |
| `--blue-1` through `--blue-5`, `--green-*`, etc. | Full GNOME palette |

**Available style classes for widgets:**
- `.suggested-action`, `.destructive-action` -- button emphasis
- `.flat`, `.raised`, `.circular`, `.pill` -- button shapes
- `.title-1` through `.title-4`, `.heading`, `.caption` -- typography
- `.accent`, `.success`, `.warning`, `.error` -- semantic colors
- `.card`, `.boxed-list`, `.navigation-sidebar` -- container styles
- `.osd` -- dark semi-transparent overlay style
- `.dimmed` -- partial transparency

**Custom drawing (Snapshot API) for beyond-CSS visuals:**

When CSS cannot achieve the desired effect (animated indicators, custom progress rings, status badges), use GTK4's Snapshot API:

```vala
public override void snapshot (Gtk.Snapshot snapshot) {
    int width = this.get_width ();
    int height = this.get_height ();

    Graphene.Rect rect = Graphene.Rect () {
        origin = Graphene.Point () { x = 0.0f, y = 0.0f },
        size = Graphene.Size () {
            height = (float) height,
            width = (float) width * (float) progress
        }
    };

    snapshot.append_color (
        Gdk.RGBA () { red = 0.2f, green = 0.6f, blue = 1.0f, alpha = 1.0f },
        rect
    );

    base.snapshot (snapshot);
}
```

Combine with `Adw.TimedAnimation` or `Adw.SpringAnimation` for physics-based fluid motion.

### 4. Flatpak Permission Architecture

**Confidence: MEDIUM** -- Patterns verified from official Flatpak docs, but pkexec-in-Flatpak is a known unsolved pain point in the ecosystem.

#### GSettings/dconf Access

Shadow Settings needs to read/write HOST desktop settings (org.gnome.desktop.*, org.gnome.mutter.*, etc.). This requires breaking through the Flatpak dconf sandbox:

```yaml
finish-args:
  # Direct dconf access for host desktop settings
  - --talk-name=ca.desrt.dconf
  - --filesystem=xdg-run/dconf
  - --filesystem=~/.config/dconf:ro
  - --env=DCONF_USER_CONFIG_DIR=.config/dconf

  # System bus access for logind (lid close, power management)
  - --system-talk-name=org.freedesktop.login1
```

Note: The modern GSettings portal (xdg-desktop-portal) only handles the app's OWN settings namespace. For an app that modifies org.gnome.desktop.* settings on behalf of the user, direct dconf access is required.

#### pkexec / Polkit in Flatpak

**This is the hard problem.** pkexec does NOT work inside a Flatpak sandbox because:
1. pkexec is a setuid binary -- Flatpak strips setuid capabilities
2. The polkit authentication agent runs outside the sandbox
3. There is no XDG portal for "run this command as root"

**Solutions, in order of preference:**

| Approach | How | Tradeoff |
|----------|-----|----------|
| **Accept the limitation** | Flatpak version = gsettings-only features. Logind settings require native install. | Cleanest. 90%+ of the app works. GNOME Tweaks does this too. |
| **flatpak-spawn --host** | Shell out to host for pkexec. Needs `--talk-name=org.freedesktop.Flatpak`. | Full sandbox escape. Flathub reviewers will scrutinize. |
| **Host helper daemon** | Install a D-Bus system service on the host that performs privileged writes. | Complex setup. Not practical for a settings app. |
| **Logind D-Bus API only** | Use org.freedesktop.login1 D-Bus methods instead of config files. | Lid switch config is file-based, not available via D-Bus runtime API. |

**Recommendation:** Start with option 1 (accept limitation for Flatpak). The vast majority of Shadow Settings features are gsettings-based and work perfectly in Flatpak. Logind lid-close config is a niche feature. Ship both Flatpak (gsettings features) and native package (full features including logind) if demand warrants it.

**Flatpak detection:**
```vala
public static bool is_flatpak () {
    return FileUtils.test ("/.flatpak-info", FileTest.EXISTS);
}
```

### 5. Changed-from-Default Detection

A distinctive feature opportunity: visually indicate which settings the user has modified from their defaults, and provide a reset button.

```vala
public bool is_changed (GLib.Settings settings, string key,
                        GLib.SettingsSchemaKey schema_key) {
    var current = settings.get_value (key);
    var default_val = schema_key.get_default_value ();
    return !current.equal (default_val);
}

// Reset to default:
public void reset_to_default (GLib.Settings settings, string key) {
    settings.reset (key);  // GLib.Settings.reset() restores schema default
}
```

This leverages `SettingsSchemaKey.get_default_value()` (verified available in the Vala API) and `GLib.Settings.reset()` to provide a feature that dconf-editor has but GNOME Tweaks and Refine lack in a polished form.

## Patterns to Follow

### Pattern 1: Registry-Driven Panel Construction

**What:** Define settings as data, build UI from data at runtime.
**When:** Every panel except truly custom widgets (logind combo boxes, XKB options).

```vala
// In registry/desktop.vala
public const SettingDef[] DESKTOP_SETTINGS = {
    {
        schema_id: "org.gnome.desktop.interface",
        key: "enable-hot-corners",
        label: "Hot Corners",
        subtitle: "Trigger Activities when mouse hits top-left corner",
        category: "Desktop",
        group: "Shell",
        icon: "desktop-symbolic",
        widget_hint: WidgetHint.SWITCH
    },
    {
        schema_id: "org.gnome.desktop.interface",
        key: "clock-show-seconds",
        label: "Show Seconds in Clock",
        subtitle: null,
        category: "Desktop",
        group: "Top Bar",
        icon: "desktop-symbolic",
        widget_hint: WidgetHint.SWITCH
    },
    // ... more entries
};
```

### Pattern 2: Safe Schema Lookup (Graceful Degradation)

**What:** Always check schema+key existence before creating a Settings object or binding.
**When:** Every settings access, no exceptions.

```vala
public class SafeSettings {
    private static SettingsSchemaSource? _source;

    public static SettingsSchemaSource get_source () {
        if (_source == null) {
            _source = SettingsSchemaSource.get_default ();
        }
        return _source;
    }

    // Returns null if schema doesn't exist on this system
    public static GLib.Settings? try_get (string schema_id) {
        var schema = get_source ().lookup (schema_id, true);
        if (schema == null) return null;
        return new GLib.Settings (schema_id);
    }

    // Check if a specific key exists in a schema
    public static bool has_key (string schema_id, string key) {
        var schema = get_source ().lookup (schema_id, true);
        if (schema == null) return false;
        foreach (var k in schema.list_keys ()) {
            if (k == key) return true;
        }
        return false;
    }
}
```

### Pattern 3: Automatic Widget Type Inference

**What:** Use schema key metadata to auto-determine the right widget when the registry doesn't specify one explicitly.

```vala
public WidgetHint infer_widget_hint (SettingsSchemaKey schema_key) {
    var type_string = schema_key.get_value_type ().dup_string ();
    var range = schema_key.get_range ();
    var range_type = range.get_child_value (0).get_string ();

    if (type_string == "b") {
        return WidgetHint.SWITCH;
    } else if (type_string == "s" && range_type == "enum") {
        return WidgetHint.COMBO;
    } else if (type_string == "i" || type_string == "u") {
        return WidgetHint.SPIN_INT;
    } else if (type_string == "d") {
        return WidgetHint.SPIN_DOUBLE;
    } else if (type_string == "s") {
        return WidgetHint.ENTRY;
    }
    return WidgetHint.ENTRY;  // fallback
}
```

### Pattern 4: CSS Class Tagging for Visual Identity

**What:** Apply custom CSS classes to widget groups for distinctive styling without overriding libadwaita internals.

```vala
// In Panel Builder
var group = new Adw.PreferencesGroup ();
group.title = def.group;
group.add_css_class ("shadow-group");

// Category header with custom styling
var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
header_box.add_css_class ("shadow-panel-header");
var icon = new Gtk.Image.from_icon_name (category_icon);
icon.add_css_class ("shadow-category-icon");
```

### Pattern 5: Flatpak-Aware Feature Gating

**What:** Detect Flatpak environment and conditionally disable features requiring system access.

```vala
public static bool is_flatpak () {
    return FileUtils.test ("/.flatpak-info", FileTest.EXISTS);
}

// In panel construction:
if (!is_flatpak ()) {
    // Add logind lid-close controls (requires pkexec)
    add_logind_group ();
}
// gsettings-based settings work in both environments
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Full Auto-Discovery

**What:** Listing all 942 keys and displaying them automatically.
**Why bad:** Produces a worse dconf-editor. Most keys are internal, deprecated, or meaningless to users. The app becomes a wall of unintelligible toggles. Schema summaries are terse developer notes, not user-facing descriptions.
**Instead:** Curate. The registry is the product -- it's the editorial voice that says "these are the settings worth knowing about."

### Anti-Pattern 2: Direct Schema Construction Without Lookup

**What:** `new GLib.Settings("org.gnome.settings-daemon.plugins.power")` directly in panel constructors (the current prototype pattern).
**Why bad:** Crashes on systems where that schema is not installed. Different distros ship different schemas. GNOME version upgrades can remove schemas. Other DEs using GTK may not have these schemas at all.
**Instead:** Always go through SafeSettings.try_get() or source.lookup() first. Null means skip silently.

### Anti-Pattern 3: Fighting Libadwaita's Design Language

**What:** Overriding core Adwaita CSS selectors (.boxed-list internals, button styles, headerbar layout) to look "different."
**Why bad:** Breaks on libadwaita updates, looks jarring next to other GNOME apps, causes accessibility regressions, confuses users who expect consistent GNOME behavior.
**Instead:** Add distinctiveness through custom CSS classes (.shadow-*), subtle gradients using var(--accent-bg-color), icon styling, panel headers, and custom Snapshot-drawn widgets. Enhance Adwaita, do not replace it.

### Anti-Pattern 4: "Known Exposed" Exclusion List

**What:** Scan all settings, maintain a hardcoded list of what GNOME Settings already exposes, show only what's NOT in that list.
**Why bad:** gnome-control-center does not publish a machine-readable key list. Reverse-engineering it from source code is fragile and breaks every GNOME release. The exclusion list becomes a maintenance burden that defeats the "self-maintaining" goal.
**Instead:** Use a curated inclusion list (the registry). You define what's worth showing. Runtime detection only checks whether those settings exist on the user's system.

### Anti-Pattern 5: Blocking Main Thread for Schema Scanning

**What:** Running the full schema scan synchronously in the window constructor.
**Why bad:** With 200 settings to check, scanning takes ~20-50ms. Acceptable on modern hardware, but could lag on older machines or VMs.
**Instead:** Profile first -- GSettings introspection is fast (in-memory schema XML). If profiling shows a problem, use `GLib.Idle.add()` to scan and populate panels after the window is visible.

## File Structure (Target)

```
src/
  main.vala                    # Entry point
  application.vala             # Adw.Application subclass, resource_base_path
  window.vala                  # NavigationSplitView, sidebar, content stack

  core/
    setting_def.vala           # SettingDef struct and WidgetHint enum
    schema_scanner.vala        # GSettingsSchemaSource introspection
    safe_settings.vala         # Safe schema lookup wrappers
    panel_builder.vala         # Builds Adw.PreferencesPage from SettingDef[]
    widget_factory.vala        # Creates the right Adw widget for each SettingDef

  registry/
    desktop.vala               # Shell, top bar, sound, lock screen settings
    appearance.vala            # Fonts, text rendering, cursor
    windows.vala               # WM preferences, mutter settings
    input.vala                 # Mouse, touchpad, keyboard, XKB
    power.vala                 # Power/suspend settings (gsettings portion)
    privacy.vala               # Privacy and lockdown settings

  helpers/
    logind_helper.vala         # Privileged logind config operations (pkexec)

  widgets/
    custom_widgets.vala        # Snapshot-drawn custom widgets (if any)

data/
  com.matrixshader.ShadowSettings.desktop
  com.matrixshader.ShadowSettings.metainfo.xml
  com.matrixshader.ShadowSettings.gresource.xml
  style.css
  style-dark.css
  icons/

polkit/
  com.matrixshader.ShadowSettings.policy

flatpak/
  com.matrixshader.ShadowSettings.json
```

## Suggested Build Order

Based on component dependencies:

```
Phase 1: Core Infrastructure (must be first)
  +-- setting_def.vala          (zero dependencies, defines the SettingDef struct)
  +-- safe_settings.vala        (depends on: GLib.Settings/GSettingsSchemaSource)
  +-- schema_scanner.vala       (depends on: setting_def, safe_settings)
  +-- Rename/rebrand app ID     (blocks all resource paths and Flatpak manifest)

Phase 2: Registry + Panel Builder (depends on Phase 1)
  +-- widget_factory.vala       (depends on: setting_def)
  +-- panel_builder.vala        (depends on: setting_def, widget_factory, schema_scanner)
  +-- registry/*.vala           (depends on: setting_def struct)
  +-- Migrate existing panels   (depends on: all above -- replace 5 hardcoded panels
                                 with registry-driven construction)

Phase 3: CSS Theme Layer (can start in parallel with Phase 2)
  +-- GResource setup           (depends on: meson restructure + app ID)
  +-- style.css + style-dark    (depends on: GResource working)
  +-- CSS class tagging         (depends on: panel_builder adding classes)
  +-- Visual polish iterations  (depends on: CSS pipeline working)

Phase 4: Distribution (depends on Phase 2 + 3)
  +-- .desktop + metainfo.xml   (depends on: app ID decided)
  +-- Flatpak manifest          (depends on: working app + finish-args)
  +-- Flathub submission        (depends on: everything stable)
```

**Key dependency chain:** Phase 1 (core infrastructure) must be complete before panels can be migrated. The registry pattern fundamentally changes how settings are defined. You cannot do this incrementally on top of the current hardcoded panels -- it is a deliberate rearchitecture.

Phase 3 (CSS) can begin in parallel with Phase 2 once the GResource pipeline is set up, because CSS development uses GTK Inspector hot-reload and does not need the panel builder to be complete.

## Scalability Considerations

| Concern | 50 settings | 200 settings | 500+ settings |
|---------|-------------|--------------|---------------|
| Startup time | Instant (<10ms) | Fast (<50ms) | Fine (<100ms) |
| Memory | Trivial (~2MB) | Trivial (~5MB) | Still trivial (~8MB) |
| Registry maintenance | Single file | Split by category (5-8 files) | Consider subcategories or data file |
| Panel rendering | Build all at once | Lazy-load panels on sidebar click | Lazy-load + consider virtual scrolling |
| Widget count | ~50 widgets | ~200 rows | Profile; may need AdwPreferencesGroup.bind_model() |

Schema scanning is inherently fast: `SettingsSchemaSource.lookup()` is a hash table lookup (O(1) per schema). Scanning 200 settings against the system takes negligible time.

**For 200+ settings, implement lazy panel construction:** Only build the widgets for a panel when the user first clicks on that category in the sidebar. This avoids constructing all widgets at startup when the user will only visit 2-3 panels per session.

## Sources

- [GLib.SettingsSchemaSource (Vala)](https://valadoc.org/gio-2.0/GLib.SettingsSchemaSource.html) -- schema introspection, list_schemas, lookup
- [GLib.SettingsSchema (Vala)](https://valadoc.org/gio-2.0/GLib.SettingsSchema.html) -- list_keys, get_key
- [GLib.SettingsSchemaKey (Vala)](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.html) -- get_range, get_summary, get_default_value, get_value_type
- [Libadwaita Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html) -- Adw.Application CSS loading mechanism
- [Libadwaita CSS Variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.2/css-variables.html) -- named color variables reference
- [Libadwaita Style Classes](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/style-classes.html) -- built-in CSS classes
- [Libadwaita Adw.Application](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1-latest/class.Application.html) -- resource-based style loading
- [Flatpak Sandbox Permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html) -- dconf/gsettings access, D-Bus permissions
- [CSS vs Snapshot API in GTK4](https://geopjr.dev/blog/css-snapshot-api-in-gtk4) -- custom drawing patterns in Vala
- [Refine (GNOME tweaks successor)](https://gitlab.gnome.org/itsEve/Refine) -- competitor architecture reference
- Live system verification: Fedora 43, 185 total schemas (81 GNOME-related), 942 desktop keys verified via Python GI introspection
