namespace ShadowSettings {
    public class Window : Adw.ApplicationWindow {
        private Adw.NavigationSplitView split_view;
        private Gtk.Stack content_stack;
        private Gtk.ListBox sidebar_list;

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

            // --- Build full registry from all curated setting files ---
            SettingDef[] full_registry = {};
            foreach (var def in Registry.get_desktop_settings ()) full_registry += def;
            foreach (var def in Registry.get_appearance_settings ()) full_registry += def;
            foreach (var def in Registry.get_windows_settings ()) full_registry += def;
            foreach (var def in Registry.get_input_settings ()) full_registry += def;
            // Skip power.vala entries (CUSTOM/logind -- handled separately below)
            foreach (var def in Registry.get_privacy_settings ()) full_registry += def;

            // --- Run SchemaScanner to filter to available settings ---
            var scanner = new SchemaScanner ();
            var available = scanner.scan (full_registry);

            // --- Run CategoryMapper to group into ordered categories ---
            var mapper = new CategoryMapper ();
            var categories = mapper.map (available);

            // --- Build content pages for each detected category ---
            foreach (var cat in categories) {
                var page = build_category_page (cat);
                content_stack.add_named (page, cat.id);
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
                if (row != null) {
                    var action_row = (Adw.ActionRow) row;
                    var panel_id = action_row.get_data<string> ("panel-id");
                    content_stack.visible_child_name = panel_id;
                    split_view.show_content = true;
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

            // Select first category row
            sidebar_list.select_row (sidebar_list.get_row_at_index (0));
        }

        /**
         * Builds a placeholder PreferencesPage for a category, showing
         * detected settings organized by group. Phase 3's widget factory
         * will replace these with actual interactive widgets.
         */
        private Adw.PreferencesPage build_category_page (CategoryInfo cat) {
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
                        var row = new Adw.ActionRow ();
                        row.title = def.label;
                        if (def.subtitle != null) {
                            row.subtitle = def.subtitle;
                        }
                        group.add (row);
                    }
                }

                page.add (group);
            }

            return page;
        }
    }
}
