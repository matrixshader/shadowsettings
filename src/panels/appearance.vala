namespace ShadowSettings {
    public class AppearancePanel : Adw.PreferencesPage {
        construct {
            title = "Appearance";
            icon_name = "applications-graphics-symbolic";

            var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
            var wm_settings = new GLib.Settings ("org.gnome.desktop.wm.preferences");

            // --- Fonts Group ---
            var fonts_group = new Adw.PreferencesGroup ();
            fonts_group.title = "Fonts";

            // Interface font
            var font_row = new Adw.ActionRow ();
            font_row.title = "Interface Font";
            font_row.subtitle = interface_settings.get_string ("font-name");
            var font_button = new Gtk.FontDialogButton (new Gtk.FontDialog ());
            font_button.valign = Gtk.Align.CENTER;
            var font_desc = Pango.FontDescription.from_string (interface_settings.get_string ("font-name"));
            font_button.font_desc = font_desc;
            font_button.notify["font-desc"].connect (() => {
                var desc_str = font_button.font_desc.to_string ();
                interface_settings.set_string ("font-name", desc_str);
                font_row.subtitle = desc_str;
            });
            font_row.add_suffix (font_button);
            fonts_group.add (font_row);

            // Document font
            var doc_font_row = new Adw.ActionRow ();
            doc_font_row.title = "Document Font";
            doc_font_row.subtitle = interface_settings.get_string ("document-font-name");
            var doc_font_button = new Gtk.FontDialogButton (new Gtk.FontDialog ());
            doc_font_button.valign = Gtk.Align.CENTER;
            var doc_font_desc = Pango.FontDescription.from_string (interface_settings.get_string ("document-font-name"));
            doc_font_button.font_desc = doc_font_desc;
            doc_font_button.notify["font-desc"].connect (() => {
                var desc_str = doc_font_button.font_desc.to_string ();
                interface_settings.set_string ("document-font-name", desc_str);
                doc_font_row.subtitle = desc_str;
            });
            doc_font_row.add_suffix (doc_font_button);
            fonts_group.add (doc_font_row);

            // Monospace font
            var mono_font_row = new Adw.ActionRow ();
            mono_font_row.title = "Monospace Font";
            mono_font_row.subtitle = interface_settings.get_string ("monospace-font-name");
            var mono_font_button = new Gtk.FontDialogButton (new Gtk.FontDialog ());
            mono_font_button.valign = Gtk.Align.CENTER;
            var mono_font_desc = Pango.FontDescription.from_string (interface_settings.get_string ("monospace-font-name"));
            mono_font_button.font_desc = mono_font_desc;
            mono_font_button.notify["font-desc"].connect (() => {
                var desc_str = mono_font_button.font_desc.to_string ();
                interface_settings.set_string ("monospace-font-name", desc_str);
                mono_font_row.subtitle = desc_str;
            });
            mono_font_row.add_suffix (mono_font_button);
            fonts_group.add (mono_font_row);

            // Titlebar font
            var title_font_row = new Adw.ActionRow ();
            title_font_row.title = "Titlebar Font";
            title_font_row.subtitle = wm_settings.get_string ("titlebar-font");
            var title_font_button = new Gtk.FontDialogButton (new Gtk.FontDialog ());
            title_font_button.valign = Gtk.Align.CENTER;
            var title_font_desc = Pango.FontDescription.from_string (wm_settings.get_string ("titlebar-font"));
            title_font_button.font_desc = title_font_desc;
            title_font_button.notify["font-desc"].connect (() => {
                var desc_str = title_font_button.font_desc.to_string ();
                wm_settings.set_string ("titlebar-font", desc_str);
                title_font_row.subtitle = desc_str;
            });
            title_font_row.add_suffix (title_font_button);
            fonts_group.add (title_font_row);

            add (fonts_group);

            // --- Text Rendering Group ---
            var rendering_group = new Adw.PreferencesGroup ();
            rendering_group.title = "Text Rendering";

            // Text scaling factor
            var scaling = new Adw.SpinRow.with_range (0.5, 3.0, 0.05);
            scaling.title = "Text Scaling Factor";
            scaling.subtitle = "Scale all text without changing resolution (1.0 = default)";
            scaling.digits = 2;
            scaling.value = interface_settings.get_double ("text-scaling-factor");
            scaling.notify["value"].connect (() => {
                interface_settings.set_double ("text-scaling-factor", scaling.value);
            });
            rendering_group.add (scaling);

            // Font hinting
            string[] hinting_labels = { "None", "Slight", "Medium", "Full" };
            string[] hinting_values = { "none", "slight", "medium", "full" };
            var hinting_model = new Gtk.StringList (null);
            foreach (var label in hinting_labels) hinting_model.append (label);

            var hinting = new Adw.ComboRow ();
            hinting.title = "Font Hinting";
            hinting.subtitle = "How fonts snap to the pixel grid";
            hinting.model = hinting_model;
            var current_hinting = interface_settings.get_string ("font-hinting");
            for (int i = 0; i < hinting_values.length; i++) {
                if (hinting_values[i] == current_hinting) { hinting.selected = i; break; }
            }
            hinting.notify["selected"].connect (() => {
                interface_settings.set_string ("font-hinting", hinting_values[hinting.selected]);
            });
            rendering_group.add (hinting);

            // Font antialiasing
            string[] aa_labels = { "None", "Grayscale", "Subpixel (LCD)" };
            string[] aa_values = { "none", "grayscale", "rgba" };
            var aa_model = new Gtk.StringList (null);
            foreach (var label in aa_labels) aa_model.append (label);

            var antialiasing = new Adw.ComboRow ();
            antialiasing.title = "Font Antialiasing";
            antialiasing.subtitle = "Smoothing method for text edges";
            antialiasing.model = aa_model;
            var current_aa = interface_settings.get_string ("font-antialiasing");
            for (int i = 0; i < aa_values.length; i++) {
                if (aa_values[i] == current_aa) { antialiasing.selected = i; break; }
            }
            antialiasing.notify["selected"].connect (() => {
                interface_settings.set_string ("font-antialiasing", aa_values[antialiasing.selected]);
            });
            rendering_group.add (antialiasing);

            add (rendering_group);

            // --- Cursor Group ---
            var cursor_group = new Adw.PreferencesGroup ();
            cursor_group.title = "Cursor";

            string[] cursor_labels = { "24 (Default)", "32", "48", "64", "96" };
            int[] cursor_sizes = { 24, 32, 48, 64, 96 };
            var cursor_model = new Gtk.StringList (null);
            foreach (var label in cursor_labels) cursor_model.append (label);

            var cursor_size = new Adw.ComboRow ();
            cursor_size.title = "Cursor Size";
            cursor_size.model = cursor_model;
            var current_size = interface_settings.get_int ("cursor-size");
            for (int i = 0; i < cursor_sizes.length; i++) {
                if (cursor_sizes[i] == current_size) { cursor_size.selected = i; break; }
            }
            cursor_size.notify["selected"].connect (() => {
                interface_settings.set_int ("cursor-size", cursor_sizes[cursor_size.selected]);
            });
            cursor_group.add (cursor_size);

            add (cursor_group);
        }
    }
}
