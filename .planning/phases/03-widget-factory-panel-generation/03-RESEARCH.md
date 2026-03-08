# Phase 3: Widget Factory & Panel Generation - Research

**Researched:** 2026-03-08
**Domain:** GTK4/libadwaita widget generation from GSettings schema metadata, Vala
**Confidence:** HIGH

## Summary

Phase 3 replaces the placeholder `ActionRow` labels in `build_category_page()` with interactive widgets driven by the `SettingDef` data model from Phase 2. The widget factory maps each `WidgetHint` enum value to the correct Adwaita row widget (`AdwSwitchRow`, `AdwComboRow`, `AdwSpinRow`, `AdwEntryRow`, `FontDialogButton`), wires GSettings bindings for live two-way updates, and adds reset-to-default with changed-setting visual indication.

The core APIs are well-understood and already partially demonstrated in the existing hardcoded panels (`src/panels/*.vala`). The existing panels show working patterns for every widget type needed. The widget factory essentially generalizes these patterns into a data-driven dispatch. The `GLib.Settings.get_user_value()` method (returns `null` when no user override exists) provides the exact mechanism needed for changed-settings highlighting without fragile value comparison.

**Primary recommendation:** Create a `WidgetFactory` static class with a single entry point `create_row(SettingDef, SchemaScanner) -> Gtk.Widget?` that dispatches on `WidgetHint`, using existing panel code as reference implementation. Replace `build_category_page()` in window.vala to call the factory. Add CSS class `setting-modified` for changed-settings visual indication (Phase 4 will style it).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FR-3 | Widget Factory: auto-generate appropriate UI widgets based on key metadata | WidgetHint enum already maps to widget types; AdwSwitchRow/ComboRow/SpinRow/EntryRow/FontDialogButton APIs verified; existing panels demonstrate all patterns |
| FR-5 | Reset to Default + Changed Highlighting | `GLib.Settings.reset(key)` for reset; `GLib.Settings.get_user_value(key)` returns null when at default for highlighting; `Gtk.Widget.add_css_class()` for visual indication |
| FR-7 | Logind gating: auto-hidden when Flatpak | `FileUtils.test("/.flatpak-info", FileTest.EXISTS)` already implemented in window.vala; Power/logind entries use CUSTOM WidgetHint; PowerPanel preserved as-is |
</phase_requirements>

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GTK4 | 4.20.3 | UI toolkit, widget base classes | System GTK, target is 4.12+ |
| libadwaita | 1.8.4 | AdwSwitchRow, ComboRow, SpinRow, EntryRow, ActionRow | System libadwaita, target is 1.4+ |
| GLib/GIO | 2.x | GSettings, SettingsSchemaKey, Variant | Core GObject/GSettings APIs |
| Vala | 0.56.18 | Language compiler | Project language |
| Meson | 0.62+ | Build system | Project build system |

### Supporting (already in project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Pango | system | FontDescription for FONT widget hint | Font picker rows |

### No New Dependencies
This phase requires zero new dependencies. All APIs are in GTK4, libadwaita, and GLib which are already in `meson.build`.

## Architecture Patterns

### Recommended Project Structure
```
src/
├── core/
│   ├── setting-def.vala      # [EXISTS] SettingDef, WidgetHint, CategoryInfo
│   ├── schema-scanner.vala   # [EXISTS] SchemaScanner with scan() + get_key_info()
│   ├── category-mapper.vala  # [EXISTS] CategoryMapper with map()
│   └── widget-factory.vala   # [NEW] WidgetFactory static class
├── registry/                 # [EXISTS] 6 registry files, untouched
├── panels/
│   └── power.vala            # [EXISTS] PowerPanel for logind (CUSTOM), kept as-is
├── helpers/
│   ├── safe-settings.vala    # [EXISTS] SafeSettings helper
│   └── logind-helper.vala    # [EXISTS] LogindHelper for pkexec
├── window.vala               # [MODIFY] Replace build_category_page() with factory calls
└── ...
```

