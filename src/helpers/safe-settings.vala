namespace ShadowSettings {
    public class SafeSettings {
        private static GLib.SettingsSchemaSource? _source;

        public static GLib.SettingsSchemaSource get_source () {
            if (_source == null) {
                _source = GLib.SettingsSchemaSource.get_default ();
            }
            return _source;
        }

        public static GLib.Settings? try_get (string schema_id) {
            var schema = get_source ().lookup (schema_id, true);
            if (schema == null) {
                warning ("Schema '%s' not found on this system, skipping", schema_id);
                return null;
            }
            return new GLib.Settings (schema_id);
        }

        public static bool has_key (string schema_id, string key) {
            var schema = get_source ().lookup (schema_id, true);
            if (schema == null) return false;
            foreach (var k in schema.list_keys ()) {
                if (k == key) return true;
            }
            return false;
        }
    }
}
