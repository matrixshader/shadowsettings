namespace ShadowSettings {
    public class Application : Adw.Application {
        public ThemeManager theme_manager { get; private set; }

        public Application () {
            Object (
                application_id: "io.github.matrixshader.ShadowSettings",
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
        }

        protected override void activate () {
            var window = new ShadowSettings.Window (this);

            // Instantiate ThemeManager after window exists so CSS classes can be applied
            if (theme_manager == null) {
                theme_manager = new ThemeManager (this);
            } else {
                // Re-apply theme to new window
                theme_manager.apply_theme (theme_manager.current_theme);
            }

            // Apply persisted reduce-motion state
            if (theme_manager.reduce_motion_active) {
                theme_manager.set_reduce_motion (true);
            }

            window.present ();

            // About action -- shows AdwAboutWindow with full FR-8 branding
            var about_action = new SimpleAction ("about", null);
            about_action.activate.connect (() => {
                var about = new Adw.AboutWindow ();
                about.application_name = "Shadow Settings";
                about.application_icon = "io.github.matrixshader.ShadowSettings";
                about.developer_name = "Matrix Shader";
                about.version = "1.0.0";
                about.website = "https://matrixshader.com";
                about.copyright = "\u00a9 2026 Matrix Shader";
                about.license_type = Gtk.License.GPL_3_0;
                about.comments = "The settings hiding in the shadow of your system";
                about.add_link ("Tip Jar", "https://buymeacoffee.com/iknowkungfu");
                about.transient_for = active_window;
                about.present ();
            });
            add_action (about_action);
        }
    }
}
