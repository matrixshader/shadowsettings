namespace ShadowSettings {
    public class InputPanel : Adw.PreferencesPage {
        construct {
            title = "Input";
            icon_name = "input-keyboard-symbolic";

            var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
            var keyboard_settings = new GLib.Settings ("org.gnome.desktop.peripherals.keyboard");
            var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");

            // --- Mouse Group ---
            var mouse_group = new Adw.PreferencesGroup ();
            mouse_group.title = "Mouse";

            string[] accel_labels = { "Default (Adaptive)", "Flat (No Acceleration)", "Adaptive" };
            string[] accel_values = { "default", "flat", "adaptive" };
            var accel_model = new Gtk.StringList (null);
            foreach (var label in accel_labels) accel_model.append (label);

            var accel_profile = new Adw.ComboRow ();
            accel_profile.title = "Acceleration Profile";
            accel_profile.subtitle = "How mouse movement speed is mapped";
            accel_profile.model = accel_model;
            var current_accel = mouse_settings.get_string ("accel-profile");
            for (int i = 0; i < accel_values.length; i++) {
                if (accel_values[i] == current_accel) { accel_profile.selected = i; break; }
            }
            accel_profile.notify["selected"].connect (() => {
                mouse_settings.set_string ("accel-profile", accel_values[accel_profile.selected]);
            });
            mouse_group.add (accel_profile);

            // Mouse speed
            var mouse_speed = new Adw.SpinRow.with_range (-1.0, 1.0, 0.1);
            mouse_speed.title = "Mouse Speed";
            mouse_speed.digits = 1;
            mouse_speed.value = mouse_settings.get_double ("speed");
            mouse_speed.notify["value"].connect (() => {
                mouse_settings.set_double ("speed", mouse_speed.value);
            });
            mouse_group.add (mouse_speed);

            // Middle-click emulation
            var middle_click = new Adw.SwitchRow ();
            middle_click.title = "Middle-Click Emulation";
            middle_click.subtitle = "Simulate middle-click by pressing left and right buttons together";
            mouse_settings.bind ("middle-click-emulation", middle_click, "active", SettingsBindFlags.DEFAULT);
            mouse_group.add (middle_click);

            add (mouse_group);

            // --- Touchpad Group ---
            var touchpad_group = new Adw.PreferencesGroup ();
            touchpad_group.title = "Touchpad";

            var tap_to_click = new Adw.SwitchRow ();
            tap_to_click.title = "Tap to Click";
            tap_to_click.subtitle = "Tap the touchpad to click instead of pressing";
            touchpad_settings.bind ("tap-to-click", tap_to_click, "active", SettingsBindFlags.DEFAULT);
            touchpad_group.add (tap_to_click);

            add (touchpad_group);

            // --- Keyboard Group ---
            var keyboard_group = new Adw.PreferencesGroup ();
            keyboard_group.title = "Keyboard";

            var repeat_switch = new Adw.SwitchRow ();
            repeat_switch.title = "Key Repeat";
            repeat_switch.subtitle = "Hold a key to repeat it";
            keyboard_settings.bind ("repeat", repeat_switch, "active", SettingsBindFlags.DEFAULT);
            keyboard_group.add (repeat_switch);

            var repeat_delay = new Adw.SpinRow.with_range (100, 2000, 50);
            repeat_delay.title = "Repeat Delay";
            repeat_delay.subtitle = "Milliseconds before key starts repeating";
            keyboard_settings.bind ("delay", repeat_delay, "value", SettingsBindFlags.DEFAULT);
            keyboard_group.add (repeat_delay);

            var repeat_speed = new Adw.SpinRow.with_range (10, 200, 5);
            repeat_speed.title = "Repeat Speed";
            repeat_speed.subtitle = "Milliseconds between key repeats (lower = faster)";
            keyboard_settings.bind ("repeat-interval", repeat_speed, "value", SettingsBindFlags.DEFAULT);
            keyboard_group.add (repeat_speed);

            add (keyboard_group);

            // --- Caps Lock / Compose Group ---
            var xkb_group = new Adw.PreferencesGroup ();
            xkb_group.title = "Key Remapping";
            xkb_group.description = "Common XKB options for key behavior";

            var input_settings = new GLib.Settings ("org.gnome.desktop.input-sources");
            var current_xkb = input_settings.get_strv ("xkb-options");

            // Caps Lock behavior
            string[] caps_labels = { "Default (Caps Lock)", "Escape", "Ctrl", "Backspace", "Disabled", "Swap with Escape" };
            string[] caps_values = { "", "caps:escape", "caps:ctrl_modifier", "caps:backspace", "caps:none", "caps:swapescape" };
            var caps_model = new Gtk.StringList (null);
            foreach (var label in caps_labels) caps_model.append (label);

            var caps_combo = new Adw.ComboRow ();
            caps_combo.title = "Caps Lock Behavior";
            caps_combo.model = caps_model;

            // Find current caps setting
            int caps_idx = 0;
            foreach (var opt in current_xkb) {
                for (int i = 1; i < caps_values.length; i++) {
                    if (opt == caps_values[i]) { caps_idx = i; break; }
                }
            }
            caps_combo.selected = caps_idx;

            caps_combo.notify["selected"].connect (() => {
                update_xkb_option (input_settings, "caps:", caps_values[caps_combo.selected]);
            });
            xkb_group.add (caps_combo);

            add (xkb_group);
        }

        private void update_xkb_option (GLib.Settings settings, string prefix, string new_value) {
            var current = settings.get_strv ("xkb-options");
            string[] updated = {};

            // Remove any existing option with this prefix
            foreach (var opt in current) {
                if (!opt.has_prefix (prefix)) {
                    updated += opt;
                }
            }

            // Add new value if not empty
            if (new_value != "") {
                updated += new_value;
            }

            settings.set_strv ("xkb-options", updated);
        }
    }
}
