namespace ShadowSettings.Registry {

    public static SettingDef[] get_input_settings () {
        return {
            // Group: Mouse
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.mouse",
                key = "middle-click-emulation",
                label = "Middle-Click Emulation",
                subtitle = "Simulate middle-click by pressing left and right buttons together",
                category = "Input",
                group = "Mouse",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.SWITCH
            },

            // Group: Touchpad
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.touchpad",
                key = "tap-and-drag",
                label = "Tap and Drag",
                subtitle = "Tap the touchpad to start dragging",
                category = "Input",
                group = "Touchpad",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.touchpad",
                key = "tap-and-drag-lock",
                label = "Tap and Drag Lock",
                subtitle = "Keep dragging until you tap again to release",
                category = "Input",
                group = "Touchpad",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.SWITCH
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.touchpad",
                key = "tap-button-map",
                label = "Tap Button Mapping",
                subtitle = "How multi-finger taps map to mouse buttons",
                category = "Input",
                group = "Touchpad",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Default", "Left-Right-Middle", "Left-Middle-Right" },
                combo_values = { "default", "lrm", "lmr" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.touchpad",
                key = "accel-profile",
                label = "Touchpad Acceleration",
                subtitle = "How touchpad movement speed is mapped",
                category = "Input",
                group = "Touchpad",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Default (Adaptive)", "Flat (No Acceleration)", "Adaptive" },
                combo_values = { "default", "flat", "adaptive" }
            },
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.touchpad",
                key = "left-handed",
                label = "Touchpad Left-Handed Mode",
                subtitle = "Swap primary and secondary touchpad buttons",
                category = "Input",
                group = "Touchpad",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.COMBO,
                combo_labels = { "Disabled", "Enabled" },
                combo_values = { "mouse", "left" }
            },

            // Group: Keyboard
            SettingDef () {
                schema_id = "org.gnome.desktop.peripherals.keyboard",
                key = "remember-numlock-state",
                label = "Remember NumLock State",
                subtitle = "Restore NumLock state when logging in",
                category = "Input",
                group = "Keyboard",
                category_icon = "input-keyboard-symbolic",
                widget_hint = WidgetHint.SWITCH
            }
        };
    }
}
