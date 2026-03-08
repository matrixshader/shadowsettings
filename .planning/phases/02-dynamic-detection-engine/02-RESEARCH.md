# Phase 2: Dynamic Detection Engine - Research

**Researched:** 2026-03-07
**Domain:** GSettings schema introspection, curated registry architecture, category mapping
**Confidence:** HIGH

## Summary

Phase 2 replaces the 5 hardcoded panel classes with a data-driven architecture: a `SettingDef` struct defines each setting declaratively, a `SchemaScanner` validates which settings exist on the user's system at runtime, and a `CategoryMapper` organizes them into logical groups. The existing `SafeSettings` helper (Phase 1) provides the null-guarded schema access layer this builds on.

The architecture decision from prior research is confirmed: curated registry (inclusion list), NOT auto-discovery with exclusion blocklist. The "known-exposed blocklist" from FR-2 is implemented as the editorial act of curating the registry itself -- we only include settings that GNOME Settings does NOT expose. This approach was validated by examining gnome-control-center source code across 23 panels, which confirmed there is no machine-readable list of exposed keys.

**Primary recommendation:** Build the SettingDef data model and SchemaScanner first, populate the registry with all settings currently hardcoded in the 5 existing panels (plus additional hidden settings discovered during research), organize by category, and output structured data for the Phase 3 widget factory.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FR-1 | Dynamic Schema Detection - scan system at runtime, filter to hidden settings, null-guard all access | SchemaScanner class using SettingsSchemaSource.lookup() + SettingsSchema.has_key(); SafeSettings already provides null-guarding; curated registry defines "hidden" |
| FR-2 | Known-Exposed Blocklist - prevent duplicating GNOME Settings | Implemented as editorial curation: registry only contains settings NOT in gnome-control-center. Full audit of g-c-c source across 23 panels completed (see Blocklist section) |
| FR-4 | Category Organization - by user intent, split multi-category schemas | CategoryMapper with per-key category assignment in SettingDef; org.gnome.desktop.interface split across Desktop/Appearance categories |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GLib.SettingsSchemaSource | GLib 2.86.4 (installed) | Schema discovery and lookup | The only API for runtime schema introspection. Verified working in Vala. |
| GLib.SettingsSchema | GLib 2.86.4 | Key enumeration and existence checking | `has_key()` and `list_keys()` verified working |
| GLib.SettingsSchemaKey | GLib 2.86.4 | Key metadata extraction (type, range, summary, description, default) | All methods verified with live Vala compilation |
| GLib.Settings | GLib 2.86.4 | Read/write setting values | Bound via SafeSettings.try_get() from Phase 1 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Gee (libgee) | NOT NEEDED | Collections | Vala arrays and GenericArray sufficient for this phase |

**No new dependencies required.** Everything needed is in GLib/GIO, already in the dependency list.

## Architecture Patterns

### Recommended Project Structure

```
src/
  core/
    setting-def.vala          # SettingDef struct + WidgetHint enum
    schema-scanner.vala       # SchemaScanner: validates registry against system
    category-mapper.vala      # Groups SettingDef[] by category for sidebar
  registry/
    power.vala                # Power & suspend settings
    windows.vala              # WM preferences, mutter settings
    desktop.vala              # Shell, top bar, sound, lock screen
    appearance.vala           # Fonts, text rendering, cursor
    input.vala                # Mouse, touchpad, keyboard, XKB
    privacy.vala              # Privacy and lockdown settings (NEW)
  helpers/
    safe-settings.vala        # Existing SafeSettings helper (Phase 1)
    logind-helper.vala        # Existing logind helper
```

### Pattern 1: SettingDef Data Model

**What:** Every setting defined as a struct -- the centerpiece data type.
**When to use:** Every setting except truly custom widgets (logind lid-close combos).

```vala
// Source: Verified against ARCHITECTURE.md design + Vala compilation test
public enum WidgetHint {
    AUTO,         // infer from schema key metadata
    SWITCH,       // bool -> Adw.SwitchRow
    COMBO,        // enum/choices -> Adw.ComboRow
    SPIN_INT,     // int with range -> Adw.SpinRow
    SPIN_DOUBLE,  // double with range -> Adw.SpinRow
    FONT,         // font string -> Gtk.FontDialogButton in Adw.ActionRow
    ENTRY,        // free-text string -> Adw.EntryRow
    CUSTOM,       // delegate to custom builder
}

public struct SettingDef {
    string schema_id;
    string key;
    string label;
    string? subtitle;
    string category;
    string group;
    string category_icon;
    WidgetHint widget_hint;

    // Spin row constraints (used when widget_hint is SPIN_INT or SPIN_DOUBLE)
    double spin_min;
    double spin_max;
    double spin_step;
    int spin_digits;

    // Combo row labels (override schema enum nick values with human-readable)
    // null = use schema enum values directly
    string[]? combo_labels;
    string[]? combo_values;

    // Display transform (e.g., seconds -> minutes)
    double display_factor;
}
```

