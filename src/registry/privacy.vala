namespace ShadowSettings.Registry {

    public static SettingDef[] get_privacy_settings () {
        return {
            // Group: Camera & Microphone
            SettingDef () {
                schema_id = "org.gnome.desktop.privacy",
                key = "disable-camera",
                label = "Disable Camera",
                subtitle = "Block camera access for all applications",
                category = "Privacy",
                group = "Camera & Microphone",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.privacy",
                key = "disable-microphone",
                label = "Disable Microphone",
                subtitle = "Block microphone access for all applications",
                category = "Privacy",
                group = "Camera & Microphone",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: Lockdown
            SettingDef () {
                schema_id = "org.gnome.desktop.lockdown",
                key = "disable-lock-screen",
                label = "Disable Lock Screen",
                subtitle = "Prevent the screen from locking",
                category = "Privacy",
                group = "Lockdown",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.lockdown",
                key = "disable-command-line",
                label = "Disable Command Line",
                subtitle = "Prevent access to terminal and command line",
                category = "Privacy",
                group = "Lockdown",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.lockdown",
                key = "disable-log-out",
                label = "Disable Log Out",
                subtitle = "Remove the Log Out option from the system menu",
                category = "Privacy",
                group = "Lockdown",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.lockdown",
                key = "disable-printing",
                label = "Disable Printing",
                subtitle = "Prevent printing from any application",
                category = "Privacy",
                group = "Lockdown",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.lockdown",
                key = "disable-user-switching",
                label = "Disable User Switching",
                subtitle = "Prevent switching to another user account",
                category = "Privacy",
                group = "Lockdown",
                category_icon = "preferences-system-privacy-symbolic",
                widget_hint = WidgetHint.SWITCH
            }
        };
    }
}
