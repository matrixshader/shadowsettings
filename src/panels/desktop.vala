namespace ShadowSettings {
    public class DesktopPanel : Adw.PreferencesPage {
        construct {
            title = "Desktop";
            icon_name = "preferences-desktop-wallpaper-symbolic";

            var interface_settings = SafeSettings.try_get ("org.gnome.desktop.interface");
            var sound_settings = SafeSettings.try_get ("org.gnome.desktop.sound");
            var screensaver_settings = SafeSettings.try_get ("org.gnome.desktop.screensaver");

            if (interface_settings != null) {
                // --- Shell Group ---
                var shell_group = new Adw.PreferencesGroup ();
                shell_group.title = "Shell";

                var hot_corners = new Adw.SwitchRow ();
                hot_corners.title = "Hot Corners";
                hot_corners.subtitle = "Trigger Activities overview when mouse hits top-left corner";
                interface_settings.bind ("enable-hot-corners", hot_corners, "active", SettingsBindFlags.DEFAULT);
                shell_group.add (hot_corners);

                var animations = new Adw.SwitchRow ();
                animations.title = "Animations";
                animations.subtitle = "Enable desktop animations and transitions";
                interface_settings.bind ("enable-animations", animations, "active", SettingsBindFlags.DEFAULT);
                shell_group.add (animations);

                add (shell_group);

                // --- Top Bar Group ---
                var topbar_group = new Adw.PreferencesGroup ();
                topbar_group.title = "Top Bar";

                var clock_seconds = new Adw.SwitchRow ();
                clock_seconds.title = "Show Seconds in Clock";
                interface_settings.bind ("clock-show-seconds", clock_seconds, "active", SettingsBindFlags.DEFAULT);
                topbar_group.add (clock_seconds);

                var clock_weekday = new Adw.SwitchRow ();
                clock_weekday.title = "Show Weekday in Clock";
                interface_settings.bind ("clock-show-weekday", clock_weekday, "active", SettingsBindFlags.DEFAULT);
                topbar_group.add (clock_weekday);

                var clock_date = new Adw.SwitchRow ();
                clock_date.title = "Show Date in Clock";
                interface_settings.bind ("clock-show-date", clock_date, "active", SettingsBindFlags.DEFAULT);
                topbar_group.add (clock_date);

                // Clock format
                var clock_model = new Gtk.StringList (null);
                clock_model.append ("12 Hour");
                clock_model.append ("24 Hour");
                string[] clock_values = { "12h", "24h" };

                var clock_format = new Adw.ComboRow ();
                clock_format.title = "Clock Format";
                clock_format.model = clock_model;

                var current_format = interface_settings.get_string ("clock-format");
                clock_format.selected = (current_format == "24h") ? 1 : 0;
                clock_format.notify["selected"].connect (() => {
                    interface_settings.set_string ("clock-format", clock_values[clock_format.selected]);
                });
                topbar_group.add (clock_format);

                var battery_pct = new Adw.SwitchRow ();
                battery_pct.title = "Show Battery Percentage";
                interface_settings.bind ("show-battery-percentage", battery_pct, "active", SettingsBindFlags.DEFAULT);
                topbar_group.add (battery_pct);

                add (topbar_group);
            }

            if (sound_settings != null) {
                // --- Sound Group ---
                var sound_group = new Adw.PreferencesGroup ();
                sound_group.title = "Sound";

                var over_amp = new Adw.SwitchRow ();
                over_amp.title = "Allow Volume Above 100%";
                over_amp.subtitle = "Enable over-amplification for louder output";
                sound_settings.bind ("allow-volume-above-100-percent", over_amp, "active", SettingsBindFlags.DEFAULT);
                sound_group.add (over_amp);

                var event_sounds = new Adw.SwitchRow ();
                event_sounds.title = "Event Sounds";
                event_sounds.subtitle = "Play sounds for system events like errors and alerts";
                sound_settings.bind ("event-sounds", event_sounds, "active", SettingsBindFlags.DEFAULT);
                sound_group.add (event_sounds);

                add (sound_group);
            }

            if (screensaver_settings != null) {
                // --- Lock Screen Group ---
                var lock_group = new Adw.PreferencesGroup ();
                lock_group.title = "Lock Screen";

                var lock_enabled = new Adw.SwitchRow ();
                lock_enabled.title = "Automatic Screen Lock";
                lock_enabled.subtitle = "Lock screen when the display turns off";
                screensaver_settings.bind ("lock-enabled", lock_enabled, "active", SettingsBindFlags.DEFAULT);
                lock_group.add (lock_enabled);

                var lock_delay = new Adw.SpinRow.with_range (0, 300, 5);
                lock_delay.title = "Lock Delay";
                lock_delay.subtitle = "Seconds after screen blanks before locking (0 = immediate)";
                lock_delay.value = screensaver_settings.get_uint ("lock-delay");
                lock_delay.notify["value"].connect (() => {
                    screensaver_settings.set_uint ("lock-delay", (uint) lock_delay.value);
                });
                lock_group.add (lock_delay);

                add (lock_group);
            }
        }
    }
}