### Pattern 1: Widget Factory Dispatch
**What:** Static class that maps SettingDef -> interactive Adwaita row widget
**When to use:** Every time a category page is built from SettingDef array

```vala
// Pattern: dispatch on WidgetHint enum
namespace ShadowSettings {
    public class WidgetFactory : Object {

        public static Gtk.Widget? create_row (SettingDef def, SchemaScanner scanner) {
            // Get GLib.Settings for this schema
            var settings = SafeSettings.try_get (def.schema_id);
            if (settings == null) return null;

            switch (def.widget_hint) {
                case WidgetHint.SWITCH:
                    return create_switch_row (def, settings);
                case WidgetHint.COMBO:
                    return create_combo_row (def, settings);
                case WidgetHint.SPIN_INT:
                    return create_spin_int_row (def, settings);
                case WidgetHint.SPIN_DOUBLE:
                    return create_spin_double_row (def, settings);
                case WidgetHint.FONT:
                    return create_font_row (def, settings);
                case WidgetHint.ENTRY:
                    return create_entry_row (def, settings);
                case WidgetHint.AUTO:
                    return create_auto_row (def, settings, scanner);
                case WidgetHint.CUSTOM:
                    return null; // Handled separately (e.g., PowerPanel)
                default:
                    return null;
            }
        }
    }
}
```

### Pattern 2: GSettings Binding for Booleans (SwitchRow)
**What:** Use `GLib.Settings.bind()` for automatic two-way sync
**When to use:** Boolean settings with SWITCH hint

```vala
// Source: Existing pattern from src/panels/desktop.vala
private static Adw.SwitchRow create_switch_row (SettingDef def, GLib.Settings settings) {
    var row = new Adw.SwitchRow ();
    row.title = def.label;
    if (def.subtitle != null) row.subtitle = def.subtitle;
    settings.bind (def.key, row, "active", SettingsBindFlags.DEFAULT);
    add_reset_action (row, def, settings);
    update_modified_state (row, def, settings);
    return row;
}
```

### Pattern 3: ComboRow with Labels/Values Arrays
**What:** Map combo_labels/combo_values from SettingDef to StringList + selection tracking
**When to use:** String settings with explicit choices

```vala
// Source: Existing pattern from src/panels/windows.vala and src/panels/appearance.vala
private static Adw.ComboRow create_combo_row (SettingDef def, GLib.Settings settings) {
    var model = new Gtk.StringList (null);
    foreach (var label in def.combo_labels) {
        model.append (label);
    }
    var combo = new Adw.ComboRow ();
    combo.title = def.label;
    if (def.subtitle != null) combo.subtitle = def.subtitle;
    combo.model = model;

    // Set initial selection
    var current = settings.get_string (def.key);
    for (int i = 0; i < def.combo_values.length; i++) {
        if (def.combo_values[i] == current) {
            combo.selected = i;
            break;
        }
    }

    // Write back on change
    combo.notify["selected"].connect (() => {
        if (combo.selected < def.combo_values.length) {
            settings.set_string (def.key, def.combo_values[combo.selected]);
        }
    });
    add_reset_action (combo, def, settings);
    update_modified_state (combo, def, settings);
    return combo;
}
```

### Pattern 4: SpinRow with Range Constraints
**What:** Use spin_min/spin_max/spin_step/spin_digits from SettingDef
**When to use:** Integer and double settings with bounded ranges

```vala
// Source: Existing pattern from src/panels/appearance.vala (text-scaling-factor)
private static Adw.SpinRow create_spin_int_row (SettingDef def, GLib.Settings settings) {
    var row = new Adw.SpinRow.with_range (def.spin_min, def.spin_max, def.spin_step);
    row.title = def.label;
    if (def.subtitle != null) row.subtitle = def.subtitle;
    row.digits = (uint) def.spin_digits;
    row.value = settings.get_int (def.key);
    row.notify["value"].connect (() => {
        settings.set_int (def.key, (int) row.value);
    });
    add_reset_action (row, def, settings);
    update_modified_state (row, def, settings);
    return row;
}
```

