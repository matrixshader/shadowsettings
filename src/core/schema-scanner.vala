namespace ShadowSettings {

    public class SchemaScanner : Object {
        private GLib.SettingsSchemaSource source;

        public int total_scanned { get; private set; default = 0; }
        public int total_available { get; private set; default = 0; }

        public SchemaScanner () {
            this.source = GLib.SettingsSchemaSource.get_default ();
        }

        /**
         * Scans the registry of setting definitions and returns only those
         * whose schema and key exist on the running system.
         */
        public SettingDef[] scan (SettingDef[] registry) {
            var available = new GenericArray<SettingDef?> ();
            total_scanned = registry.length;

            foreach (var def in registry) {
                var schema = source.lookup (def.schema_id, true);
                if (schema == null) {
                    continue;
                }
                if (!schema.has_key (def.key)) {
                    continue;
                }
                available.add (def);
            }

            total_available = available.length;

            var result = new SettingDef[available.length];
            for (int i = 0; i < available.length; i++) {
                result[i] = available[i];
            }
            return result;
        }

        /**
         * Returns the SettingsSchemaKey for a given SettingDef, or null if
         * the schema or key doesn't exist on this system.
         * Always checks has_key() before get_key() to avoid abort on missing key.
         */
        public GLib.SettingsSchemaKey? get_key_info (SettingDef def) {
            var schema = source.lookup (def.schema_id, true);
            if (schema == null) {
                return null;
            }
            if (!schema.has_key (def.key)) {
                return null;
            }
            return schema.get_key (def.key);
        }
    }
}
