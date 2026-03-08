namespace ShadowSettings.Registry {

    public static SettingDef[] get_power_settings () {
        return {
            // Group: Lid Close
            // NOTE: These use org.freedesktop.login1 as a placeholder schema_id.
            // logind is NOT gsettings -- SchemaScanner will filter these out.
            // Power category needs special handling in window.vala (check logind
            // directly, not via gsettings). The widget factory (Phase 3) will
            // handle CUSTOM widget construction for these entries.
            SettingDef () {
                schema_id = "org.freedesktop.login1",
                key = "HandleLidSwitch",
                label = "Lid Close on Battery",
                subtitle = "What happens when you close the laptop lid on battery",
                category = "Power",
                group = "Lid Close",
                category_icon = "system-shutdown-symbolic",
                widget_hint = WidgetHint.CUSTOM
            },
            SettingDef () {
                schema_id = "org.freedesktop.login1",
                key = "HandleLidSwitchExternalPower",
                label = "Lid Close on AC Power",
                subtitle = "What happens when you close the laptop lid while plugged in",
                category = "Power",
                group = "Lid Close",
                category_icon = "system-shutdown-symbolic",
                widget_hint = WidgetHint.CUSTOM
            }
        };
    }
}