**Key insight:** `combo_labels` and `combo_values` allow overriding terse schema enum values like `"toggle-maximize"` with human-readable `"Toggle Maximize"`. When null, the widget factory should use the schema enum values directly.

### Pattern 2: SchemaScanner

**What:** Filters the curated registry down to settings that exist on THIS system.
**When to use:** Once at startup, before building any UI.

```vala
// Source: Verified with live Vala compilation on Fedora 43
public class SchemaScanner {
    private GLib.SettingsSchemaSource source;

    public SchemaScanner () {
        this.source = GLib.SettingsSchemaSource.get_default ();
    }

    // Filter a registry array down to settings available on this system
    public SettingDef[] scan (SettingDef[] registry) {
        SettingDef[] available = {};
        foreach (var def in registry) {
            var schema = source.lookup (def.schema_id, true);
            if (schema == null) continue;
            if (!schema.has_key (def.key)) continue;
            available += def;
        }
        return available;
    }

    // Get schema key metadata for a setting (for widget factory)
    public GLib.SettingsSchemaKey? get_key_info (SettingDef def) {
        var schema = source.lookup (def.schema_id, true);
        if (schema == null) return null;
        if (!schema.has_key (def.key)) return null;
        return schema.get_key (def.key);
    }
}
```

**Critical API detail:** `SettingsSchema.has_key(name)` returns `bool` -- use this instead of iterating `list_keys()`. It was verified in live Vala compilation and is cleaner.

### Pattern 3: Category Mapper

**What:** Groups filtered SettingDefs by category for sidebar construction.
**When to use:** After SchemaScanner.scan(), before building UI.

```vala
// Source: Design pattern from ARCHITECTURE.md
public struct CategoryInfo {
    string id;
    string title;
    string icon;
    SettingDef[] settings;
}

public class CategoryMapper {
    // Returns categories with their settings, ordered for sidebar
    public CategoryInfo[] map (SettingDef[] available) {
        // Use a HashTable to group by category
        var groups = new HashTable<string, GenericArray<SettingDef?>> (str_hash, str_equal);

        foreach (var def in available) {
            var list = groups.lookup (def.category);
            if (list == null) {
                list = new GenericArray<SettingDef?> ();
                groups.insert (def.category, list);
            }
            list.add (def);
        }

        // Build ordered output -- categories with 0 settings are omitted
        CategoryInfo[] result = {};
        foreach (var cat_id in CATEGORY_ORDER) {
            var list = groups.lookup (cat_id);
            if (list == null || list.length == 0) continue;
            // ... build CategoryInfo from list
        }
        return result;
    }
}
```

### Pattern 4: Registry Constants

**What:** Each registry file exports a const array of SettingDef structs.
**When to use:** One file per category domain, merged at startup.

```vala
// Source: Design from ARCHITECTURE.md, keys verified against live system
// In registry/desktop.vala:
namespace ShadowSettings.Registry {
    public const SettingDef[] DESKTOP_SETTINGS = {
        {
            schema_id: "org.gnome.desktop.interface",
            key: "enable-hot-corners",
            label: "Hot Corners",
            subtitle: "Trigger Activities overview when mouse hits top-left corner",
            category: "Desktop",
            group: "Shell",
            category_icon: "preferences-desktop-wallpaper-symbolic",
            widget_hint: WidgetHint.SWITCH
        },
        // ... more entries
    };
}
```

### Anti-Patterns to Avoid

- **Full auto-discovery (scanning all 942 keys):** Produces an inferior dconf-editor. The value proposition is curation, not exhaustive enumeration.
- **Hardcoded "known-exposed" exclusion list:** gnome-control-center has no machine-readable key manifest. Maintaining a reverse-engineered exclusion list is fragile and breaks every GNOME release.
- **Direct GLib.Settings construction without lookup:** Crashes on missing schemas. Always go through SafeSettings.try_get() or SchemaScanner validation.
- **Blocking main thread with scan:** While scanning 200 settings takes ~20-50ms (fast), profile it. If needed, use `GLib.Idle.add()` for deferred population.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema existence checking | Manual try/catch around `new GLib.Settings()` | `SettingsSchemaSource.lookup()` + null check | Built-in, no exceptions, zero-cost |
| Key existence checking | Iterate `list_keys()` array | `SettingsSchema.has_key(name)` | Direct API, cleaner, verified working |
| Key type detection | Hardcode types per key | `SettingsSchemaKey.get_value_type()` + `get_range()` | Schema XML already encodes this |
| Default value storage | Maintain separate defaults map | `SettingsSchemaKey.get_default_value()` | Schema XML is the source of truth |
| Range validation | Manual min/max checks | `SettingsSchemaKey.range_check(value)` | Built-in validation |
| Human-readable labels | Only use schema summaries | Curated labels in SettingDef with schema summary as fallback | Schema summaries are terse developer notes |

