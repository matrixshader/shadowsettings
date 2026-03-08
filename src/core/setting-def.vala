namespace ShadowSettings {

    public enum WidgetHint {
        AUTO,
        SWITCH,
        COMBO,
        SPIN_INT,
        SPIN_DOUBLE,
        FONT,
        ENTRY,
        CUSTOM
    }

    public struct SettingDef {
        public string schema_id;
        public string key;
        public string label;
        public string? subtitle;
        public string category;
        public string group;
        public string category_icon;
        public WidgetHint widget_hint;
        public double spin_min;
        public double spin_max;
        public double spin_step;
        public int spin_digits;
        public string[]? combo_labels;
        public string[]? combo_values;
        public double display_factor;
    }

    public struct CategoryInfo {
        public string id;
        public string title;
        public string icon;
        public SettingDef[] settings;
    }

    public static string[] CATEGORY_ORDER = {
        "desktop", "appearance", "windows", "input", "power", "privacy"
    };
}
