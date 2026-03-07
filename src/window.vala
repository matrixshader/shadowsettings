namespace ShadowSettings {
    public class Window : Adw.ApplicationWindow {
        private Adw.NavigationSplitView split_view;
        private Gtk.Stack content_stack;
        private Gtk.ListBox sidebar_list;

        private struct PanelInfo {
            string id;
            string title;
            string icon;
        }

        private const PanelInfo[] PANELS = {
            { "power",      "Power",             "system-shutdown-symbolic" },
            { "windows",    "Window Management", "preferences-system-windows-symbolic" },
            { "desktop",    "Desktop",           "preferences-desktop-wallpaper-symbolic" },
            { "appearance", "Appearance",        "applications-graphics-symbolic" },
            { "input",      "Input",             "input-keyboard-symbolic" },
        };

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

            // Add panels to stack
            content_stack.add_named (new ShadowSettings.PowerPanel (), "power");
            content_stack.add_named (new ShadowSettings.WindowsPanel (), "windows");
            content_stack.add_named (new ShadowSettings.DesktopPanel (), "desktop");
            content_stack.add_named (new ShadowSettings.AppearancePanel (), "appearance");
            content_stack.add_named (new ShadowSettings.InputPanel (), "input");

            // Sidebar
            sidebar_list = new Gtk.ListBox ();
            sidebar_list.selection_mode = Gtk.SelectionMode.SINGLE;
            sidebar_list.add_css_class ("navigation-sidebar");

            foreach (var panel in PANELS) {
                var row = new Adw.ActionRow ();
                row.title = panel.title;
                row.add_prefix (new Gtk.Image.from_icon_name (panel.icon));
                row.activatable = true;
                row.set_data<string> ("panel-id", panel.id);
                sidebar_list.append (row);
            }

            sidebar_list.row_selected.connect ((row) => {
                if (row != null) {
                    var action_row = (Adw.ActionRow) row;
                    var panel_id = action_row.get_data<string> ("panel-id");
                    content_stack.visible_child_name = panel_id;
                    split_view.show_content = true;
                }
            });

            // Sidebar page
            var sidebar_header = new Adw.HeaderBar ();
            sidebar_header.title_widget = new Adw.WindowTitle ("Shadow Settings", "The Settings They Took");

            var sidebar_page = new Adw.ToolbarView ();
            sidebar_page.add_top_bar (sidebar_header);

            var sidebar_scroll = new Gtk.ScrolledWindow ();
            sidebar_scroll.child = sidebar_list;
            sidebar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            sidebar_page.content = sidebar_scroll;

            var sidebar_nav = new Adw.NavigationPage.with_tag (sidebar_page, "sidebar", "Shadow Settings");

            // Content page
            var content_header = new Adw.HeaderBar ();

            var content_page = new Adw.ToolbarView ();
            content_page.add_top_bar (content_header);
            content_page.content = content_stack;

            var content_nav = new Adw.NavigationPage.with_tag (content_page, "content", "Settings");

            // Split view
            split_view = new Adw.NavigationSplitView ();
            split_view.sidebar = sidebar_nav;
            split_view.content = content_nav;
            split_view.min_sidebar_width = 220;
            split_view.max_sidebar_width = 280;

            this.content = split_view;

            // Select first panel
            sidebar_list.select_row (sidebar_list.get_row_at_index (0));
        }
    }
}
