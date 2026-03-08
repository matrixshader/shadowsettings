namespace ShadowSettings.Registry {

    public static SettingDef[] get_windows_settings () {
        return {
            // Group: Titlebar Buttons
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "button-layout",
                label = "Titlebar Button Layout",
                subtitle = "Arrangement of close, minimize, maximize buttons",
                category = "Windows",
                group = "Titlebar Buttons",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.ENTRY
            },

            // Group: Titlebar Actions
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "action-double-click-titlebar",
                label = "Double-Click Titlebar",
                subtitle = "Action when double-clicking a window titlebar",
                category = "Windows",
                group = "Titlebar Actions",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Toggle Maximize", "Minimize", "Menu", "Lower", "None" },
                combo_values = { "toggle-maximize", "minimize", "menu", "lower", "none" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "action-middle-click-titlebar",
                label = "Middle-Click Titlebar",
                subtitle = "Action when middle-clicking a window titlebar",
                category = "Windows",
                group = "Titlebar Actions",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Toggle Maximize", "Minimize", "Menu", "Lower", "None" },
                combo_values = { "toggle-maximize", "minimize", "menu", "lower", "none" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "action-right-click-titlebar",
                label = "Right-Click Titlebar",
                subtitle = "Action when right-clicking a window titlebar",
                category = "Windows",
                group = "Titlebar Actions",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Toggle Maximize", "Minimize", "Menu", "Lower", "None" },
                combo_values = { "toggle-maximize", "minimize", "menu", "lower", "none" }
            },

            // Group: Focus
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "auto-raise",
                label = "Auto-Raise Focused Windows",
                subtitle = "Automatically raise windows when they receive focus",
                category = "Windows",
                group = "Focus",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "auto-raise-delay",
                label = "Auto-Raise Delay",
                subtitle = "Delay before auto-raising focused windows (ms)",
                category = "Windows",
                group = "Focus",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SPIN_INT,
                spin_min = 0,
                spin_max = 10000,
                spin_step = 100
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "raise-on-click",
                label = "Raise Window on Click",
                subtitle = "Bring window to front when clicked",
                category = "Windows",
                group = "Focus",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "focus-new-windows",
                label = "New Window Focus",
                subtitle = "How new windows receive focus",
                category = "Windows",
                group = "Focus",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Smart", "Strict" },
                combo_values = { "smart", "strict" }
            },

            // Group: Behavior
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "center-new-windows",
                label = "Center New Windows",
                subtitle = "Open new windows in the center of the screen",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "attach-modal-dialogs",
                label = "Attach Modal Dialogs",
                subtitle = "Attach dialog windows to their parent window",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "auto-maximize",
                label = "Auto-Maximize Large Windows",
                subtitle = "Automatically maximize windows that are nearly full-screen",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "focus-change-on-pointer-rest",
                label = "Delay Focus Until Pointer Stops",
                subtitle = "Wait for pointer to stop moving before changing focus",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "check-alive-timeout",
                label = "Window Alive Check Timeout",
                subtitle = "Milliseconds before showing 'not responding' dialog (0 = disabled)",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SPIN_INT,
                spin_min = 0,
                spin_max = 60000,
                spin_step = 1000
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "draggable-border-width",
                label = "Draggable Border Width",
                subtitle = "Width of the invisible window resize border in pixels",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SPIN_INT,
                spin_min = 0,
                spin_max = 64,
                spin_step = 1
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "resize-with-right-button",
                label = "Resize with Right Button",
                subtitle = "Use right mouse button for window resize",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.wm.preferences",
                key = "mouse-button-modifier",
                label = "Window Drag Modifier Key",
                subtitle = "Key to hold for moving windows by clicking anywhere",
                category = "Windows",
                group = "Behavior",
                category_icon = "preferences-system-windows-symbolic",
                widget_hint = WidgetHint.ENTRY
            }
        };
    }
}
