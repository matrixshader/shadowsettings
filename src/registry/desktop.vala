namespace ShadowSettings.Registry {

    public static SettingDef[] get_desktop_settings () {
        return {
            // Group: Sound
            SettingDef () {
                schema_id = "org.gnome.desktop.sound",
                key = "event-sounds",
                label = "Event Sounds",
                subtitle = "Play sounds for system events",
                category = "Desktop",
                group = "Sound",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.sound",
                key = "input-feedback-sounds",
                label = "Input Feedback Sounds",
                subtitle = "Play sounds for input events like button clicks",
                category = "Desktop",
                group = "Sound",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: Lock Screen
            SettingDef () {
                schema_id = "org.gnome.desktop.screensaver",
                key = "show-full-name-in-top-bar",
                label = "Show Name on Lock Screen",
                subtitle = "Display your full name on the lock screen",
                category = "Desktop",
                group = "Lock Screen",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.screensaver",
                key = "user-switch-enabled",
                label = "User Switching on Lock Screen",
                subtitle = "Allow switching to another user from the lock screen",
                category = "Desktop",
                group = "Lock Screen",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.screensaver",
                key = "logout-enabled",
                label = "Logout from Lock Screen",
                subtitle = "Allow logging out from the screensaver",
                category = "Desktop",
                group = "Lock Screen",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.screensaver",
                key = "idle-activation-enabled",
                label = "Activate Screensaver When Idle",
                subtitle = "Automatically activate screensaver when idle",
                category = "Desktop",
                group = "Lock Screen",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: User Menu
            SettingDef () {
                schema_id = "org.gnome.desktop.privacy",
                key = "show-full-name-in-top-bar",
                label = "Show Full Name in Top Bar",
                subtitle = "Display your full name in the system menu",
                category = "Desktop",
                group = "User Menu",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.privacy",
                key = "remember-app-usage",
                label = "Remember App Usage",
                subtitle = "Track which applications you use",
                category = "Desktop",
                group = "User Menu",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.privacy",
                key = "report-technical-problems",
                label = "Send Problem Reports",
                subtitle = "Automatically send technical problem reports",
                category = "Desktop",
                group = "User Menu",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: Shell
            SettingDef () {
                schema_id = "org.gnome.shell",
                key = "always-show-log-out",
                label = "Always Show Log Out",
                subtitle = "Show Log Out option even with single user",
                category = "Desktop",
                group = "Shell",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.shell.window-switcher",
                key = "current-workspace-only",
                label = "Alt-Tab Current Workspace Only",
                subtitle = "Only show windows from the current workspace in Alt-Tab",
                category = "Desktop",
                group = "Shell",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.mutter",
                key = "overlay-key",
                label = "Activities Overlay Key",
                subtitle = "Key that triggers the Activities overlay",
                category = "Desktop",
                group = "Shell",
                category_icon = "preferences-desktop-wallpaper-symbolic",
                widget_hint = WidgetHint.ENTRY
            }
        };
    }
}