### Pattern 5: Reset-to-Default with Changed Highlighting
**What:** Add suffix button for reset + CSS class for visual indication
**When to use:** Every setting row

```vala
// Core reset pattern
private static void add_reset_action (Adw.ActionRow row, SettingDef def, GLib.Settings settings) {
    var user_val = settings.get_user_value (def.key);
    if (user_val != null) {
        row.add_css_class ("setting-modified");
    }

    // Reset button (only shown when modified, or always present)
    var reset_btn = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
    reset_btn.valign = Gtk.Align.CENTER;
    reset_btn.tooltip_text = "Reset to default";
    reset_btn.add_css_class ("flat");
    // Only show reset button when setting is modified
    reset_btn.visible = (user_val != null);

    reset_btn.clicked.connect (() => {
        settings.reset (def.key);
        row.remove_css_class ("setting-modified");
        reset_btn.visible = false;
        // Re-read value and update widget...
    });
    row.add_suffix (reset_btn);
}

// Changed state detection
private static void update_modified_state (Adw.ActionRow row, SettingDef def, GLib.Settings settings) {
    // Listen for changes to update highlight dynamically
    settings.changed[def.key].connect (() => {
        var uv = settings.get_user_value (def.key);
        if (uv != null) {
            row.add_css_class ("setting-modified");
        } else {
            row.remove_css_class ("setting-modified");
        }
    });
}
```

### Pattern 6: Font Row with FontDialogButton
**What:** ActionRow with FontDialogButton as suffix
**When to use:** FONT widget hint

```vala
// Source: Existing pattern from src/panels/appearance.vala
private static Adw.ActionRow create_font_row (SettingDef def, GLib.Settings settings) {
    var row = new Adw.ActionRow ();
    row.title = def.label;
    if (def.subtitle != null) row.subtitle = def.subtitle;

    var font_button = new Gtk.FontDialogButton (new Gtk.FontDialog ());
    font_button.valign = Gtk.Align.CENTER;
    var font_desc = Pango.FontDescription.from_string (settings.get_string (def.key));
    font_button.font_desc = font_desc;

    font_button.notify["font-desc"].connect (() => {
        var desc_str = font_button.font_desc.to_string ();
        settings.set_string (def.key, desc_str);
    });
    row.add_suffix (font_button);
    add_reset_action (row, def, settings);
    update_modified_state (row, def, settings);
    return row;
}
```

### Pattern 7: Lazy Panel Construction
**What:** Build widgets only on first panel visit, not on app startup
**When to use:** All category pages

```vala
// In window.vala construct block:
// Instead of building all pages upfront, store CategoryInfo and build on demand
private HashTable<string, bool> panels_built;

// When sidebar row selected:
sidebar_list.row_selected.connect ((row) => {
    if (row != null) {
        var panel_id = action_row.get_data<string> ("panel-id");
        if (!panels_built.contains (panel_id)) {
            // Find CategoryInfo for this panel_id and build it now
            var page = build_category_page_with_widgets (cat);
            content_stack.add_named (page, panel_id);
            panels_built[panel_id] = true;
        }
        content_stack.visible_child_name = panel_id;
    }
});
```

### Anti-Patterns to Avoid
- **Direct `new GLib.Settings()` without null-guard:** Always go through `SafeSettings.try_get()`. Widget factory receives `GLib.Settings` already validated.
- **Comparing `get_value()` vs `get_default_value()` to detect changes:** Use `get_user_value()` instead -- it returns `null` when no user override exists, which is the canonical detection method.
- **Building all panels in `construct`:** Violates NFR-2 (launch under 500ms). Use lazy construction.
- **Adding reset button via `set_suffix`:** Use `add_suffix()` to avoid replacing other suffixes (like FontDialogButton).
- **Using `set_css_classes` to add modified state:** This replaces ALL classes including GTK-internal ones. Use `add_css_class()`/`remove_css_class()` instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Changed detection | Value comparison loop | `GLib.Settings.get_user_value()` returns null when at default | Handles admin overrides, explicit-same-as-default correctly |
| Reset to default | Manual value restore | `GLib.Settings.reset(key)` | Respects admin overrides, emits proper signals |
| Boolean binding | Manual `notify` signal handler | `GLib.Settings.bind(key, row, "active", DEFAULT)` | Two-way, auto-unbinds on widget destroy |
| Range validation | Manual min/max clamping | `AdwSpinRow.with_range(min, max, step)` | GTK handles clamping, accessibility, keyboard input |
| Enum detection | Custom enum parsing | `SettingsSchemaKey.get_range()` returns `('enum', <[values]>)` | Only needed for AUTO hint; registry already declares combo_values |
| Font picker | Custom dialog | `Gtk.FontDialogButton` + `Gtk.FontDialog` | System-native, handles all Pango formats |