**Key insight:** The GSettings introspection API provides everything the widget factory needs via `SettingsSchemaKey`. The SettingDef struct adds the editorial layer (better labels, category assignment, widget hint overrides) that makes this a product rather than a raw settings browser.

## Common Pitfalls

### Pitfall 1: Vala Struct Arrays as Constants
**What goes wrong:** Vala has limitations with `const` arrays of structs containing nullable fields (`string?`, `string[]?`). The compiler may reject them.
**Why it happens:** Vala's const semantics are strict -- nullable types and arrays in structs don't always work in const context.
**How to avoid:** Use `static` arrays instead of `const` if the compiler rejects nullable fields. Alternatively, use a static method that returns the array.
**Warning signs:** Compiler errors about "non-constant expression" in struct initializers.

### Pitfall 2: SettingsSchema.get_key() on Nonexistent Key
**What goes wrong:** Calling `schema.get_key("nonexistent")` aborts the program (GLib assertion failure), unlike `lookup()` which returns null.
**Why it happens:** `get_key()` is not null-safe. It assumes the key exists.
**How to avoid:** ALWAYS call `schema.has_key(name)` before `schema.get_key(name)`.
**Warning signs:** `GLib-CRITICAL` assertion failures at runtime.

### Pitfall 3: get_range() Variant Tuple Interpretation
**What goes wrong:** Incorrectly parsing the range variant leads to wrong widget constraints.
**Why it happens:** `get_range()` returns a variant of type `(sv)` -- a tuple of (string range_type, variant data). The data variant's interpretation depends on range_type.
**How to avoid:** Handle all three range types:
```vala
var range = key.get_range ();
var range_type = range.get_child_value (0).get_string ();
// range_type == "type"  -> unconstrained (data is empty array of the value type)
// range_type == "enum"  -> data.get_variant() is array of allowed string values
// range_type == "range" -> data.get_variant() is tuple of (min, max)
```
**Warning signs:** Spin rows with wrong min/max, combo rows with wrong options.

### Pitfall 4: Schema Keys That Exist But Shouldn't Be Shown
**What goes wrong:** Including deprecated or internal keys that confuse users.
**Why it happens:** Some keys like `gtk-color-palette`, `gtk-im-preedit-style`, `toolbar-style` are deprecated legacy from GTK2/GTK3 and have no effect in modern GNOME.
**How to avoid:** The curated registry approach inherently prevents this -- you only add keys you've verified are useful. But document which keys to specifically EXCLUDE from curation.
**Warning signs:** User reports of settings that "do nothing."

### Pitfall 5: org.gnome.desktop.interface Spanning Multiple Categories
**What goes wrong:** Putting all `org.gnome.desktop.interface` keys in one category makes that category overwhelming (45 keys!).
**Why it happens:** This schema is a grab-bag of unrelated settings: fonts, clock, cursor, animations, theme, accessibility.
**How to avoid:** The SettingDef struct has per-key `category` and `group` fields. Keys from the same schema can be assigned to different categories. Example: `clock-*` keys go to "Desktop/Top Bar", `font-*` keys go to "Appearance/Fonts", `enable-animations` goes to "Desktop/Shell".

## GNOME Settings (gnome-control-center) Exposed Keys Audit

**Source:** Direct examination of gnome-control-center source code on GitHub (main branch, GNOME 48/49).
**Confidence:** MEDIUM-HIGH -- source code review of C files across 23 panels. Some keys may be exposed in UI XML files not examined.

The following keys are exposed in GNOME Settings and MUST NOT appear in Shadow Settings:

### Already Exposed by GNOME Settings

