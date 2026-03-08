namespace ShadowSettings {

    public class CategoryMapper : Object {

        /**
         * Groups the available SettingDef array by category field and returns
         * CategoryInfo array in CATEGORY_ORDER sidebar order.
         * Categories with zero settings are omitted from the output.
         */
        public CategoryInfo[] map (SettingDef[] available) {
            // Collect settings per category (lowercased)
            var groups = new HashTable<string, GenericArray<SettingDef?>> (str_hash, str_equal);
            // Track first def per category for title and icon
            var first_defs = new HashTable<string, SettingDef?> (str_hash, str_equal);

            foreach (var def in available) {
                var cat_id = def.category.down ();
                var list = groups.lookup (cat_id);
                if (list == null) {
                    list = new GenericArray<SettingDef?> ();
                    groups.insert (cat_id, list);
                    first_defs.insert (cat_id, def);
                }
                list.add (def);
            }

            // Build output in CATEGORY_ORDER, omitting empty categories
            var result = new GenericArray<CategoryInfo?> ();
            foreach (var cat_id in CATEGORY_ORDER) {
                var list = groups.lookup (cat_id);
                if (list == null || list.length == 0) {
                    continue;
                }

                var first = first_defs.lookup (cat_id);
                var settings = new SettingDef[list.length];
                for (int i = 0; i < list.length; i++) {
                    settings[i] = list[i];
                }

                var info = CategoryInfo () {
                    id = cat_id,
                    title = first.category,
                    icon = first.category_icon,
                    settings = settings
                };
                result.add (info);
            }

            var output = new CategoryInfo[result.length];
            for (int i = 0; i < result.length; i++) {
                output[i] = result[i];
            }
            return output;
        }
    }
}