**Key insight:** The existing panels already solved every widget pattern. The factory generalizes these into data-driven dispatch -- no new widget patterns needed.

## Common Pitfalls

### Pitfall 1: GSettings Object Caching
**What goes wrong:** Creating a new `GLib.Settings` object for every row wastes memory and misses cross-row updates for the same schema.
**Why it happens:** Multiple SettingDefs can share the same `schema_id` (e.g., many keys from `org.gnome.desktop.interface`).
**How to avoid:** Cache `GLib.Settings` objects by schema_id in the factory. Use a `HashTable<string, GLib.Settings>` so all rows for the same schema share one object.
**Warning signs:** Memory spikes when building a category with many keys from the same schema.

### Pitfall 2: Signal Handler Leaks on Reset
**What goes wrong:** After `settings.reset(key)`, the `changed` signal fires, which triggers the widget update, which triggers the `notify["value"]` handler, which writes back to settings -- creating a feedback loop.
**Why it happens:** Two-way binding without loop protection.
**How to avoid:** For `bind()` (SWITCH rows), GSettings handles this automatically. For manual `notify` handlers (COMBO/SPIN), use a guard flag or disconnect/reconnect around reset. Alternatively, use `SettingsBindFlags.DEFAULT` which handles this.
**Warning signs:** Setting resets but immediately gets set back to the old value.

### Pitfall 3: AdwSpinRow Value Type Mismatch
**What goes wrong:** `SpinRow.value` is always `double`. Calling `settings.get_int()` for int keys and `settings.get_double()` for double keys requires different setter calls.
**Why it happens:** The SpinRow API is double-only; GSettings has typed getters/setters.
**How to avoid:** Separate `create_spin_int_row()` and `create_spin_double_row()` methods with appropriate `get_int()`/`set_int()` vs `get_double()`/`set_double()` calls. The WidgetHint enum already distinguishes SPIN_INT from SPIN_DOUBLE.
**Warning signs:** Integer values get stored as floating point in dconf.

### Pitfall 4: ComboRow Selected Index vs Value
**What goes wrong:** `ComboRow.selected` is a `uint` position, not the string value. If the current value doesn't match any combo_values entry, `selected` stays at 0 (wrong default).
**Why it happens:** GSettings value doesn't match any of the predefined combo_values.
**How to avoid:** After the matching loop, check if a match was found. If not, the setting may have an unexpected value -- leave selected at 0 or add the unknown value to the list.
**Warning signs:** Combo shows wrong initial value for settings with non-standard values.

### Pitfall 5: display_factor Field Not Connected
**What goes wrong:** The `display_factor` field in SettingDef exists but no registry entries currently set it, and no widget code reads it.
**Why it happens:** It was designed for settings like sleep timeouts (stored as seconds, display as minutes) but no such settings are in the current registry (the old hardcoded panels handled those inline).
**How to avoid:** If display_factor is 0.0 (default for unset double), treat it as 1.0 (no scaling). Only apply when non-zero.
**Warning signs:** SpinRow shows raw seconds instead of minutes for timeout values.

