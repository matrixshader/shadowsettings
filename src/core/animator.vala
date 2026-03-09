namespace ShadowSettings {

    /**
     * Animator -- cinematic animation helpers for the Batcomputer aesthetic.
     *
     * Provides staggered row cascade on panel switch, amber glow pulse
     * on modified settings, and spring reveal for reset buttons.
     *
     * All methods check for the "reduce-motion" CSS class on the root
     * window and skip animations when active.
     */
    public class Animator : Object {

        /**
         * Staggered row cascade: walks a PreferencesPage and fades each
         * PreferencesRow in with a 40ms stagger between rows.
         */
        public static void cascade_rows (Adw.PreferencesPage page) {
            // Collect all rows from all groups on the page
            var rows = new GenericArray<Gtk.Widget> ();
            collect_rows (page, rows);

            if (rows.length == 0) return;

            // Check reduce-motion on root window
            var root = rows[0].get_root () as Gtk.Window;
            if (root != null && root.has_css_class ("reduce-motion")) {
                // Ensure all rows are visible with no animation
                for (int j = 0; j < rows.length; j++) {
                    rows[j].opacity = 1.0;
                }
                return;
            }

            // Set all rows invisible initially
            for (int j = 0; j < rows.length; j++) {
                rows[j].opacity = 0;
            }

            // Stagger each row's entrance
            for (int i = 0; i < rows.length; i++) {
                var row = rows[i];
                uint delay = (uint) (i * 40);

                GLib.Timeout.add (delay, () => {
                    var target = new Adw.CallbackAnimationTarget ((value) => {
                        row.opacity = value;
                    });

                    var anim = new Adw.TimedAnimation (row, 0.0, 1.0, 250, target);
                    anim.easing = Adw.Easing.EASE_OUT_CUBIC;
                    anim.play ();

                    return Source.REMOVE;
                });
            }
        }

        /**
         * Amber glow pulse: adds the setting-glow CSS class (triggering
         * a CSS @keyframes animation) then removes it after 800ms.
         */
        public static void pulse_modified (Gtk.Widget row) {
            // Check reduce-motion
            var root = row.get_root () as Gtk.Window;
            if (root != null && root.has_css_class ("reduce-motion")) {
                return;
            }

            row.add_css_class ("setting-glow");

            GLib.Timeout.add (800, () => {
                row.remove_css_class ("setting-glow");
                return Source.REMOVE;
            });
        }

        /**
         * Spring reveal: animate a widget from opacity 0 -> 1 with slight
         * overshoot (spring physics) for reset button appearance.
         */
        public static void spring_reveal (Gtk.Widget button) {
            // Check reduce-motion
            var root = button.get_root () as Gtk.Window;
            if (root != null && root.has_css_class ("reduce-motion")) {
                button.opacity = 1.0;
                return;
            }

            button.opacity = 0;

            var target = new Adw.CallbackAnimationTarget ((value) => {
                button.opacity = value;
            });

            var spring_params = new Adw.SpringParams (0.7, 1.0, 300.0);
            var anim = new Adw.SpringAnimation (button, 0.0, 1.0, spring_params, target);
            anim.play ();
        }

        /**
         * Recursively collect all PreferencesRow widgets from a page.
         * Walks: PreferencesPage -> children -> PreferencesGroup -> children -> rows
         */
        private static void collect_rows (Gtk.Widget parent, GenericArray<Gtk.Widget> rows) {
            var child = parent.get_first_child ();
            while (child != null) {
                if (child is Adw.PreferencesRow) {
                    rows.add (child);
                } else {
                    collect_rows (child, rows);
                }
                child = child.get_next_sibling ();
            }
        }
    }
}