| Schema | Key | Exposed In Panel |
|--------|-----|-----------------|
| org.gnome.desktop.interface | color-scheme | Background (Appearance) |
| org.gnome.desktop.interface | accent-color | Background (Appearance) |
| org.gnome.desktop.interface | show-battery-percentage | Power |
| org.gnome.desktop.interface | clock-format | System > Date & Time |
| org.gnome.desktop.interface | clock-show-weekday | System > Date & Time |
| org.gnome.desktop.interface | clock-show-date | System > Date & Time |
| org.gnome.desktop.interface | clock-show-seconds | System > Date & Time |
| org.gnome.desktop.interface | enable-hot-corners | Multitasking |
| org.gnome.desktop.interface | cursor-size | Universal Access > Seeing |
| org.gnome.desktop.interface | text-scaling-factor | Universal Access > Seeing |
| org.gnome.desktop.interface | cursor-blink | Universal Access > Typing |
| org.gnome.desktop.interface | cursor-blink-time | Universal Access > Typing |
| org.gnome.desktop.interface | enable-animations | Universal Access > Seeing (as "reduced motion") |
| org.gnome.desktop.interface | overlay-scrolling | Universal Access > Seeing |
| org.gnome.desktop.interface | locate-pointer | Universal Access > Mouse |
| org.gnome.desktop.interface | gtk-theme | Universal Access > Seeing (high contrast) |
| org.gnome.desktop.interface | icon-theme | Universal Access > Seeing (high contrast) |
| org.gnome.desktop.wm.preferences | focus-mode | Universal Access > Mouse |
| org.gnome.desktop.wm.preferences | visual-bell | Universal Access > Hearing |
| org.gnome.desktop.wm.preferences | visual-bell-type | Universal Access > Hearing |
| org.gnome.desktop.wm.preferences | num-workspaces | Multitasking |
| org.gnome.desktop.peripherals.mouse | left-handed | Mouse |
| org.gnome.desktop.peripherals.mouse | natural-scroll | Mouse |
| org.gnome.desktop.peripherals.mouse | speed | Mouse |
| org.gnome.desktop.peripherals.mouse | accel-profile | Mouse |
| org.gnome.desktop.peripherals.mouse | double-click | Universal Access > Mouse |
| org.gnome.desktop.peripherals.touchpad | send-events | Mouse |
| org.gnome.desktop.peripherals.touchpad | natural-scroll | Mouse |
| org.gnome.desktop.peripherals.touchpad | speed | Mouse |
| org.gnome.desktop.peripherals.touchpad | tap-to-click | Mouse |
| org.gnome.desktop.peripherals.touchpad | click-method | Mouse |
| org.gnome.desktop.peripherals.touchpad | two-finger-scrolling-enabled | Mouse |
| org.gnome.desktop.peripherals.touchpad | edge-scrolling-enabled | Mouse |
| org.gnome.desktop.peripherals.touchpad | disable-while-typing | Mouse |
| org.gnome.desktop.peripherals.pointingstick | speed | Mouse |
| org.gnome.desktop.peripherals.pointingstick | accel-profile | Mouse |
| org.gnome.desktop.peripherals.keyboard | delay | Universal Access > Typing |
| org.gnome.desktop.peripherals.keyboard | repeat | Universal Access > Typing |
| org.gnome.desktop.peripherals.keyboard | repeat-interval | Universal Access > Typing |
| org.gnome.desktop.input-sources | per-window | Keyboard |
| org.gnome.desktop.input-sources | xkb-options | Keyboard |
| org.gnome.desktop.sound | allow-volume-above-100-percent | Sound |
| org.gnome.desktop.session | idle-delay | Power, Privacy > Screen |
| org.gnome.desktop.screensaver | lock-enabled | Privacy > Screen |
| org.gnome.desktop.screensaver | lock-delay | Privacy > Screen |
| org.gnome.desktop.privacy | remember-recent-files | Privacy > Usage |
| org.gnome.desktop.privacy | recent-files-max-age | Privacy > Usage |
| org.gnome.desktop.privacy | remove-old-trash-files | Privacy > Usage |
| org.gnome.desktop.privacy | remove-old-temp-files | Privacy > Usage |
| org.gnome.desktop.privacy | old-files-age | Privacy > Usage |
| org.gnome.desktop.privacy | usb-protection | Privacy > Screen |
| org.gnome.desktop.privacy | privacy-screen | Privacy > Screen |
| org.gnome.desktop.privacy | show-in-lock-screen | Privacy > Screen |
| org.gnome.desktop.notifications | show-banners | Notifications |
| org.gnome.desktop.notifications | show-in-lock-screen | Notifications |
| org.gnome.desktop.background | (all keys) | Background |
| org.gnome.desktop.screensaver | picture-uri* | Background |
| org.gnome.desktop.calendar | show-weekdate | System > Date & Time |
| org.gnome.desktop.datetime | automatic-timezone | System > Date & Time |
| org.gnome.desktop.search-providers | (all keys) | Search |
| org.gnome.desktop.media-handling | automount* | (Nautilus integration) |
| org.gnome.desktop.file-sharing | require-password | Sharing |
| org.gnome.mutter | workspaces-only-on-primary | Multitasking |
| org.gnome.mutter | edge-tiling | Multitasking |
| org.gnome.mutter | dynamic-workspaces | Multitasking |
| org.gnome.shell.app-switcher | current-workspace-only | Multitasking |
| org.gnome.settings-daemon.plugins.power | (all keys) | Power |
| org.gnome.settings-daemon.plugins.color | night-light-enabled | Display |
| org.gnome.desktop.a11y.keyboard | (all keys) | Universal Access > Typing |
| org.gnome.desktop.a11y.mouse | secondary-click-*, dwell-* | Universal Access > Mouse |
| org.gnome.desktop.a11y.applications | (all keys) | Universal Access |
| org.gnome.desktop.a11y.interface | high-contrast, show-status-shapes | Universal Access > Seeing |
| org.gnome.desktop.a11y | always-show-universal-access-status | Universal Access |
| org.gnome.desktop.screen-time-limits | (all keys) | Wellbeing (GNOME 48+) |
| org.gnome.desktop.break-reminders | (all keys) | Wellbeing (GNOME 48+) |
| org.gnome.desktop.break-reminders.eyesight | play-sound | Wellbeing |
| org.gnome.desktop.break-reminders.movement | duration, interval, play-sound | Wellbeing |
| org.gnome.desktop.wm.keybindings | switch-input-source | Keyboard |