### Pitfall 6: Lazy Construction + First Category
**What goes wrong:** The first sidebar row is auto-selected but if lazy construction delays building the page, the user sees an empty content area.
**Why it happens:** `sidebar_list.select_row(...)` fires `row_selected` which tries to show the page before it's built.
**How to avoid:** Build the first category page eagerly (before sidebar selection), lazy-load the rest.
**Warning signs:** Blank content area on first launch.

### Pitfall 7: Removing Old Hardcoded Panels
**What goes wrong:** Removing `src/panels/*.vala` (except power.vala) from `meson.build` before the factory fully replaces their functionality.
**Why it happens:** The old panels have widget patterns the factory should replicate, but they're dead code once the factory works.
**How to avoid:** Keep old panel files in the tree during development for reference but remove them from `meson.build` once factory is verified. Or remove them in a clean-up task at the end.
**Warning signs:** Build errors from missing files, or dead code bloating the binary.

## Code Examples

### Reset Button with Dynamic Visibility

```vala
// Source: Verified against valadoc.org GLib.Settings.get_user_value, GLib.Settings.reset
private static Gtk.Button create_reset_button (Adw.ActionRow row, SettingDef def, GLib.Settings settings) {
    var btn = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
    btn.valign = Gtk.Align.CENTER;
    btn.add_css_class ("flat");
    btn.tooltip_text = "Reset to default";

    // Initial state
    btn.visible = (settings.get_user_value (def.key) != null);

    btn.clicked.connect (() => {
        settings.reset (def.key);
    });

    // Track changes
    settings.changed[def.key].connect (() => {
        var is_modified = settings.get_user_value (def.key) != null;
        btn.visible = is_modified;
        if (is_modified) {
            row.add_css_class ("setting-modified");
        } else {
            row.remove_css_class ("setting-modified");
        }
    });

    return btn;
}
```

### AUTO Widget Hint Resolution

```vala
// Source: Verified against valadoc.org GLib.SettingsSchemaKey.get_range, get_value_type
// For WidgetHint.AUTO: inspect the schema key at runtime to pick the right widget
private static Gtk.Widget? create_auto_row (SettingDef def, GLib.Settings settings, SchemaScanner scanner) {
    var key_info = scanner.get_key_info (def);
    if (key_info == null) return null;

    var type_str = key_info.get_value_type ().dup_string ();
    var range = key_info.get_range ();
    string range_type;
    Variant range_data;
    range.get ("(sv)", out range_type, out range_data);

    if (type_str == "b") {
        // Boolean -> SwitchRow
        var modified_def = def;
        modified_def.widget_hint = WidgetHint.SWITCH;
        return create_switch_row (modified_def, settings);
    } else if (range_type == "enum") {
        // Enum -> ComboRow (need to extract values from range_data)
        // range_data contains array of valid values
        var modified_def = def;
        modified_def.widget_hint = WidgetHint.COMBO;
        // ... extract combo_values from range_data variant array
        return create_combo_row (modified_def, settings);
    } else if (type_str == "i" || type_str == "u") {
        // Integer -> SpinRow
        var modified_def = def;
        modified_def.widget_hint = WidgetHint.SPIN_INT;
        if (range_type == "range") {
            // Extract min/max from range_data
            // range_data is (min, max) pair
        }
        return create_spin_int_row (modified_def, settings);
    } else if (type_str == "d") {
        // Double -> SpinRow
        var modified_def = def;
        modified_def.widget_hint = WidgetHint.SPIN_DOUBLE;
        return create_spin_double_row (modified_def, settings);
    } else if (type_str == "s") {
        // String -> EntryRow
        var modified_def = def;
        modified_def.widget_hint = WidgetHint.ENTRY;
        return create_entry_row (modified_def, settings);
    }

    return null; // Unknown type, skip
}
```

### EntryRow for String Settings

```vala
// Source: Verified against valadoc.org Adw.EntryRow
private static Adw.EntryRow create_entry_row (SettingDef def, GLib.Settings settings) {
    var row = new Adw.EntryRow ();
    row.title = def.label;
    // EntryRow implements Gtk.Editable -- use set_text/get_text
    row.set_text (settings.get_string (def.key));
    row.show_apply_button = true; // Only commit on Enter/Apply

    row.apply.connect (() => {
        settings.set_string (def.key, row.get_text ());
    });

    add_reset_action (row, def, settings);
    update_modified_state (row, def, settings);
    return row;
}
```

