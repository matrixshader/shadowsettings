namespace ShadowSettings.Registry {

    public static SettingDef[] get_appearance_settings () {
        return {
            // Group: Fonts
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "font-name",
                label = "Interface Font",
                subtitle = "Font used across the desktop interface",
                category = "Appearance",
                group = "Fonts",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.FONT
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "document-font-name",
                label = "Document Font",
                subtitle = "Default font for document content",
                category = "Appearance",
                group = "Fonts",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.FONT
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "monospace-font-name",
                label = "Monospace Font",
                subtitle = "Font used in terminals and code editors",
                category = "Appearance",
                group = "Fonts",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.FONT
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "titlebar-font",
                label = "Titlebar Font",
                subtitle = "Font used for window titlebars",
                category = "Appearance",
                group = "Fonts",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.FONT
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "titlebar-uses-system-font",
                label = "Use System Font for Titlebars",
                subtitle = "Use the interface font for window titlebars instead of a custom font",
                category = "Appearance",
                group = "Fonts",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: Text Rendering
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "font-antialiasing",
                label = "Font Antialiasing",
                subtitle = "Smoothing method for text edges",
                category = "Appearance",
                group = "Text Rendering",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "None", "Grayscale", "Subpixel (LCD)" },
                combo_values = { "none", "grayscale", "rgba" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "font-hinting",
                label = "Font Hinting",
                subtitle = "How fonts snap to the pixel grid",
                category = "Appearance",
                group = "Text Rendering",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "None", "Slight", "Medium", "Full" },
                combo_values = { "none", "slight", "medium", "full" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "font-rgba-order",
                label = "Subpixel Order",
                subtitle = "RGB subpixel rendering order for LCD displays",
                category = "Appearance",
                group = "Text Rendering",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "RGB", "BGR", "Vertical RGB", "Vertical BGR" },
                combo_values = { "rgb", "bgr", "vrgb", "vbgr" }
            },

            // Group: Cursor
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "cursor-theme",
                label = "Cursor Theme",
                subtitle = "Name of the cursor icon theme",
                category = "Appearance",
                group = "Cursor",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.ENTRY
            },

            // Group: Misc
            SettingDef () {
                schema_id = "org.gnome.desktop.interface",
                key = "gtk-enable-primary-paste",
                label = "Middle-Click Paste",
                subtitle = "Paste selected text with middle mouse button click",
                category = "Appearance",
                group = "Misc",
                category_icon = "applications-graphics-symbolic",
                widget_hint = WidgetHint.SWITCH
            }
        };
    }
}