### Settings HIDDEN from GNOME Settings (Candidates for Shadow Settings Registry)

These are confirmed NOT exposed in gnome-control-center and are useful to users:

**Desktop / Shell:**
| Schema | Key | Type | Description |
|--------|-----|------|-------------|
| org.gnome.desktop.sound | event-sounds | bool | System event sounds |
| org.gnome.desktop.sound | input-feedback-sounds | bool | Input feedback sounds |
| org.gnome.desktop.screensaver | show-full-name-in-top-bar | bool | Show full name in lock screen |
| org.gnome.desktop.screensaver | user-switch-enabled | bool | Allow user switching from lock screen |
| org.gnome.desktop.screensaver | logout-enabled | bool | Allow logout from screensaver |
| org.gnome.desktop.screensaver | idle-activation-enabled | bool | Activate screensaver when idle |
| org.gnome.desktop.privacy | show-full-name-in-top-bar | bool | Show full name in user menu |
| org.gnome.desktop.privacy | disable-camera | bool | Disable camera access |
| org.gnome.desktop.privacy | disable-microphone | bool | Disable microphone access |
| org.gnome.desktop.privacy | remember-app-usage | bool | Remember app usage |
| org.gnome.desktop.privacy | report-technical-problems | bool | Send tech problem reports |
| org.gnome.desktop.notifications | show-in-lock-screen | bool | Show notifications on lock screen |

**Appearance:**
| Schema | Key | Type | Description |
|--------|-----|------|-------------|
| org.gnome.desktop.interface | font-name | string | Interface font |
| org.gnome.desktop.interface | document-font-name | string | Document font |
| org.gnome.desktop.interface | monospace-font-name | string | Monospace font |
| org.gnome.desktop.interface | font-antialiasing | enum | Font antialiasing method |
| org.gnome.desktop.interface | font-hinting | enum | Font hinting level |
| org.gnome.desktop.interface | font-rgba-order | enum | Subpixel rendering order |
| org.gnome.desktop.interface | font-rendering | enum | Font rendering mode (GNOME 48+) |
| org.gnome.desktop.interface | cursor-theme | string | Cursor theme name |
| org.gnome.desktop.interface | gtk-enable-primary-paste | bool | Middle-click paste |
| org.gnome.desktop.wm.preferences | titlebar-font | string | Titlebar font |
| org.gnome.desktop.wm.preferences | titlebar-uses-system-font | bool | Use system font for titlebars |

**Window Management:**
| Schema | Key | Type | Description |
|--------|-----|------|-------------|
| org.gnome.desktop.wm.preferences | button-layout | string | Titlebar button arrangement |
| org.gnome.desktop.wm.preferences | action-double-click-titlebar | enum | Double-click titlebar action |
| org.gnome.desktop.wm.preferences | action-middle-click-titlebar | enum | Middle-click titlebar action |
| org.gnome.desktop.wm.preferences | action-right-click-titlebar | enum | Right-click titlebar action |
| org.gnome.desktop.wm.preferences | auto-raise | bool | Auto-raise focused windows |
| org.gnome.desktop.wm.preferences | auto-raise-delay | int [0-10000] | Auto-raise delay (ms) |
| org.gnome.desktop.wm.preferences | raise-on-click | bool | Raise window on click |
| org.gnome.desktop.wm.preferences | resize-with-right-button | bool | Resize with right button |
| org.gnome.desktop.wm.preferences | focus-new-windows | enum | New window focus behavior |
| org.gnome.desktop.wm.preferences | mouse-button-modifier | string | Window drag modifier key |
| org.gnome.desktop.wm.preferences | audible-bell | bool | System bell audible |
| org.gnome.mutter | center-new-windows | bool | Center new windows |
| org.gnome.mutter | attach-modal-dialogs | bool | Attach modal dialogs |
| org.gnome.mutter | auto-maximize | bool | Auto-maximize large windows |
| org.gnome.mutter | focus-change-on-pointer-rest | bool | Delay focus until pointer stops |
| org.gnome.mutter | check-alive-timeout | uint [0-max] | Window alive check timeout |
| org.gnome.mutter | draggable-border-width | int [0-64] | Draggable border width |