### GSettings Object Cache

```vala
// Cache GLib.Settings objects by schema_id to avoid duplicates
private static HashTable<string, GLib.Settings> settings_cache;

private static GLib.Settings? get_cached_settings (string schema_id) {
    if (settings_cache == null) {
        settings_cache = new HashTable<string, GLib.Settings> (str_hash, str_equal);
    }
    var cached = settings_cache.lookup (schema_id);
    if (cached != null) return cached;

    var settings = SafeSettings.try_get (schema_id);
    if (settings != null) {
        settings_cache.insert (schema_id, settings);
    }
    return settings;
}
```

## State of the Art

| Old Approach (Current Hardcoded Panels) | New Approach (Widget Factory) | When Changed | Impact |
|------------------------------------------|-------------------------------|--------------|--------|
| One class per category panel with manual widget construction | Single WidgetFactory dispatching from SettingDef | Phase 3 | Eliminates 5 panel files (~500 lines), makes adding settings = adding registry entries |
| No reset-to-default capability | `GLib.Settings.reset()` + `get_user_value()` for detection | Phase 3 | Addresses FR-5 completely |
| No changed-setting indication | CSS class `setting-modified` on rows with user overrides | Phase 3 | Addresses FR-5 highlighting requirement |
| Panels built eagerly in construct | Lazy construction on first sidebar visit | Phase 3 | Addresses NFR-2 launch time |

**Deprecated/outdated:**
- `Gtk.StyleContext.add_class()`: Deprecated in GTK4. Use `Gtk.Widget.add_css_class()` directly.
- Old panels (`src/panels/desktop.vala`, `windows.vala`, `appearance.vala`, `input.vala`): Will be replaced by factory-generated UI. `power.vala` stays for CUSTOM/logind handling.

## Open Questions

1. **EntryRow: show_apply_button behavior**
   - What we know: `show_apply_button = true` adds an apply button and `apply` signal fires on Enter/click
   - What's unclear: Whether the apply button is visually appropriate for the Shadow Settings design
   - Recommendation: Use `show_apply_button = true` -- it prevents every keystroke from writing to dconf, which is the safe default for string settings

2. **display_factor usage**
   - What we know: Field exists in SettingDef but no registry entries currently set it (default is 0.0)
   - What's unclear: Whether any current registry entries need display_factor (old hardcoded panels had seconds->minutes conversion but those settings aren't in the registry)
   - Recommendation: Implement support (treat 0.0 as 1.0 = no scaling), but don't worry about it until a registry entry actually uses it

