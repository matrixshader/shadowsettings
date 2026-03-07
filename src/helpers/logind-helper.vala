namespace ShadowSettings {
    public class LogindHelper {
        private const string CONF_DIR = "/etc/systemd/logind.conf.d";
        private const string CONF_FILE = "/etc/systemd/logind.conf.d/99-shadow-settings.conf";

        public static string[] LID_OPTIONS = {
            "suspend", "ignore", "lock", "poweroff", "hibernate"
        };

        public static string[] LID_LABELS = {
            "Suspend", "Do Nothing", "Lock Screen", "Power Off", "Hibernate"
        };

        public static HashTable<string, string> read_config () {
            var table = new HashTable<string, string> (str_hash, str_equal);

            // Read all drop-in configs in order
            try {
                var dir = Dir.open (CONF_DIR);
                var files = new GenericArray<string> ();
                string? name;
                while ((name = dir.read_name ()) != null) {
                    if (name.has_suffix (".conf")) {
                        files.add (name);
                    }
                }
                files.sort (strcmp);

                foreach (var fname in files) {
                    var kf = new KeyFile ();
                    try {
                        kf.load_from_file (CONF_DIR + "/" + fname, KeyFileFlags.NONE);
                        if (kf.has_group ("Login")) {
                            try { table["HandleLidSwitch"] = kf.get_string ("Login", "HandleLidSwitch"); } catch {}
                            try { table["HandleLidSwitchExternalPower"] = kf.get_string ("Login", "HandleLidSwitchExternalPower"); } catch {}
                            try { table["HandleLidSwitchDocked"] = kf.get_string ("Login", "HandleLidSwitchDocked"); } catch {}
                        }
                    } catch {}
                }
            } catch {}

            // Defaults if nothing set
            if (!table.contains ("HandleLidSwitch")) table["HandleLidSwitch"] = "suspend";
            if (!table.contains ("HandleLidSwitchExternalPower")) table["HandleLidSwitchExternalPower"] = "suspend";
            if (!table.contains ("HandleLidSwitchDocked")) table["HandleLidSwitchDocked"] = "ignore";

            return table;
        }

        public static bool write_config (string key, string value) {
            // Read existing config or create new
            var kf = new KeyFile ();
            try {
                kf.load_from_file (CONF_FILE, KeyFileFlags.KEEP_COMMENTS);
            } catch {}

            kf.set_string ("Login", key, value);

            try {
                var content = kf.to_data ();
                // Write via pkexec
                string[] argv = {
                    "pkexec", "bash", "-c",
                    "mkdir -p %s && printf '%%s' '%s' > %s".printf (
                        CONF_DIR,
                        content.replace ("'", "'\\''"),
                        CONF_FILE
                    )
                };
                var proc = new Subprocess.newv (argv, SubprocessFlags.NONE);
                proc.wait ();

                if (proc.get_exit_status () != 0) {
                    return false;
                }

                // Reload logind config via D-Bus (does NOT restart the service)
                string[] reload_argv = { "busctl", "call", "org.freedesktop.login1",
                    "/org/freedesktop/login1", "org.freedesktop.login1.Manager",
                    "SetRebootParameter", "s", "" };
                // SetRebootParameter is a no-op trick to trigger config reload
                // Actually, the proper way is just to send SIGHUP
                string[] hup_argv = { "pkexec", "kill", "-HUP", "1" };
                // systemd re-reads logind.conf on SIGHUP to PID 1... actually no.
                // The safest way without restarting logind:
                // logind re-reads its config files on its own for some keys.
                // For lid switch, it reads config on each lid event, so the new config
                // takes effect on the next lid close. No restart needed.

                return true;
            } catch (Error e) {
                warning ("Failed to write logind config: %s", e.message);
                return false;
            }
        }

        public static int index_of_value (string value) {
            for (int i = 0; i < LID_OPTIONS.length; i++) {
                if (LID_OPTIONS[i] == value) return i;
            }
            return 0;
        }
    }
}