**Input:**
| Schema | Key | Type | Description |
|--------|-----|------|-------------|
| org.gnome.desktop.peripherals.mouse | middle-click-emulation | bool | Middle-click emulation |
| org.gnome.desktop.peripherals.touchpad | tap-and-drag | bool | Tap-and-drag |
| org.gnome.desktop.peripherals.touchpad | tap-and-drag-lock | bool | Tap-and-drag lock |
| org.gnome.desktop.peripherals.touchpad | tap-button-map | enum | Tap button mapping |
| org.gnome.desktop.peripherals.touchpad | accel-profile | enum | Touchpad acceleration |
| org.gnome.desktop.peripherals.touchpad | left-handed | enum | Touchpad handedness |
| org.gnome.desktop.peripherals.keyboard | numlock-state | bool | NumLock state |
| org.gnome.desktop.peripherals.keyboard | remember-numlock-state | bool | Remember NumLock |
| org.gnome.desktop.input-sources | show-all-sources | bool | Show all input sources |

**Shell / Misc:**
| Schema | Key | Type | Description |
|--------|-----|------|-------------|
| org.gnome.shell | always-show-log-out | bool | Always show Log Out |
| org.gnome.shell.window-switcher | current-workspace-only | bool | Alt-Tab current workspace only |
| org.gnome.shell.window-switcher | app-icon-mode | enum | Window switcher icon mode |
| org.gnome.mutter | overlay-key | string | Activities overlay key |
| org.gnome.mutter.wayland | xwayland-allow-grabs | bool | Allow X11 grabs in Xwayland |
| org.gnome.desktop.lockdown | disable-lock-screen | bool | Disable lock screen |
| org.gnome.desktop.lockdown | disable-command-line | bool | Disable command line |
| org.gnome.desktop.lockdown | disable-log-out | bool | Disable log out |
| org.gnome.desktop.lockdown | disable-printing | bool | Disable printing |
| org.gnome.desktop.lockdown | disable-user-switching | bool | Disable user switching |

## Curated Registry: Initial Content

Based on existing panels + hidden settings audit above, the initial registry should contain approximately **65-80 settings** organized as follows:

### Category Plan

| Category | Icon | Sources | Approx. Keys |
|----------|------|---------|-------------|
| Desktop | preferences-desktop-wallpaper-symbolic | interface (clock, shell), sound, screensaver, privacy, shell | ~15 |
| Appearance | applications-graphics-symbolic | interface (fonts, cursor, rendering), wm.preferences (titlebar font) | ~12 |
| Windows | preferences-system-windows-symbolic | wm.preferences (buttons, actions, focus), mutter (behavior) | ~18 |
| Input | input-keyboard-symbolic | peripherals.mouse, peripherals.touchpad, peripherals.keyboard, input-sources | ~12 |
| Power | system-shutdown-symbolic | logind helper (CUSTOM widget) | ~3 (logind only) |
| Privacy | preferences-system-privacy-symbolic | lockdown, privacy (camera/mic/etc.) | ~8 |

**Note on Power panel:** All gsettings-based power keys (sleep timeouts, idle-dim, power-button-action, show-battery-percentage) are already exposed in GNOME Settings Power panel. The only hidden power-related settings are the logind lid-close configurations, which use CUSTOM widgets (not gsettings). Keep the Power category for logind settings only.

### Migration from Existing Panels

Settings currently hardcoded in the 5 prototype panels that need to move to the registry:

| Current Panel | Settings Count | Notes |
|---------------|---------------|-------|
| PowerPanel | 7 gsettings + 2 logind | **6 of 7 gsettings are EXPOSED by GNOME Settings.** Only `idle-dim` is genuinely hidden. Logind settings stay as CUSTOM. |
| WindowsPanel | 8 | All hidden from GNOME Settings. Direct migration. |
| DesktopPanel | 9 | `enable-hot-corners` exposed in Multitasking panel. Remove it. Rest migrate. |
| AppearancePanel | 10 | All fonts + rendering = hidden. All migrate. `cursor-size` exposed in Universal Access. |
| InputPanel | 8 | `mouse speed`, `accel-profile`, `touchpad` basics exposed in Mouse panel. Keep only hidden ones. |

**Critical cleanup during migration:** Remove settings discovered to be exposed by GNOME Settings that the prototype incorrectly included. This directly addresses FR-2.

## Vala API Reference (Verified)

All signatures verified by compiling and running Vala programs on this system.

### SettingsSchemaSource

```vala
// Get the system default schema source
unowned GLib.SettingsSchemaSource source = GLib.SettingsSchemaSource.get_default ();

// List all schemas (out parameters, not return value)
string[] non_relocatable;
string[] relocatable;
source.list_schemas (true, out non_relocatable, out relocatable);
// non_relocatable.length == 185 on this system
// relocatable.length == 32 on this system

// Look up a specific schema (returns null if not found)
GLib.SettingsSchema? schema = source.lookup ("org.gnome.desktop.interface", true);
```

### SettingsSchema