3. **Old panel removal timing**
   - What we know: Panels in `src/panels/` (desktop, windows, appearance, input) become dead code once factory works
   - What's unclear: Whether to remove them in this phase or a cleanup task
   - Recommendation: Remove from meson.build in this phase (they aren't referenced from window.vala anymore once factory replaces build_category_page). Keep power.vala.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual testing (Vala/GTK4 app -- no unit test framework in project) |
| Config file | none |
| Quick run command | `cd builddir && ninja && ./shadow-settings` |
| Full suite command | `meson setup builddir --wipe && ninja -C builddir && ./builddir/shadow-settings` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-3-a | Boolean settings render as SwitchRow | manual | Launch app, navigate to Privacy category, verify switches | N/A |
| FR-3-b | Combo settings render as ComboRow | manual | Navigate to Windows > Titlebar Actions, verify dropdowns | N/A |
| FR-3-c | SpinInt settings render as SpinRow | manual | Navigate to Windows > Focus > Auto-Raise Delay, verify spinner | N/A |
| FR-3-d | Font settings render with FontDialogButton | manual | Navigate to Appearance > Fonts, verify font picker buttons | N/A |
| FR-3-e | Entry settings render as EntryRow | manual | Navigate to Windows > Behavior > Window Drag Modifier, verify text entry | N/A |
| FR-3-f | Title/subtitle from SettingDef displayed | manual | Every row shows label + subtitle from registry | N/A |
| FR-3-g | Range constraints enforced | manual | SpinRow cannot exceed spin_min/spin_max | N/A |
| FR-5-a | Reset button visible on modified settings | manual | Change a setting, verify undo button appears | N/A |
| FR-5-b | Reset restores default value | manual | Click reset button, verify setting returns to default | N/A |
| FR-5-c | Changed settings have CSS class | manual | Change a setting, inspect with GTK Inspector for `setting-modified` class | N/A |
| FR-7 | Power category hidden in Flatpak | manual | Verify `/.flatpak-info` check hides Power sidebar entry | N/A |
| NFR-2-lazy | Panels constructed lazily | manual | Set breakpoint/print in build function, verify only called on navigation | N/A |

### Sampling Rate
- **Per task commit:** `cd builddir && ninja && ./shadow-settings` (verify build + manual check)
- **Per wave merge:** Full rebuild with `meson setup builddir --wipe && ninja -C builddir`
- **Phase gate:** All widget types render correctly, reset works, changed highlighting works

### Wave 0 Gaps
None -- no test infrastructure to set up for manual testing. Build verification is sufficient.

## Sources

### Primary (HIGH confidence)
- [valadoc.org/gio-2.0/GLib.Settings](https://valadoc.org/gio-2.0/GLib.Settings.html) - reset(), get_user_value(), get_default_value(), bind() APIs
- [valadoc.org/gio-2.0/GLib.Settings.reset](https://valadoc.org/gio-2.0/GLib.Settings.reset.html) - Reset to default behavior
- [valadoc.org/gio-2.0/GLib.Settings.get_user_value](https://valadoc.org/gio-2.0/GLib.Settings.get_user_value.html) - Changed detection (null = at default)
- [valadoc.org/gio-2.0/GLib.SettingsSchemaKey](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.html) - get_range(), get_value_type(), get_summary(), get_description()
- [valadoc.org/libadwaita-1/Adw.SwitchRow](https://valadoc.org/libadwaita-1/Adw.SwitchRow.html) - SwitchRow API (active property)
- [valadoc.org/libadwaita-1/Adw.SpinRow](https://valadoc.org/libadwaita-1/Adw.SpinRow.html) - SpinRow API (with_range constructor, digits, value)
- [valadoc.org/libadwaita-1/Adw.ComboRow](https://valadoc.org/libadwaita-1/Adw.ComboRow.html) - ComboRow API (model, selected, expression)
- [valadoc.org/libadwaita-1/Adw.EntryRow](https://valadoc.org/libadwaita-1/Adw.EntryRow.html) - EntryRow API (show_apply_button, apply signal)
- [valadoc.org/gtk4/Gtk.FontDialogButton](https://valadoc.org/gtk4/Gtk.FontDialogButton.html) - FontDialogButton API
- [docs.gtk.org/gtk4/method.Widget.add_css_class](https://docs.gtk.org/gtk4/method.Widget.add_css_class.html) - CSS class manipulation
- Existing codebase: `src/panels/*.vala` - Working reference implementations for all widget patterns

### Secondary (MEDIUM confidence)
- [docs.gtk.org/gio/method.Settings.get_default_value](https://docs.gtk.org/gio/method.Settings.get_default_value.html) - Default value retrieval semantics
- [SettingsSchemaKey.get_range documentation](https://valadoc.org/gio-2.0/GLib.SettingsSchemaKey.get_range.html) - Range format (sv) with type/enum/flags/range variants

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All APIs verified in valadoc.org, already used in project
- Architecture: HIGH - Widget factory pattern is straightforward dispatch; existing panels prove every pattern works
- Pitfalls: HIGH - Signal loops and type mismatches are well-known GTK/GSettings issues; existing code demonstrates solutions

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable GTK4/libadwaita APIs, no upcoming breaking changes expected)
