namespace ShadowSettings {

    public class SchemaScanner : Object {
        private GLib.SettingsSchemaSource source;

        public int total_scanned { get; private set; default = 0; }
        public int total_available { get; private set; default = 0; }

        /**
         * Schema prefixes that represent GNOME system/desktop settings.
         */
        private const string[] SYSTEM_PREFIXES = {
            "org.gnome.desktop.",
            "org.gnome.settings-daemon.",
            "org.gnome.mutter",
            "org.gnome.shell",
            "org.gnome.SessionManager"
        };

        /**
         * Keys that existed in GTK2/GTK3 but have no effect in modern GNOME.
         * Format: "schema.id:key-name"
         */
        private const string[] DEPRECATED_KEYS = {
            "org.gnome.desktop.interface:can-change-accels",
            "org.gnome.desktop.interface:gtk-color-palette",
            "org.gnome.desktop.interface:gtk-color-scheme",
            "org.gnome.desktop.interface:gtk-im-module",
            "org.gnome.desktop.interface:gtk-im-preedit-style",
            "org.gnome.desktop.interface:gtk-im-status-style",
            "org.gnome.desktop.interface:gtk-key-theme",
            "org.gnome.desktop.interface:menubar-accel",
            "org.gnome.desktop.interface:menubar-detachable",
            "org.gnome.desktop.interface:menus-have-tearoff",
            "org.gnome.desktop.interface:toolbar-detachable",
            "org.gnome.desktop.interface:toolbar-icons-size",
            "org.gnome.desktop.interface:toolbar-style",
            "org.gnome.desktop.interface:scaling-factor"
        };

        public SchemaScanner () {
            this.source = GLib.SettingsSchemaSource.get_default ();
        }

        /**
         * True auto-discovery: enumerates ALL GSettings schemas on the system,
         * auto-generates SettingDef entries from schema metadata, and layers
         * curated overrides on top for better labels where available.
         *
         * The only filter is type-based: we skip array/tuple/dict types because
         * there is no widget to render them. Everything else is shown.
         */
        public SettingDef[] discover_all (SettingDef[]? curated_overrides = null) {
            // Build lookup index for curated overrides
            var curated_map = new HashTable<string, SettingDef?> (str_hash, str_equal);
            if (curated_overrides != null) {
                foreach (var def in curated_overrides) {
                    var lookup_key = "%s:%s".printf (def.schema_id, def.key);
                    curated_map.insert (lookup_key, def);
                }
            }

            // Enumerate all non-relocatable schemas on the system
            string[] non_relocatable;
            string[] relocatable;
            source.list_schemas (true, out non_relocatable, out relocatable);

            // Separate curated (top) from auto-discovered (below)
            var curated_found = new GenericArray<SettingDef?> ();
            var auto_found = new GenericArray<SettingDef?> ();
            // Track which curated keys were found so we can add unmatched curated entries too
            var curated_seen = new HashTable<string, bool> (str_hash, str_equal);
            int scanned = 0;

            foreach (var schema_id in non_relocatable) {
                // Only include system/desktop schemas
                if (!is_system_schema (schema_id)) continue;

                var schema = source.lookup (schema_id, true);
                if (schema == null) continue;

                foreach (var key in schema.list_keys ()) {
                    scanned++;

                    // Skip deprecated keys that have no effect in modern GNOME
                    if (is_deprecated_key (schema_id, key)) continue;

                    // Check for curated override
                    var full_key = "%s:%s".printf (schema_id, key);
                    var curated = curated_map.lookup (full_key);
                    if (curated != null) {
                        curated_found.add (curated);
                        curated_seen.insert (full_key, true);
                        continue;
                    }

                    // Auto-generate SettingDef from schema metadata
                    var key_info = schema.get_key (key);
                    var type_str = key_info.get_value_type ().dup_string ();

                    // Skip types we can't render (arrays, tuples, dicts)
                    if (!is_renderable_type (type_str)) continue;

                    var summary = key_info.get_summary ();
                    var description = key_info.get_description ();
                    var category = categorize_schema (schema_id);

                    var def = SettingDef () {
                        schema_id = schema_id,
                        key = key,
                        label = (summary != null && summary.length > 0)
                            ? summary : humanize_key_name (key),
                        subtitle = description,
                        category = category,
                        group = group_from_schema (schema_id),
                        category_icon = icon_for_category (category),
                        widget_hint = WidgetHint.AUTO
                    };

                    auto_found.add (def);
                }
            }

            // Curated first, then auto-discovered
            total_scanned = scanned;
            total_available = curated_found.length + auto_found.length;

            var result = new SettingDef[total_available];
            int idx = 0;
            for (int i = 0; i < curated_found.length; i++) {
                result[idx++] = curated_found[i];
            }
            for (int i = 0; i < auto_found.length; i++) {
                result[idx++] = auto_found[i];
            }
            return result;
        }

