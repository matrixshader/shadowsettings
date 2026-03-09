namespace ShadowSettings {
    public class Window : Adw.ApplicationWindow {
        private Adw.NavigationSplitView split_view;
        private Gtk.Stack content_stack;
        private Gtk.ListBox sidebar_list;

        /* Instance fields for lazy panel construction */
        private CategoryInfo[] categories;
        private SchemaScanner scanner;
        private HashTable<string, bool> panels_built;

        public Window (Adw.Application app) {
            Object (
                application: app,
                title: "Shadow Settings",
                default_width: 900,
                default_height: 600
            );
        }

        construct {
            content_stack = new Gtk.Stack ();
            content_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

            panels_built = new HashTable<string, bool> (str_hash, str_equal);

            // --- Build full registry from all curated setting files ---
            SettingDef[] full_registry = {};
            foreach (var def in Registry.get_desktop_settings ()) full_registry += def;
            foreach (var def in Registry.get_appearance_settings ()) full_registry += def;
            foreach (var def in Registry.get_windows_settings ()) full_registry += def;
            foreach (var def in Registry.get_input_settings ()) full_registry += def;
            // Skip power.vala entries (CUSTOM/logind -- handled separately below)
            foreach (var def in Registry.get_privacy_settings ()) full_registry += def;

            // --- Run SchemaScanner to filter to available settings ---
            scanner = new SchemaScanner ();
            var available = scanner.scan (full_registry);

            // --- Run CategoryMapper to group into ordered categories ---
            var mapper = new CategoryMapper ();
            categories = mapper.map (available);

            // --- Build preferences panel eagerly ---
            var prefs_page = build_preferences_page ();
            content_stack.add_named (prefs_page, "preferences");
            panels_built["preferences"] = true;

            // --- Build first category eagerly to avoid blank content area ---
            if (categories.length > 0) {
                var first_page = build_category_page_with_widgets (categories[0]);
                content_stack.add_named (first_page, categories[0].id);
                panels_built[categories[0].id] = true;
            }

            // --- Power category: special logind handling (native only) ---
            bool is_flatpak = FileUtils.test ("/.flatpak-info", FileTest.EXISTS);
            bool has_power = false;
            if (!is_flatpak) {
                // Add Power panel using existing PowerPanel (logind lid-close)
                content_stack.add_named (new ShadowSettings.PowerPanel (), "power");
                has_power = true;
            }

            // --- Sidebar ---
            sidebar_list = new Gtk.ListBox ();
            sidebar_list.selection_mode = Gtk.SelectionMode.SINGLE;
            sidebar_list.add_css_class ("navigation-sidebar");

            // Preferences row -- first item in sidebar
            var prefs_row = new Adw.ActionRow ();
            prefs_row.title = "Preferences";
            prefs_row.add_prefix (new Gtk.Image.from_icon_name ("applications-system-symbolic"));
            prefs_row.activatable = true;
            prefs_row.set_data<string> ("panel-id", "preferences");
            sidebar_list.append (prefs_row);

            // Art Deco separator between Preferences and category rows
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.add_css_class ("preferences-separator");
            sidebar_list.append (separator);

            foreach (var cat in categories) {
                var row = new Adw.ActionRow ();
                row.title = cat.title;
                row.add_prefix (new Gtk.Image.from_icon_name (cat.icon));
                row.activatable = true;
                row.set_data<string> ("panel-id", cat.id);
                sidebar_list.append (row);
            }

            // Add Power to sidebar if native
            if (has_power) {
                var power_row = new Adw.ActionRow ();
                power_row.title = "Power";
                power_row.add_prefix (new Gtk.Image.from_icon_name ("system-shutdown-symbolic"));
                power_row.activatable = true;
                power_row.set_data<string> ("panel-id", "power");
                sidebar_list.append (power_row);
            }

            sidebar_list.row_selected.connect ((row) => {
                if (row == null) return;

                // Skip separator rows (they are not ActionRows)
                if (!(row is Adw.ActionRow)) return;

                var action_row = (Adw.ActionRow) row;
                var panel_id = action_row.get_data<string> ("panel-id");
                if (panel_id == null) return;

                // Lazy build: construct page on first visit
                if (!panels_built.contains (panel_id) && panel_id != "power" && panel_id != "preferences") {
                    // Find the CategoryInfo for this panel_id
                    foreach (var cat in categories) {
                        if (cat.id == panel_id) {
                            var page = build_category_page_with_widgets (cat);
                            content_stack.add_named (page, panel_id);
                            panels_built[panel_id] = true;
                            break;
                        }
                    }
                }

                content_stack.visible_child_name = panel_id;
                split_view.show_content = true;

                // Cascade row entrance animation on every panel switch (skip preferences)
                if (panel_id != "preferences") {
                    var visible = content_stack.visible_child as Adw.PreferencesPage;
                    if (visible != null) {
                        Animator.cascade_rows (visible);
                    }
                }
            });

            // --- Sidebar page with settings count ---
            var sidebar_header = new Adw.HeaderBar ();
            int display_count = scanner.total_available;
            if (has_power) {
                display_count += 2; // logind lid-close entries
            }
            sidebar_header.title_widget = new Adw.WindowTitle (
                "Shadow Settings",
                "%d hidden settings found".printf (display_count)
            );

            var sidebar_page = new Adw.ToolbarView ();
            sidebar_page.add_top_bar (sidebar_header);

            var sidebar_scroll = new Gtk.ScrolledWindow ();
            sidebar_scroll.child = sidebar_list;
            sidebar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            sidebar_page.content = sidebar_scroll;

            var sidebar_nav = new Adw.NavigationPage.with_tag (sidebar_page, "sidebar", "Shadow Settings");

            // --- Content page ---
            var content_header = new Adw.HeaderBar ();

            var content_page = new Adw.ToolbarView ();
            content_page.add_top_bar (content_header);
            content_page.content = content_stack;

            var content_nav = new Adw.NavigationPage.with_tag (content_page, "content", "Settings");

            // --- Split view ---
            split_view = new Adw.NavigationSplitView ();
            split_view.sidebar = sidebar_nav;
            split_view.content = content_nav;
            split_view.min_sidebar_width = 220;
            split_view.max_sidebar_width = 280;

            this.content = split_view;

            // Select first category row (skip preferences + separator = index 2)
            sidebar_list.select_row (sidebar_list.get_row_at_index (2));
        }

        /**
         * Builds the Preferences page with theme picker and animation toggle.
         */
        private Adw.PreferencesPage build_preferences_page () {
            var page = new Adw.PreferencesPage ();
            page.title = "Preferences";
            page.icon_name = "applications-system-symbolic";

            // --- Appearance group ---
            var appearance_group = new Adw.PreferencesGroup ();
            appearance_group.title = "Appearance";
            appearance_group.description = "Visual theme and motion settings";

            // Theme picker: ComboRow with 4 options
            var theme_combo = new Adw.ComboRow ();
            theme_combo.title = "Theme";
            theme_combo.subtitle = "Visual color scheme";

            var theme_model = new Gtk.StringList (null);
            theme_model.append ("Auto");
            theme_model.append ("Gotham Night");
            theme_model.append ("Gotham Day");
            theme_model.append ("Wayne Manor");
            theme_combo.model = theme_model;

            // Theme values mapped by position
            string[] theme_values = { "auto", "gotham-night", "gotham-day", "wayne-manor" };

            // Read persisted theme directly from GSettings (ThemeManager may not exist yet)
            var prefs_settings = SafeSettings.try_get ("io.github.matrixshader.ShadowSettings");
            if (prefs_settings != null) {
                var persisted = prefs_settings.get_string ("theme");
                for (int i = 0; i < theme_values.length; i++) {
                    if (theme_values[i] == persisted) {
                        theme_combo.selected = i;
                        break;
                    }
                }
            }

            // Wire combo to ThemeManager (connect after setting initial value to avoid spurious signal)
            theme_combo.notify["selected"].connect (() => {
                var idx = theme_combo.selected;
                if (idx < theme_values.length) {
                    var app = (ShadowSettings.Application) this.application;
                    if (app.theme_manager != null) {
                        app.theme_manager.apply_theme (theme_values[idx]);
                    }
                }
            });

            appearance_group.add (theme_combo);

            // Reduce motion toggle
            var motion_switch = new Adw.SwitchRow ();
            motion_switch.title = "Reduce Motion";
            motion_switch.subtitle = "Disable animations within the app";

            // Read persisted reduce-motion directly from GSettings
            if (prefs_settings != null) {
                motion_switch.active = prefs_settings.get_boolean ("reduce-motion");
            }

            // Wire switch to ThemeManager
            motion_switch.notify["active"].connect (() => {
                var app = (ShadowSettings.Application) this.application;
                if (app.theme_manager != null) {
                    app.theme_manager.set_reduce_motion (motion_switch.active);
                }
            });

            appearance_group.add (motion_switch);
            page.add (appearance_group);

            return page;
        }

        /**
         * Builds a PreferencesPage for a category using WidgetFactory to create
         * interactive widgets for each detected setting.
         */
        private Adw.PreferencesPage build_category_page_with_widgets (CategoryInfo cat) {
            var page = new Adw.PreferencesPage ();
            page.title = cat.title;
            page.icon_name = cat.icon;

            // Collect unique groups in order of appearance
            string[] groups_seen = {};
            foreach (var def in cat.settings) {
                bool found = false;
                foreach (var g in groups_seen) {
                    if (g == def.group) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    groups_seen += def.group;
                }
            }

            // Build a PreferencesGroup per unique group
            foreach (var group_name in groups_seen) {
                var group = new Adw.PreferencesGroup ();
                group.title = group_name;

                foreach (var def in cat.settings) {
                    if (def.group == group_name) {
                        var widget = WidgetFactory.create_row (def, scanner);
                        if (widget != null) {
                            group.add (widget);
                        }
                    }
                }

                page.add (group);
            }

            return page;
        }
    }
}
