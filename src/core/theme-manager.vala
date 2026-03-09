namespace ShadowSettings {
    /**
     * ThemeManager -- three-theme switcher with GSettings persistence.
     * Manages CSS class switching on the active window and color scheme
     * toggling via AdwStyleManager.
     *
     * Stub created in Task 1 for meson.build compilation.
     * Full implementation in Task 2.
     */
    public class ThemeManager : Object {
        private Adw.Application app;
        private GLib.Settings? app_settings;
        private Adw.StyleManager style_manager;

        public string current_theme {
            owned get {
                if (app_settings != null) {
                    return app_settings.get_string ("theme");
                }
                return "auto";
            }
        }

        public bool reduce_motion_active {
            get {
                if (app_settings != null) {
                    return app_settings.get_boolean ("reduce-motion");
                }
                return false;
            }
        }

        public ThemeManager (Adw.Application app) {
            this.app = app;
            this.style_manager = Adw.StyleManager.get_default ();
            this.app_settings = SafeSettings.try_get ("io.github.matrixshader.ShadowSettings");

            // Apply persisted theme on construction
            apply_theme (current_theme);

            // Listen for system dark/light changes -- re-apply if in auto mode
            style_manager.notify["dark"].connect (() => {
                if (current_theme == "auto") {
                    apply_theme ("auto");
                }
            });
        }

        public void apply_theme (string theme_id) {
            var window = app.active_window;
            if (window == null) return;

            // Remove all theme CSS classes
            window.remove_css_class ("gotham-night");
            window.remove_css_class ("gotham-day");
            window.remove_css_class ("wayne-manor");

            switch (theme_id) {
                case "gotham-night":
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                    window.add_css_class ("gotham-night");
                    break;
                case "gotham-day":
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                    window.add_css_class ("gotham-day");
                    break;
                case "wayne-manor":
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                    window.add_css_class ("wayne-manor");
                    break;
                case "auto":
                default:
                    style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
                    if (style_manager.dark) {
                        window.add_css_class ("gotham-night");
                    } else {
                        window.add_css_class ("gotham-day");
                    }
                    break;
            }

            // Persist to GSettings
            if (app_settings != null) {
                app_settings.set_string ("theme", theme_id);
            }
        }

        public void set_reduce_motion (bool reduce) {
            var window = app.active_window;
            if (window == null) return;

            if (reduce) {
                window.add_css_class ("reduce-motion");
                var gtk_settings = Gtk.Settings.get_default ();
                if (gtk_settings != null) {
                    gtk_settings.gtk_enable_animations = false;
                }
            } else {
                window.remove_css_class ("reduce-motion");
                var gtk_settings = Gtk.Settings.get_default ();
                if (gtk_settings != null) {
                    gtk_settings.gtk_enable_animations = true;
                }
            }

            // Persist to GSettings
            if (app_settings != null) {
                app_settings.set_boolean ("reduce-motion", reduce);
            }
        }
    }
}
