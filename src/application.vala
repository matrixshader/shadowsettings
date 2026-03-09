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

            // Placeholder about action (wired in Plan 02)
            var about_action = new SimpleAction ("about", null);
            add_action (about_action);
        }
    }
}