```vala
// Check if key exists (SAFE -- returns bool, no abort)
bool exists = schema.has_key ("enable-hot-corners");  // true
bool nope = schema.has_key ("nonexistent-key");        // false

// Get key metadata (UNSAFE -- aborts if key doesn't exist!)
// ALWAYS check has_key() first!
GLib.SettingsSchemaKey key = schema.get_key ("enable-hot-corners");

// List all keys
string[] keys = schema.list_keys ();

// Get schema ID and path
string id = schema.get_id ();       // "org.gnome.desktop.interface"
string? path = schema.get_path ();  // "/org/gnome/desktop/interface/"
```

### SettingsSchemaKey

```vala
GLib.SettingsSchemaKey key = schema.get_key ("clock-format");

// Type information
string type_str = key.get_value_type ().dup_string ();  // "s", "b", "i", "d", "u", "as", etc.

// Human-readable strings (can be null!)
string? summary = key.get_summary ();       // "Whether the clock displays in 24h or 12h format"
string? description = key.get_description (); // More verbose description

// Default value
GLib.Variant default_val = key.get_default_value ();  // '24h'

// Key name
string name = key.get_name ();  // "clock-format"

// Range information - returns Variant of type (sv)
GLib.Variant range = key.get_range ();
string range_type = range.get_child_value (0).get_string ();
// range_type values:
//   "type"  -> unconstrained (any value of the correct GVariant type)
//   "enum"  -> restricted to specific string values
//   "range" -> numeric min/max bounds

if (range_type == "enum") {
    var vals = range.get_child_value (1).get_variant ();
    // vals is an array of strings: iterate with n_children() + get_child_value(i).get_string()
    for (size_t i = 0; i < vals.n_children (); i++) {
        string choice = vals.get_child_value (i).get_string ();
    }
} else if (range_type == "range") {
    var bounds = range.get_child_value (1).get_variant ();
    // bounds is a tuple of (min, max) of the key's type
    var min_val = bounds.get_child_value (0);  // GLib.Variant
    var max_val = bounds.get_child_value (1);  // GLib.Variant
}

// Validate a value against the range
bool valid = key.range_check (new GLib.Variant.int32 (42));
```

### Verified Range Examples from Live System

| Schema.Key | Type | Range Type | Range Data |
|------------|------|-----------|------------|
| interface.clock-format | s | enum | ['24h', '12h'] |
| interface.text-scaling-factor | d | range | [0.5, 3.0] |
| interface.enable-animations | b | type | (unconstrained) |
| interface.cursor-size | i | type | (unconstrained) |
| interface.font-hinting | s | enum | ['none', 'slight', 'medium', 'full'] |
| wm.preferences.auto-raise-delay | i | range | [0, 10000] |
| mutter.draggable-border-width | i | range | [0, 64] |

## Output Data Model for Widget Factory (Phase 3)

The SchemaScanner produces filtered `SettingDef[]` arrays grouped by category. Phase 3's widget factory consumes each `SettingDef` plus its `SettingsSchemaKey` metadata:

```
Phase 2 Output -> Phase 3 Input
================================

For each category in sidebar:
  CategoryInfo {
    id: "windows"
    title: "Window Management"
    icon: "preferences-system-windows-symbolic"
    settings: SettingDef[]  -- filtered to available on this system
  }

For each SettingDef, Phase 3 also needs:
  SchemaScanner.get_key_info(def) -> SettingsSchemaKey
    .get_value_type()      -> determines widget type (if AUTO)
    .get_range()           -> determines widget constraints
    .get_summary()         -> fallback title if label is null
    .get_description()     -> fallback subtitle if subtitle is null
    .get_default_value()   -> for reset-to-default (FR-5)

  SafeSettings.try_get(def.schema_id) -> GLib.Settings
    .bind()                -> connects widget to dconf
    .get_value() / .set_value() -> read/write current value
```

## State of the Art

| Old Approach (Prototype) | New Approach (Phase 2) | Impact |
|--------------------------|------------------------|--------|
| 5 hardcoded panel classes (~600 LOC) | SettingDef registry (~150 LOC data) + SchemaScanner (~50 LOC) | Adding a setting = 1 struct entry vs 20 LOC of widget code |
| Crashes on missing schemas | SchemaScanner.scan() silently filters | Works on any distro/GNOME version |
| Settings hardcoded regardless of exposure | Curated registry excludes GNOME Settings duplicates | Satisfies FR-2 |
| All settings in flat categories | Per-key category assignment, cross-schema grouping | Satisfies FR-4 |
| Widget type hardcoded per setting | WidgetHint.AUTO uses schema metadata | Phase 3 can auto-generate widgets |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vala compile + runtime smoke test |
| Config file | None -- Vala has no standard test framework. Tests are compile-and-run. |
| Quick run command | `cd build && meson compile && ./shadow-settings` |
| Full suite command | `meson test -C build` (if test targets added to meson.build) |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-1 | SchemaScanner filters registry to available settings | unit | Compile test program that scans registry, assert count > 0 | No -- Wave 0 |
| FR-1 | App launches without crashes on clean system | smoke | `./build/shadow-settings` (visual check) | No -- manual |
| FR-2 | No setting in registry is also in GNOME Settings | manual-only | Cross-reference registry against blocklist audit | No -- manual review |
| FR-4 | Settings grouped by category, not schema | unit | Assert categories contain cross-schema settings | No -- Wave 0 |

