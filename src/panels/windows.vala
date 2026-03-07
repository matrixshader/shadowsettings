namespace ShadowSettings {
    public class WindowsPanel : Adw.PreferencesPage {
        construct {
            title = "Window Management";
            icon_name = "preferences-system-windows-symbolic";

            var wm_settings = SafeSettings.try_get ("org.gnome.desktop.wm.preferences");
            var mutter_settings = SafeSettings.try_get ("org.gnome.mutter");

            if (wm_settings != null) {
                // --- Titlebar Buttons Group ---
                var buttons_group = new Adw.PreferencesGroup ();
                buttons_group.title = "Titlebar Buttons";
                buttons_group.description = "Controls which buttons appear on window titlebars";

                var current_layout = wm_settings.get_string ("button-layout");
                bool has_minimize = current_layout.contains ("minimize");
                bool has_maximize = current_layout.contains ("maximize");

                var minimize_switch = new Adw.SwitchRow ();
                minimize_switch.title = "Show Minimize Button";
                minimize_switch.active = has_minimize;

                var maximize_switch = new Adw.SwitchRow ();
                maximize_switch.title = "Show Maximize Button";
                maximize_switch.active = has_maximize;

                minimize_switch.notify["active"].connect (() => {
                    update_button_layout (wm_settings, minimize_switch.active, maximize_switch.active);
                });
                maximize_switch.notify["active"].connect (() => {
                    update_button_layout (wm_settings, minimize_switch.active, maximize_switch.active);
                });

                buttons_group.add (minimize_switch);
                buttons_group.add (maximize_switch);
                add (buttons_group);

                // --- Titlebar Actions Group ---
                var actions_group = new Adw.PreferencesGroup ();
                actions_group.title = "Titlebar Actions";

                string[] click_labels = { "Toggle Maximize", "Minimize", "Menu", "Lower", "None" };
                string[] click_values = { "toggle-maximize", "minimize", "menu", "lower", "none" };

                var dbl_click = make_action_combo (
                    "Double-Click", "action-double-click-titlebar",
                    wm_settings, click_labels, click_values
                );
                actions_group.add (dbl_click);

                var mid_click = make_action_combo (
                    "Middle-Click", "action-middle-click-titlebar",
                    wm_settings, click_labels, click_values
                );
                actions_group.add (mid_click);

                var right_click = make_action_combo (
                    "Right-Click", "action-right-click-titlebar",
                    wm_settings, click_labels, click_values
                );
                actions_group.add (right_click);

                add (actions_group);

                // --- Focus Group ---
                var focus_group = new Adw.PreferencesGroup ();
                focus_group.title = "Window Focus";

                string[] focus_labels = { "Click to Focus", "Focus Follows Mouse", "Mouse (Strict)" };
                string[] focus_values = { "click", "sloppy", "mouse" };

                var focus_model = new Gtk.StringList (null);
                foreach (var label in focus_labels) {
                    focus_model.append (label);
                }

                var focus_combo = new Adw.ComboRow ();
                focus_combo.title = "Focus Mode";
                focus_combo.subtitle = "How windows receive keyboard focus";
                focus_combo.model = focus_model;

                var current_focus = wm_settings.get_string ("focus-mode");
                for (int i = 0; i < focus_values.length; i++) {
                    if (focus_values[i] == current_focus) {
                        focus_combo.selected = i;
                        break;
                    }
                }
                focus_combo.notify["selected"].connect (() => {
                    if (focus_combo.selected < focus_values.length) {
                        wm_settings.set_string ("focus-mode", focus_values[focus_combo.selected]);
                    }
                });
                focus_group.add (focus_combo);

                // Auto-raise (only relevant for sloppy/mouse focus)
                var auto_raise = new Adw.SwitchRow ();
                auto_raise.title = "Auto-Raise Focused Windows";
                auto_raise.subtitle = "Automatically raise windows when they receive focus";
                wm_settings.bind ("auto-raise", auto_raise, "active", SettingsBindFlags.DEFAULT);
                focus_group.add (auto_raise);

                add (focus_group);
            }

            if (mutter_settings != null) {
                // --- Behavior Group ---
                var behavior_group = new Adw.PreferencesGroup ();
                behavior_group.title = "Behavior";

                var center_windows = new Adw.SwitchRow ();
                center_windows.title = "Center New Windows";
                center_windows.subtitle = "Open new windows in the center of the screen";
                mutter_settings.bind ("center-new-windows", center_windows, "active", SettingsBindFlags.DEFAULT);
                behavior_group.add (center_windows);

                var edge_tiling = new Adw.SwitchRow ();
                edge_tiling.title = "Edge Tiling";
                edge_tiling.subtitle = "Tile windows when dragged to screen edges";
                mutter_settings.bind ("edge-tiling", edge_tiling, "active", SettingsBindFlags.DEFAULT);
                behavior_group.add (edge_tiling);

                var attach_modal = new Adw.SwitchRow ();
                attach_modal.title = "Attach Modal Dialogs";
                attach_modal.subtitle = "Attach dialog windows to their parent window";
                mutter_settings.bind ("attach-modal-dialogs", attach_modal, "active", SettingsBindFlags.DEFAULT);
                behavior_group.add (attach_modal);

                add (behavior_group);
            }
        }

        private void update_button_layout (GLib.Settings settings, bool minimize, bool maximize) {
            var right_buttons = new StringBuilder ("close");
            if (maximize) right_buttons.prepend ("maximize,");
            if (minimize) right_buttons.prepend ("minimize,");
            var layout = "appmenu:" + right_buttons.str;
            settings.set_string ("button-layout", layout);
        }

        private Adw.ComboRow make_action_combo (string title, string key,
                GLib.Settings settings, string[] labels, string[] values) {
            var model = new Gtk.StringList (null);
            foreach (var label in labels) {
                model.append (label);
            }

            var combo = new Adw.ComboRow ();
            combo.title = title;
            combo.model = model;

            var current = settings.get_string (key);
            for (int i = 0; i < values.length; i++) {
                if (values[i] == current) {
                    combo.selected = i;
                    break;
                }
            }
            combo.notify["selected"].connect (() => {
                if (combo.selected < values.length) {
                    settings.set_string (key, values[combo.selected]);
                }
            });

            return combo;
        }
    }
}
