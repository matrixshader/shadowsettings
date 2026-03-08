namespace ShadowSettings {

    /**
     * WidgetFactory: Maps each WidgetHint enum value to the correct interactive
     * Adwaita row widget with GSettings bindings, reset-to-default, and
     * changed-settings highlighting.
     *
     * Entry point: create_row(SettingDef, SchemaScanner) -> Gtk.Widget?
     */
    public class WidgetFactory : Object {

        /* GSettings object cache -- avoids duplicates per schema_id */
        private static HashTable<string, GLib.Settings> settings_cache;

        /**
         * Main entry point: create the appropriate row widget for a SettingDef.
         * Returns null if the schema is unavailable or hint is CUSTOM.
         */
        public static Gtk.Widget? create_row (SettingDef def, SchemaScanner scanner) {
            var settings = get_cached_settings (def.schema_id);
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
                    return null;
                default:
                    return null;
            }
        }

        /* ---- GSettings cache ---- */

        private static GLib.Settings? get_cached_settings (string schema_id) {
            if (settings_cache == null) {
                settings_cache = new HashTable<string, GLib.Settings> (str_hash, str_equal);
            }
            var cached = settings_cache.lookup (schema_id);
            if (cached != null) return cached;

            var s = SafeSettings.try_get (schema_id);
            if (s != null) {
                settings_cache.insert (schema_id, s);
            }
            return s;
        }

        /* ---- Widget creators ---- */

        private static Adw.SwitchRow create_switch_row (SettingDef def, GLib.Settings settings) {
            var row = new Adw.SwitchRow ();
            row.title = def.label;
            if (def.subtitle != null) row.subtitle = def.subtitle;
            settings.bind (def.key, row, "active", SettingsBindFlags.DEFAULT);
            attach_reset_and_tracking (row, def, settings);
            return row;
        }

        private static Adw.ComboRow create_combo_row (SettingDef def, GLib.Settings settings) {
            var model = new Gtk.StringList (null);
            if (def.combo_labels != null) {
                foreach (var label in def.combo_labels) {
                    model.append (label);
                }
            }

            var combo = new Adw.ComboRow ();
            combo.title = def.label;
            if (def.subtitle != null) combo.subtitle = def.subtitle;
            combo.model = model;

            /* Set initial selection by matching current value to combo_values */
            if (def.combo_values != null) {
                var current = settings.get_string (def.key);
                for (int i = 0; i < def.combo_values.length; i++) {
                    if (def.combo_values[i] == current) {
                        combo.selected = i;
                        break;
                    }
                }
            }

            /* Write back on change */
            combo.notify["selected"].connect (() => {
                if (def.combo_values != null && combo.selected < def.combo_values.length) {
                    var new_val = def.combo_values[combo.selected];
                    var cur_val = settings.get_string (def.key);
                    if (new_val != cur_val) {
                        settings.set_string (def.key, new_val);
                    }
                }
            });

            /* Update combo selection when setting changes externally (e.g. reset) */
            settings.changed[def.key].connect (() => {
                if (def.combo_values != null) {
                    var val = settings.get_string (def.key);
                    for (int i = 0; i < def.combo_values.length; i++) {
                        if (def.combo_values[i] == val) {
                            if (combo.selected != i) {
                                combo.selected = i;
                            }
                            break;
                        }
                    }
                }
            });

            attach_reset_and_tracking (combo, def, settings);
            return combo;
        }

        private static Adw.SpinRow create_spin_int_row (SettingDef def, GLib.Settings settings) {
            var row = new Adw.SpinRow.with_range (def.spin_min, def.spin_max, def.spin_step);
            row.title = def.label;
            if (def.subtitle != null) row.subtitle = def.subtitle;
            row.digits = (uint) def.spin_digits;

            double factor = (def.display_factor != 0.0) ? def.display_factor : 1.0;
            row.value = settings.get_int (def.key) * factor;

            row.notify["value"].connect (() => {
                int new_val = (int) (row.value / factor);
                if (settings.get_int (def.key) != new_val) {
                    settings.set_int (def.key, new_val);
                }
            });

            /* Update spin value when setting changes externally (e.g. reset) */
            settings.changed[def.key].connect (() => {
                double displayed = settings.get_int (def.key) * factor;
                if (row.value != displayed) {
                    row.value = displayed;
                }
            });

            attach_reset_and_tracking (row, def, settings);
            return row;
        }

        private static Adw.SpinRow create_spin_double_row (SettingDef def, GLib.Settings settings) {
            var row = new Adw.SpinRow.with_range (def.spin_min, def.spin_max, def.spin_step);
            row.title = def.label;
            if (def.subtitle != null) row.subtitle = def.subtitle;
            row.digits = (uint) def.spin_digits;

            double factor = (def.display_factor != 0.0) ? def.display_factor : 1.0;
            row.value = settings.get_double (def.key) * factor;

            row.notify["value"].connect (() => {
                double new_val = row.value / factor;
                if (settings.get_double (def.key) != new_val) {
                    settings.set_double (def.key, new_val);
                }
            });

            /* Update spin value when setting changes externally (e.g. reset) */
            settings.changed[def.key].connect (() => {
                double displayed = settings.get_double (def.key) * factor;
                if (row.value != displayed) {
                    row.value = displayed;
                }
            });

            attach_reset_and_tracking (row, def, settings);
            return row;
        }

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

            /* Update font button when setting changes externally (e.g. reset) */
            settings.changed[def.key].connect (() => {
                var new_desc = Pango.FontDescription.from_string (settings.get_string (def.key));
                font_button.font_desc = new_desc;
            });

            row.add_suffix (font_button);
            attach_reset_and_tracking (row, def, settings);
            return row;
        }

        private static Adw.EntryRow create_entry_row (SettingDef def, GLib.Settings settings) {
            var row = new Adw.EntryRow ();
            row.title = def.label;
            if (def.subtitle != null) row.tooltip_text = def.subtitle;
            row.show_apply_button = true;
            row.set_text (settings.get_string (def.key));

            row.apply.connect (() => {
                settings.set_string (def.key, row.get_text ());
            });

            /* Update entry text when setting changes externally (e.g. reset) */
            settings.changed[def.key].connect (() => {
                var new_text = settings.get_string (def.key);
                if (row.get_text () != new_text) {
                    row.set_text (new_text);
                }
            });

            attach_reset_and_tracking_entry (row, def, settings);
            return row;
        }

        /* ---- AUTO hint resolution ---- */

        private static Gtk.Widget? create_auto_row (SettingDef def, GLib.Settings settings, SchemaScanner scanner) {
            var key_info = scanner.get_key_info (def);
            if (key_info == null) return null;

            var type_str = key_info.get_value_type ().dup_string ();
            var range = key_info.get_range ();
            string range_type;
            Variant range_data;
            range.get ("(sv)", out range_type, out range_data);

            if (type_str == "b") {
                return create_switch_row (def, settings);
            } else if (type_str == "s") {
                if (range_type == "enum") {
                    /* Extract enum values to build a combo row */
                    var modified_def = def;
                    var iter = range_data.iterator ();
                    string[] values = {};
                    string[] labels = {};
                    Variant? child;
                    while ((child = iter.next_value ()) != null) {
                        var val = child.get_string ();
                        values += val;
                        /* Capitalize first letter as label */
                        if (val.length > 0) {
                            labels += val.substring (0, 1).up () + val.substring (1).replace ("-", " ").replace ("_", " ");
                        } else {
                            labels += val;
                        }
                    }
                    modified_def.combo_labels = labels;
                    modified_def.combo_values = values;
                    return create_combo_row (modified_def, settings);
                } else {
                    return create_entry_row (def, settings);
                }
            } else if (type_str == "i" || type_str == "u") {
                var modified_def = def;
                if (range_type == "range") {
                    var min_v = range_data.get_child_value (0);
                    var max_v = range_data.get_child_value (1);
                    if (type_str == "i") {
                        modified_def.spin_min = (double) min_v.get_int32 ();
                        modified_def.spin_max = (double) max_v.get_int32 ();
                    } else {
                        modified_def.spin_min = (double) min_v.get_uint32 ();
                        modified_def.spin_max = (double) max_v.get_uint32 ();
                    }
                    if (modified_def.spin_step == 0.0) modified_def.spin_step = 1.0;
                }
                return create_spin_int_row (modified_def, settings);
            } else if (type_str == "d") {
                var modified_def = def;
                if (range_type == "range") {
                    var min_v = range_data.get_child_value (0);
                    var max_v = range_data.get_child_value (1);
                    modified_def.spin_min = min_v.get_double ();
                    modified_def.spin_max = max_v.get_double ();
                    if (modified_def.spin_step == 0.0) modified_def.spin_step = 0.1;
                    if (modified_def.spin_digits == 0) modified_def.spin_digits = 2;
                }
                return create_spin_double_row (modified_def, settings);
            }

            return null;
        }

        /* ---- Reset button and modified state tracking ---- */

        /**
         * Adds a reset-to-default button as suffix and connects changed signal
         * for dynamic CSS class tracking.
         */
        private static void attach_reset_and_tracking (Adw.ActionRow row, SettingDef def, GLib.Settings settings) {
            var reset_btn = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
            reset_btn.valign = Gtk.Align.CENTER;
            reset_btn.add_css_class ("flat");
            reset_btn.tooltip_text = "Reset to default";

            /* Initial state */
            var is_modified = settings.get_user_value (def.key) != null;
            reset_btn.visible = is_modified;
            if (is_modified) {
                row.add_css_class ("setting-modified");
            }

            reset_btn.clicked.connect (() => {
                settings.reset (def.key);
            });

            /* Track changes dynamically */
            settings.changed[def.key].connect (() => {
                var modified = settings.get_user_value (def.key) != null;
                reset_btn.visible = modified;
                if (modified) {
                    row.add_css_class ("setting-modified");
                } else {
                    row.remove_css_class ("setting-modified");
                }
            });

            row.add_suffix (reset_btn);
        }

        /**
         * EntryRow overload -- EntryRow extends PreferencesRow, not ActionRow,
         * so it has its own add_suffix() method.
         */
        private static void attach_reset_and_tracking_entry (Adw.EntryRow row, SettingDef def, GLib.Settings settings) {
            var reset_btn = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
            reset_btn.valign = Gtk.Align.CENTER;
            reset_btn.add_css_class ("flat");
            reset_btn.tooltip_text = "Reset to default";

            /* Initial state */
            var is_modified = settings.get_user_value (def.key) != null;
            reset_btn.visible = is_modified;
            if (is_modified) {
                row.add_css_class ("setting-modified");
            }

            reset_btn.clicked.connect (() => {
                settings.reset (def.key);
            });

            /* Track changes dynamically */
            settings.changed[def.key].connect (() => {
                var modified = settings.get_user_value (def.key) != null;
                reset_btn.visible = modified;
                if (modified) {
                    row.add_css_class ("setting-modified");
                } else {
                    row.remove_css_class ("setting-modified");
                }
            });

            row.add_suffix (reset_btn);
        }
    }
}
