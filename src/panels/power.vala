namespace ShadowSettings {
    public class PowerPanel : Adw.PreferencesPage {

        private const string[] LID_LABELS = { "Suspend", "Do Nothing", "Lock Screen", "Power Off" };
        private const string[] LID_VALUES = { "suspend", "ignore", "lock", "poweroff" };

        construct {
            title = "Power";
            icon_name = "system-shutdown-symbolic";

            var power_settings = SafeSettings.try_get ("org.gnome.settings-daemon.plugins.power");
            var session_settings = SafeSettings.try_get ("org.gnome.desktop.session");

            // --- Lid Close Group (uses LogindHelper, NOT GSettings) ---
            var lid_group = new Adw.PreferencesGroup ();
            lid_group.title = "Lid Close Behavior";
            lid_group.description = "What happens when you close the laptop lid";

            var config = LogindHelper.read_config ();

            var lid_battery = make_lid_combo ("On Battery", "HandleLidSwitch", config);
            lid_group.add (lid_battery);

            var lid_ac = make_lid_combo ("On AC Power", "HandleLidSwitchExternalPower", config);
            lid_group.add (lid_ac);

            add (lid_group);

            if (power_settings != null) {
                // --- Sleep Timeouts Group ---
                var sleep_group = new Adw.PreferencesGroup ();
                sleep_group.title = "Automatic Suspend";
                sleep_group.description = "Fine-grained idle timeout control (in minutes, 0 = never)";

                var sleep_ac = new Adw.SpinRow.with_range (0, 480, 5);
                sleep_ac.title = "Suspend After (AC)";
                sleep_ac.subtitle = "Minutes of inactivity before suspend on AC power";
                var ac_timeout = power_settings.get_int ("sleep-inactive-ac-timeout");
                sleep_ac.value = ac_timeout / 60;
                sleep_ac.notify["value"].connect (() => {
                    power_settings.set_int ("sleep-inactive-ac-timeout", (int)(sleep_ac.value * 60));
                    if (sleep_ac.value == 0) {
                        power_settings.set_string ("sleep-inactive-ac-type", "nothing");
                    } else {
                        power_settings.set_string ("sleep-inactive-ac-type", "suspend");
                    }
                });
                sleep_group.add (sleep_ac);

                var sleep_bat = new Adw.SpinRow.with_range (0, 480, 5);
                sleep_bat.title = "Suspend After (Battery)";
                sleep_bat.subtitle = "Minutes of inactivity before suspend on battery";
                var bat_timeout = power_settings.get_int ("sleep-inactive-battery-timeout");
                sleep_bat.value = bat_timeout / 60;
                sleep_bat.notify["value"].connect (() => {
                    power_settings.set_int ("sleep-inactive-battery-timeout", (int)(sleep_bat.value * 60));
                    if (sleep_bat.value == 0) {
                        power_settings.set_string ("sleep-inactive-battery-type", "nothing");
                    } else {
                        power_settings.set_string ("sleep-inactive-battery-type", "suspend");
                    }
                });
                sleep_group.add (sleep_bat);

                if (session_settings != null) {
                    var idle_delay = new Adw.SpinRow.with_range (0, 60, 1);
                    idle_delay.title = "Screen Blank After";
                    idle_delay.subtitle = "Minutes of inactivity before screen turns off (0 = never)";
                    idle_delay.value = session_settings.get_uint ("idle-delay") / 60;
                    idle_delay.notify["value"].connect (() => {
                        session_settings.set_uint ("idle-delay", (uint)(idle_delay.value * 60));
                    });
                    sleep_group.add (idle_delay);
                }

                add (sleep_group);

                // --- Screen Group ---
                var screen_group = new Adw.PreferencesGroup ();
                screen_group.title = "Screen";

                var dim_switch = new Adw.SwitchRow ();
                dim_switch.title = "Dim Screen When Idle";
                dim_switch.subtitle = "Reduce brightness before screen blanks";
                power_settings.bind ("idle-dim", dim_switch, "active", SettingsBindFlags.DEFAULT);
                screen_group.add (dim_switch);

                add (screen_group);

                // --- Power Button Group ---
                var button_group = new Adw.PreferencesGroup ();
                button_group.title = "Power Button";

                var button_model = new Gtk.StringList (null);
                button_model.append ("Interactive (Ask)");
                button_model.append ("Suspend");
                button_model.append ("Hibernate");
                button_model.append ("Do Nothing");

                string[] button_values = { "interactive", "suspend", "hibernate", "nothing" };

                var power_button = new Adw.ComboRow ();
                power_button.title = "Power Button Action";
                power_button.subtitle = "What happens when you press the power button";
                power_button.model = button_model;

                var current_action = power_settings.get_string ("power-button-action");
                for (int i = 0; i < button_values.length; i++) {
                    if (button_values[i] == current_action) {
                        power_button.selected = i;
                        break;
                    }
                }
                power_button.notify["selected"].connect (() => {
                    if (power_button.selected < button_values.length) {
                        power_settings.set_string ("power-button-action", button_values[power_button.selected]);
                    }
                });
                button_group.add (power_button);

                add (button_group);
            } else if (session_settings != null) {
                // power_settings is null but session_settings exists -- show idle delay standalone
                var idle_group = new Adw.PreferencesGroup ();
                idle_group.title = "Screen";

                var idle_delay = new Adw.SpinRow.with_range (0, 60, 1);
                idle_delay.title = "Screen Blank After";
                idle_delay.subtitle = "Minutes of inactivity before screen turns off (0 = never)";
                idle_delay.value = session_settings.get_uint ("idle-delay") / 60;
                idle_delay.notify["value"].connect (() => {
                    session_settings.set_uint ("idle-delay", (uint)(idle_delay.value * 60));
                });
                idle_group.add (idle_delay);

                add (idle_group);
            }
        }

        private Adw.ComboRow make_lid_combo (string title, string key, HashTable<string, string> config) {
            var model = new Gtk.StringList (null);
            for (int i = 0; i < LID_LABELS.length; i++) {
                model.append (LID_LABELS[i]);
            }

            var combo = new Adw.ComboRow ();
            combo.title = title;
            combo.model = model;

            var current = config[key] ?? "suspend";
            int selected = 0;
            for (int i = 0; i < LID_VALUES.length; i++) {
                if (LID_VALUES[i] == current) { selected = i; break; }
            }
            combo.selected = selected;

            combo.notify["selected"].connect (() => {
                if (combo.selected < LID_VALUES.length) {
                    LogindHelper.write_config (key, LID_VALUES[combo.selected]);
                }
            });

            return combo;
        }
    }
}