        /**
         * Returns the SettingsSchemaKey for a given SettingDef, or null if
         * the schema or key doesn't exist on this system.
         */
        public GLib.SettingsSchemaKey? get_key_info (SettingDef def) {
            var schema = source.lookup (def.schema_id, true);
            if (schema == null) return null;
            if (!schema.has_key (def.key)) return null;
            return schema.get_key (def.key);
        }

        /* ---- Private helpers ---- */

        private bool is_deprecated_key (string schema_id, string key) {
            var full_key = "%s:%s".printf (schema_id, key);
            foreach (var deprecated in DEPRECATED_KEYS) {
                if (full_key == deprecated) return true;
            }
            return false;
        }

        private bool is_system_schema (string schema_id) {
            foreach (var prefix in SYSTEM_PREFIXES) {
                if (schema_id.has_prefix (prefix) || schema_id == prefix) {
                    return true;
                }
            }
            return false;
        }

        private bool is_renderable_type (string type_str) {
            // We can render: booleans, strings, integers, unsigned ints, doubles
            return type_str == "b" || type_str == "s" ||
                   type_str == "i" || type_str == "u" || type_str == "d";
        }

        /**
         * Maps schema namespace to a user-facing category.
         */
        private string categorize_schema (string schema_id) {
            if (schema_id.has_prefix ("org.gnome.settings-daemon.plugins.power")) return "Power";
            if (schema_id.has_prefix ("org.gnome.desktop.session")) return "Power";

            if (schema_id.has_prefix ("org.gnome.desktop.peripherals")) return "Input";
            if (schema_id.has_prefix ("org.gnome.desktop.input-sources")) return "Input";

            if (schema_id.has_prefix ("org.gnome.desktop.wm")) return "Windows";
            if (schema_id.has_prefix ("org.gnome.mutter")) return "Windows";

            if (schema_id.has_prefix ("org.gnome.desktop.interface")) return "Appearance";
            if (schema_id.has_prefix ("org.gnome.desktop.background")) return "Appearance";
            if (schema_id.has_prefix ("org.gnome.settings-daemon.plugins.color")) return "Appearance";
            if (schema_id.has_prefix ("org.gnome.settings-daemon.plugins.housekeeping")) return "Appearance";

            if (schema_id.has_prefix ("org.gnome.desktop.a11y")) return "Accessibility";

            if (schema_id.has_prefix ("org.gnome.desktop.lockdown")) return "Privacy";
            if (schema_id.has_prefix ("org.gnome.desktop.privacy")) return "Privacy";
            if (schema_id.has_prefix ("org.gnome.desktop.notifications")) return "Privacy";
            if (schema_id.has_prefix ("org.gnome.desktop.media-handling")) return "Privacy";
            if (schema_id.has_prefix ("org.gnome.desktop.file-sharing")) return "Privacy";

            // Default bucket
            return "Desktop";
        }

        /**
         * Generates a human-readable group name from the schema ID.
         */
        private string group_from_schema (string schema_id) {
            var name = schema_id;
            if (name.has_prefix ("org.gnome.desktop.")) {
                name = name.substring ("org.gnome.desktop.".length);
            } else if (name.has_prefix ("org.gnome.settings-daemon.plugins.")) {
                name = name.substring ("org.gnome.settings-daemon.plugins.".length);
            } else if (name.has_prefix ("org.gnome.")) {
                name = name.substring ("org.gnome.".length);
            }

            // Replace dots/hyphens with spaces and capitalize words
            name = name.replace (".", " ").replace ("-", " ");
            var words = name.split (" ");
            var result = new StringBuilder ();
            foreach (var word in words) {
                if (word.length > 0) {
                    if (result.len > 0) result.append (" ");
                    result.append (word.substring (0, 1).up ());
                    if (word.length > 1) result.append (word.substring (1));
                }
            }
            return result.str;
        }

        /**
         * Convert a GSettings key name like "idle-dim" to "Idle Dim".
         */
        private string humanize_key_name (string key) {
            var words = key.replace ("-", " ").replace ("_", " ").split (" ");
            var result = new StringBuilder ();
            foreach (var word in words) {
                if (word.length > 0) {
                    if (result.len > 0) result.append (" ");
                    result.append (word.substring (0, 1).up ());
                    if (word.length > 1) result.append (word.substring (1));
                }
            }
            return result.str;
        }

        private string icon_for_category (string category) {
            switch (category) {
                case "Power": return "system-shutdown-symbolic";
                case "Input": return "input-keyboard-symbolic";
                case "Windows": return "preferences-system-windows-symbolic";
                case "Appearance": return "preferences-desktop-appearance-symbolic";
                case "Accessibility": return "preferences-desktop-accessibility-symbolic";
                case "Privacy": return "preferences-system-privacy-symbolic";
                case "Desktop": return "preferences-desktop-wallpaper-symbolic";
                default: return "preferences-other-symbolic";
            }
        }
    }
}