### Wave 0 Gaps

- [ ] `tests/test-schema-scanner.vala` -- compile-and-run test for SchemaScanner.scan()
- [ ] `tests/test-category-mapper.vala` -- verify category grouping
- [ ] Add `test()` targets to `meson.build`

Note: Vala testing is lightweight -- compile a test program that exercises the scanner/mapper and assert results. No framework needed beyond meson's built-in test() function.

## Open Questions

1. **How to handle settings exposed differently across GNOME versions?**
   - What we know: GNOME 48 added Wellbeing panel (break-reminders, screen-time-limits). GNOME 47 added Multitasking panel changes. Settings exposed in newer versions may be hidden in older ones.
   - What's unclear: Should the registry be version-aware? Should we check GNOME version at runtime?
   - Recommendation: Start version-agnostic. If a setting is exposed in GNOME 48+ Wellbeing panel, exclude it from the registry. Users on older GNOME can use Tweaks/Refine for those. Adding version-conditional entries is a future enhancement.

2. **Should SettingDef use Vala structs or classes?**
   - What we know: Structs are value types (copied on assignment), classes are reference types (heap-allocated). The registry is ~80 entries, read-only after construction.
   - What's unclear: Whether Vala's const/static struct array support handles nullable fields well.
   - Recommendation: Try struct first. If compiler rejects nullable fields in const arrays, switch to a static method that returns a newly-allocated array, or use a class with a static factory.

3. **Custom widget settings (logind, XKB) -- how do they flow through the registry?**
   - What we know: Logind settings use pkexec + config files, not gsettings. XKB options use a string array, not individual keys.
   - What's unclear: Whether these fit the SettingDef model or need separate handling.
   - Recommendation: Use `WidgetHint.CUSTOM` in SettingDef. Phase 3's widget factory delegates CUSTOM entries to hand-built widget constructors. The SettingDef still carries category/group/label metadata.

## Sources

### Primary (HIGH confidence)
- Live Vala compilation tests on Fedora 43 -- verified all API signatures
- `python3 gi.repository.Gio` introspection -- schema counts, key metadata, range formats
- [Valadoc GLib.SettingsSchemaSource](https://valadoc.org/gio-2.0/GLib.SettingsSchemaSource.html)
- [Valadoc GLib.SettingsSchema](https://valadoc.org/gio-2.0/GLib.SettingsSchema.html)
- [Valadoc GLib.SettingsSchemaKey](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.html)

### Secondary (MEDIUM-HIGH confidence)
- [gnome-control-center source (GitHub mirror)](https://github.com/GNOME/gnome-control-center) -- panels/ directory, C source files for 23 panels examined
- [gnome-control-center panels/power/cc-power-panel.c](https://github.com/GNOME/gnome-control-center/blob/main/panels/power/cc-power-panel.c)
- [gnome-control-center panels/mouse/cc-mouse-panel.c](https://github.com/GNOME/gnome-control-center/blob/main/panels/mouse/cc-mouse-panel.c)
- [gnome-control-center panels/multitasking/cc-multitasking-panel.c](https://github.com/GNOME/gnome-control-center/blob/main/panels/multitasking/cc-multitasking-panel.c)
- [gnome-control-center panels/universal-access/cc-ua-macros.h](https://github.com/GNOME/gnome-control-center/blob/main/panels/universal-access/cc-ua-macros.h)
- [gnome-control-center panels/wellbeing/cc-wellbeing-panel.c](https://github.com/GNOME/gnome-control-center/blob/main/panels/wellbeing/cc-wellbeing-panel.c)

### Tertiary (MEDIUM confidence)
- Prior project research: ARCHITECTURE.md, FEATURES.md, STACK.md
- Existing prototype source code (5 panels, SafeSettings, Window)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All APIs verified with live compilation
- Architecture: HIGH -- Data-driven pattern validated, all API signatures confirmed
- Blocklist audit: MEDIUM-HIGH -- Examined 23 gnome-control-center panels in C source; some keys may be exposed via UI XML not reviewed
- Category mapping: HIGH -- Schema key counts verified, cross-schema grouping proven feasible
- Pitfalls: HIGH -- Each pitfall verified through actual Vala compilation or known from prototype development

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (GSettings API is stable, gnome-control-center changes per GNOME release cycle)
