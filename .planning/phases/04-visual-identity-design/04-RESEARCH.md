# Phase 4: Visual Identity & Design - Research

**Researched:** 2026-03-08
**Domain:** GTK4 CSS styling, libadwaita theming, GResource compilation, AdwAnimation API, AdwAboutWindow API, GSettings schema for app preferences
**Confidence:** HIGH

## Summary

Phase 4 transforms Shadow Settings from a stock Adwaita app into a visually distinctive Batcomputer/Art Deco themed application. The technical foundation is strong: libadwaita's `AdwApplication` auto-loads CSS from GResource (`style.css`, `style-dark.css`, `style-hc.css`, `style-hc-dark.css`), providing correct dark/light/HC handling without manual `CssProvider` binding. GTK4 supports full CSS `@keyframes` animations, `box-shadow`, `opacity`, `transform`, `filter`, and `transition` properties -- all needed for the amber glow pulse, staggered row cascades, and spring reveals.

The three-theme system (Gotham Night, Gotham Day, Wayne Manor) maps to libadwaita's `AdwStyleManager.set_color_scheme()` for dark/light switching, with a custom GSettings schema to persist the user's choice. The "Wayne Manor" warm theme is the interesting challenge -- it uses the same light/dark CSS variable overrides but with a distinct warm palette, requiring CSS class switching rather than just color-scheme toggling.

**Primary recommendation:** Use libadwaita's GResource auto-loading for CSS (no manual CssProvider needed). Implement three themes via CSS class toggling on the window (`gotham-night`, `gotham-day`, `wayne-manor`), with `AdwStyleManager` controlling dark/light mode. Use `AdwTimedAnimation` with `CallbackAnimationTarget` for staggered row cascades and glow pulses. Use `AdwAboutWindow` (not `AdwAboutDialog`) to maintain libadwaita >= 1.4 compatibility per NFR-4.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Three visual themes: Dark (Gotham night), Light (Gotham day), Warm (Wayne Manor)
- All three share the same Art Deco / Batman: The Animated Series DNA -- same visual language, different "exposure"
- Default auto-selects based on system `prefer-dark` / `prefer-light` -- dark system gets Gotham night, light system gets Gotham day
- User can override to any of the three via in-app setting
- First sidebar item: a "Shadow Settings" or "Preferences" entry at the top of the sidebar
- Contains: theme picker (3 themes) and animation toggle
- Dark theme (Gotham Night): deep blacks, amber/gold primary accents (like Gotham streetlights), deep crimson/red for alerts and reset actions
- Light theme (Gotham Day): warm grays, muted gold accents -- daylight version of the same city
- Warm theme (Wayne Manor): deep browns, warm amber -- cozy, rich, premium feel
- All themes use libadwaita CSS variables for theme-adaptive colors
- Direction: Batcomputer aesthetic -- the app should feel like accessing hidden system controls from the Batcave
- Row entrance: staggered cascade -- rows appear one by one, top to bottom, with slight delay
- Modified-setting highlight: animated amber glow/pulse when a setting changes from default
- Reset button: animated reveal (spring in)
- Sidebar selection: pulse effect
- Reduce motion: available as in-app setting, defaults to system's gtk-enable-animations
- Group separation: bold section headers / Art Deco dividers between groups
- Sidebar: subtle gradient or Art Deco pinstripe divider between sidebar and content area
- Cinematic animations: spring animations, not minimal
- About dialog per FR-8 requirements
- App icon in Art Deco / Batcomputer style, SVG, readable at 128px and 16px

### Claude's Discretion
- Batcomputer aesthetic depth: scan line textures, monospace headers, green phosphor glow, wireframe dividers, HUD-style category headers -- optimize for cool factor
- Row density: pick what looks best with Art Deco direction
- App icon concept: Batcomputer/radar/schematic direction alongside gear-with-shadow

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NFR-1 | Visual Identity: distinctive CSS, light/dark/HC support, libadwaita variables, screenshot-recognizable | GResource auto-loading handles light/dark/HC via style.css + style-dark.css + style-hc.css; CSS variables documented; three custom themes with Art Deco palette |
| FR-8 | About Dialog: app name, version, "Made by Matrix Shader", matrixshader.com link, tip jar link, license | AdwAboutWindow API with application_name, version, developer_name, website, add_link(), license_type properties |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| libadwaita-1 | >= 1.4 (system: 1.8.4) | Theme management, style classes, animations, about dialog | AdwApplication auto-loads CSS, AdwStyleManager controls color scheme, AdwTimedAnimation/SpringAnimation for motion |
| GTK4 | >= 4.12 (system: 4.20.3) | CSS engine, @keyframes, box-shadow, transitions | Full CSS Animations Level 1 support, transform, filter, opacity |
| GLib/GIO | >= 2.0 | GSettings for app preferences, GResource for CSS/icon bundling | Standard GNOME preference storage, compile-time resource bundling |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Meson gnome module | >= 0.62 | `gnome.compile_resources()` for GResource, `gnome.compile_schemas()` for GSettings | Build time: compile CSS + icon into binary, compile app settings schema |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AdwAboutWindow | AdwAboutDialog | AdwAboutDialog requires libadwaita >= 1.5; project targets >= 1.4 per NFR-4. AdwAboutWindow available since 1.2, deprecated in 1.6 but still works. Use AdwAboutWindow for compatibility. |
| GResource auto-loading | Manual CssProvider | Manual CssProvider requires binding `prefers-color-scheme` property to GtkSettings yourself. Auto-loading handles this automatically. No reason to use manual approach. |
| CSS @keyframes only | AdwTimedAnimation + CSS | CSS @keyframes lack programmatic control for staggered delays. AdwTimedAnimation allows per-row delay computation. Use both: CSS for persistent states, AdwAnimation for entrance/reveal effects. |

## Architecture Patterns

### Recommended Project Structure
```
data/
  io.github.matrixshader.ShadowSettings.gresource.xml   # NEW: GResource manifest
  io.github.matrixshader.ShadowSettings.gschema.xml      # NEW: App preferences schema
  io.github.matrixshader.ShadowSettings.desktop           # EXISTING
  style.css                                                # NEW: Base theme (all modes)
  style-dark.css                                           # NEW: Dark-only overrides
  style-hc.css                                             # NEW: High contrast overrides
  style-hc-dark.css                                        # NEW: HC + dark overrides
  icons/hicolor/scalable/apps/
    io.github.matrixshader.ShadowSettings.svg              # EXISTING (replace content)
    io.github.matrixshader.ShadowSettings-symbolic.svg     # NEW: Symbolic variant
src/
  application.vala       # MODIFY: remove resource_base_path if needed, add about action
  window.vala            # MODIFY: add preferences sidebar item, animation orchestration
  core/
    theme-manager.vala   # NEW: Three-theme switcher, GSettings persistence
    animator.vala        # NEW: Staggered cascade, glow pulse, spring reveal helpers
  ...existing files...
```

### Pattern 1: GResource Auto-Loading for CSS
**What:** libadwaita's AdwApplication automatically loads CSS from GResource at the application's base resource path.
**When to use:** Always -- this is the standard mechanism for app-specific CSS in libadwaita apps.
**Example:**
```xml
<!-- data/io.github.matrixshader.ShadowSettings.gresource.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/io/github/matrixshader/ShadowSettings">
    <file>style.css</file>
    <file>style-dark.css</file>
    <file>style-hc.css</file>
    <file>style-hc-dark.css</file>
  </gresource>
</gresources>
```
```python
# meson.build addition
gresource = gnome.compile_resources(
  'shadow-settings-resources',
  'data/io.github.matrixshader.ShadowSettings.gresource.xml',
  source_dir: 'data',
)
# Add gresource to executable sources
executable('shadow-settings', sources, gresource, dependencies: deps, install: true)
```
Source: [libadwaita Styles & Appearance docs](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html)

### Pattern 2: Three-Theme System via CSS Classes + StyleManager
**What:** Use `AdwStyleManager.set_color_scheme()` for dark/light mode, and CSS classes on the window for theme-specific variable overrides.
**When to use:** When the app has more than two themes (can't just rely on dark/light toggle).
**Example:**
```vala
// Source: Valadoc AdwStyleManager + AdwColorScheme
public class ThemeManager : Object {
    private GLib.Settings app_settings;
    private Adw.StyleManager style_manager;

    public ThemeManager () {
        app_settings = new GLib.Settings ("io.github.matrixshader.ShadowSettings");
        style_manager = Adw.StyleManager.get_default ();
    }

    public void apply_theme (string theme_id) {
        // Remove all theme classes from main window
        var window = (Gtk.Widget) app.active_window;
        window.remove_css_class ("gotham-night");
        window.remove_css_class ("gotham-day");
        window.remove_css_class ("wayne-manor");

        switch (theme_id) {
            case "gotham-night":
                style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                window.add_css_class ("gotham-night");
                break;
            case "gotham-day":
                style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                window.add_css_class ("gotham-day");
                break;
            case "wayne-manor":
                style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                window.add_css_class ("wayne-manor");
                break;
            case "auto":
            default:
                style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
                // Auto: system decides dark/light, use gotham-night or gotham-day
                if (style_manager.dark) {
                    window.add_css_class ("gotham-night");
                } else {
                    window.add_css_class ("gotham-day");
                }
                break;
        }
        app_settings.set_string ("theme", theme_id);
    }
}
```
```css
/* style.css -- CSS variable overrides per theme class */

/* Gotham Night (dark) -- amber/gold accents, deep blacks */
window.gotham-night {
    --accent-bg-color: #C8962E;
    --accent-fg-color: #000000;
    --accent-color: #D4A843;
    --destructive-bg-color: #A02020;
    --destructive-fg-color: #ffffff;
    --window-bg-color: #0A0A0F;
    --window-fg-color: #D4C5A0;
    --view-bg-color: #0E0E14;
    --view-fg-color: #D4C5A0;
    --headerbar-bg-color: #12121A;
    --headerbar-fg-color: #D4C5A0;
    --sidebar-bg-color: #0E0E16;
    --sidebar-fg-color: #D4C5A0;
    --card-bg-color: rgba(200, 150, 46, 0.06);
    --card-fg-color: #D4C5A0;
}

/* Gotham Day (light) -- warm grays, muted gold */
window.gotham-day {
    --accent-bg-color: #9A7520;
    --accent-fg-color: #ffffff;
    --accent-color: #7A5C18;
    --window-bg-color: #F0EDE6;
    --view-bg-color: #F5F2EB;
    --headerbar-bg-color: #E8E4DB;
    --sidebar-bg-color: #E0DCD3;
}

/* Wayne Manor (warm dark) -- deep browns, warm amber */
window.wayne-manor {
    --accent-bg-color: #C89A3E;
    --accent-fg-color: #1A1008;
    --window-bg-color: #1A1410;
    --view-bg-color: #1E1812;
    --headerbar-bg-color: #221C14;
    --sidebar-bg-color: #1C1610;
    --card-bg-color: rgba(200, 154, 62, 0.08);
}
```
Source: [Valadoc Adw.StyleManager](https://valadoc.org/libadwaita-1/Adw.StyleManager.html), [Valadoc Adw.ColorScheme](https://valadoc.org/libadwaita-1/Adw.ColorScheme.html)

### Pattern 3: Staggered Row Cascade with AdwTimedAnimation
**What:** Animate rows appearing one-by-one when a panel loads, using per-row AdwTimedAnimation with computed delays.
**When to use:** Panel switch (page becomes visible), row entrance animation.
**Example:**
```vala
// Source: Valadoc Adw.TimedAnimation, Adw.CallbackAnimationTarget
private void animate_rows_cascade (Adw.PreferencesPage page) {
    int row_index = 0;
    // Walk the page's groups and rows
    var child = page.get_first_child ();
    while (child != null) {
        if (child is Adw.PreferencesGroup) {
            var group_child = child.get_first_child ();
            while (group_child != null) {
                if (group_child is Adw.ActionRow || group_child is Adw.PreferencesRow) {
                    var widget = group_child;
                    widget.opacity = 0;
                    // Stagger: 50ms between each row
                    uint delay = row_index * 50;
                    var target = new Adw.CallbackAnimationTarget ((value) => {
                        widget.opacity = value;
                    });
                    var anim = new Adw.TimedAnimation (widget, 0.0, 1.0, 300, target);
                    anim.easing = Adw.Easing.EASE_OUT_CUBIC;
                    // Use GLib.Timeout for delay since TimedAnimation has no delay property
                    GLib.Timeout.add (delay, () => {
                        anim.play ();
                        return false; // one-shot
                    });
                    row_index++;
                }
                group_child = group_child.get_next_sibling ();
            }
        }
        child = child.get_next_sibling ();
    }
}
```
Source: [Valadoc Adw.TimedAnimation](https://valadoc.org/libadwaita-1/Adw.TimedAnimation.html), [Valadoc Adw.CallbackAnimationTarget](https://valadoc.org/libadwaita-1/Adw.CallbackAnimationTarget.html)

### Pattern 4: Amber Glow Pulse via CSS @keyframes
**What:** Animated highlight on modified settings using CSS @keyframes on the `setting-modified` class (already applied by WidgetFactory).
**When to use:** Setting changes from default value.
**Example:**
```css
/* Amber glow pulse on modified rows */
@keyframes amber-glow-pulse {
    0%   { box-shadow: inset 3px 0 0 0 rgba(200, 150, 46, 0.0); }
    50%  { box-shadow: inset 3px 0 0 0 rgba(200, 150, 46, 0.8); }
    100% { box-shadow: inset 3px 0 0 0 rgba(200, 150, 46, 0.35); }
}

row.setting-modified {
    animation-name: amber-glow-pulse;
    animation-duration: 800ms;
    animation-timing-function: ease-out;
    animation-fill-mode: forwards;
}
```
Source: [GTK4 CSS Properties](https://docs.gtk.org/gtk4/css-properties.html)

### Pattern 5: AdwAboutWindow for FR-8
**What:** Standard about dialog with branding, links, license.
**When to use:** Menu action "About Shadow Settings".
**Example:**
```vala
// Source: Valadoc Adw.AboutWindow, real-world Vala examples
private void show_about () {
    var about = new Adw.AboutWindow ();
    about.application_name = "Shadow Settings";
    about.application_icon = "io.github.matrixshader.ShadowSettings";
    about.developer_name = "Matrix Shader";
    about.version = "1.0.0";
    about.website = "https://matrixshader.com";
    about.copyright = "\u00a9 2026 Matrix Shader";
    about.license_type = Gtk.License.GPL_3_0;
    about.add_link ("Tip Jar", "https://buymeacoffee.com/iknowkungfu");
    about.transient_for = this;
    about.present ();
}
```
Source: [Valadoc Adw.AboutWindow](https://valadoc.org/libadwaita-1/Adw.AboutWindow.html)

### Pattern 6: GSettings Schema for App Preferences
**What:** Custom GSettings schema to persist theme selection and reduce-motion toggle.
**When to use:** App needs to remember user's theme and animation preferences.
**Example:**
```xml
<!-- data/io.github.matrixshader.ShadowSettings.gschema.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
  <schema id="io.github.matrixshader.ShadowSettings"
          path="/io/github/matrixshader/ShadowSettings/"
          gettext-domain="shadow-settings">
    <key name="theme" type="s">
      <default>'auto'</default>
      <summary>Visual theme</summary>
      <description>Visual theme: auto, gotham-night, gotham-day, wayne-manor</description>
    </key>
    <key name="reduce-motion" type="b">
      <default>false</default>
      <summary>Reduce motion</summary>
      <description>Disable animations within the app</description>
    </key>
  </schema>
</schemalist>
```
```python
# meson.build addition
install_data(
  'data/io.github.matrixshader.ShadowSettings.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)
gnome.post_install(glib_compile_schemas: true)
```
Source: [GNOME Wiki HowDoI/GSettings](https://wiki.gnome.org/HowDoI/GSettings), [GNOME Discourse - Installing GSettings schema with meson](https://discourse.gnome.org/t/installing-gsettings-schema-with-meson/13373)

### Anti-Patterns to Avoid
- **Manual CssProvider for app theme:** Do NOT create a `Gtk.CssProvider` and manually add it. Use GResource auto-loading instead. Manual providers require you to bind `prefers-color-scheme` to `GtkSettings` yourself, which is error-prone and fights with libadwaita's internal providers.
- **Hardcoded hex colors in CSS:** Always use CSS variable overrides (`--window-bg-color`, `--accent-bg-color`, etc.) so that libadwaita's theme machinery works correctly. Hardcoded colors break high-contrast mode.
- **CSS `transition` for entrance animations:** GTK4 CSS transitions only trigger on property changes of already-rendered widgets. For row entrance (widget just added to DOM), use `AdwTimedAnimation` or CSS `@keyframes` triggered by adding a CSS class.
- **Using `AdwAboutDialog` with libadwaita >= 1.4 target:** `AdwAboutDialog` requires libadwaita 1.5+. The project's NFR-4 targets GNOME 43+ (libadwaita 1.4+). Use `AdwAboutWindow` which is available since 1.2. It's deprecated in 1.6 but still fully functional and won't be removed.
- **Animating every frame with GLib.Timeout:** Use `AdwTimedAnimation`/`AdwSpringAnimation` which properly integrate with GTK's frame clock and respect `gtk-enable-animations`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark/light mode detection | Manual GtkSettings monitoring | `AdwStyleManager.get_default().dark` | Handles system + app color scheme, signals on change |
| CSS loading for dark/light/HC | Manual CssProvider per mode | GResource auto-load (style.css, style-dark.css, etc.) | libadwaita handles loading/unloading per appearance mode |
| Animation timing/easing | GLib.Timeout frame loops | `AdwTimedAnimation` / `AdwSpringAnimation` | Respects frame clock, skips when unmapped, honors gtk-enable-animations |
| Color scheme persistence | File-based config | GSettings with custom schema | Standard GNOME pattern, works in Flatpak via dconf portal |
| About dialog | Custom window with labels | `AdwAboutWindow` | Standard layout, handles links, credits, license display |
| @keyframes glow effects | Programmatic opacity cycling | CSS `@keyframes` + `animation-*` properties | Declarative, GPU-friendly, no Vala code needed |

**Key insight:** libadwaita's auto-loading mechanism handles 80% of the theming complexity. The main custom work is: (1) defining CSS variable overrides per theme, (2) orchestrating the three-theme class switching, and (3) programming entrance animations with `AdwTimedAnimation`.

## Common Pitfalls

### Pitfall 1: prefers-color-scheme Not Working in Manual CssProvider
**What goes wrong:** `@media (prefers-color-scheme: dark)` in a manually-loaded CssProvider is silently ignored.
**Why it happens:** Custom `GtkCssProvider` instances do not auto-sync their `prefers-color-scheme` property with `GtkSettings`. Only GTK/libadwaita internal providers do this.
**How to avoid:** Use GResource auto-loading (style.css, style-dark.css) which handles this correctly. If you must use a manual provider, bind `css_provider.prefers_color_scheme` to `GtkSettings` `gtk-application-prefer-dark-theme`.
**Warning signs:** Dark mode CSS rules have no effect when switching themes.

### Pitfall 2: GResource Path Mismatch
**What goes wrong:** CSS files are compiled into GResource but libadwaita doesn't load them.
**Why it happens:** The GResource prefix must exactly match the application's resource base path. For app ID `io.github.matrixshader.ShadowSettings`, the prefix is `/io/github/matrixshader/ShadowSettings` and files must be at that path.
**How to avoid:** Verify the gresource.xml prefix matches the app ID with dots replaced by slashes. The default resource base path is derived from the application ID.
**Warning signs:** App launches with stock Adwaita appearance despite CSS in GResource.

### Pitfall 3: CSS Variable Overrides Not Taking Effect
**What goes wrong:** Setting `--window-bg-color` in `style.css` doesn't change the appearance.
**Why it happens:** CSS specificity. Variables defined on `window` need sufficient specificity or need to be on the correct widget level. libadwaita sets these on `:root`.
**How to avoid:** Override variables on `window` selector (high enough specificity). Use `window.gotham-night` class selector for theme-specific overrides.
**Warning signs:** Some widgets pick up new colors, others don't.

### Pitfall 4: Animations Running on Hidden/Unmapped Widgets
**What goes wrong:** Animations play on panels that aren't visible yet, wasting resources or completing before the user sees them.
**Why it happens:** `AdwTimedAnimation` auto-skips on unmapped widgets (good), but CSS @keyframes fire immediately when a class is added regardless of visibility.
**How to avoid:** Trigger row cascade animations only when the content_stack switches to that page. Use `content_stack.notify["visible-child"]` signal.
**Warning signs:** Cascade animation is already "done" when user switches to a panel.

### Pitfall 5: Wayne Manor Theme Color Scheme Conflict
**What goes wrong:** Wayne Manor (warm dark) and Gotham Night (cool dark) both need `FORCE_DARK` but look different.
**Why it happens:** `AdwStyleManager.color_scheme` only controls dark vs light. Different dark themes need CSS class differentiation.
**How to avoid:** Use CSS classes (`gotham-night`, `wayne-manor`) on the window widget, not just color scheme. Apply appropriate `--*-color` variable overrides per class.
**Warning signs:** Wayne Manor looks identical to Gotham Night.

### Pitfall 6: GSettings Schema Not Found at Runtime (Development)
**What goes wrong:** App crashes with "Settings schema 'io.github.matrixshader.ShadowSettings' is not installed" during development.
**Why it happens:** Schema is only compiled during `meson install`, not during `meson compile`. During development with `ninja` in build dir, schemas aren't in the default search path.
**How to avoid:** Use `gnome.compile_schemas()` in meson.build which sets `GSETTINGS_SCHEMA_DIR` automatically. Or access via `SafeSettings.try_get()` pattern already established.
**Warning signs:** Works after install but crashes in dev builds.

### Pitfall 7: prefers-reduced-motion CSS Media Query Version Dependency
**What goes wrong:** `@media (prefers-reduced-motion: reduce)` has no effect on older GTK4 versions.
**Why it happens:** This media query was added in GTK 4.20. The project targets GTK 4.12+.
**How to avoid:** Don't rely on CSS media query for reduce-motion. Instead, use the app's own GSettings `reduce-motion` boolean, and conditionally set `Adw.Animation.follow_enable_animations_setting` or skip animations in Vala code. For CSS @keyframes, add/remove an `animations-enabled` class on the window.
**Warning signs:** Reduce motion toggle has no visible effect on GTK < 4.20.

### Pitfall 8: Sidebar "Preferences" Item Breaking Panel Selection
**What goes wrong:** Adding a non-panel item to the sidebar (the preferences/theme picker row) causes the content_stack to fail because there's no matching panel-id.
**Why it happens:** The existing `row_selected` handler assumes every sidebar row maps to a content_stack child.
**How to avoid:** Handle the preferences row specially in the selection handler. Either use it to show an inline preferences panel in the content_stack, or show a popover/dialog. Recommend: treat it as a regular content_stack page (a `PreferencesPage` with theme picker and animation toggle).
**Warning signs:** Clicking "Preferences" in sidebar shows blank content or crashes.

## Code Examples

### GResource XML for CSS + Icon
```xml
<!-- data/io.github.matrixshader.ShadowSettings.gresource.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/io/github/matrixshader/ShadowSettings">
    <file>style.css</file>
    <file>style-dark.css</file>
    <file>style-hc.css</file>
    <file>style-hc-dark.css</file>
  </gresource>
</gresources>
```
Source: [elementary GResource docs](https://docs.elementary.io/develop/apis/gresource), [libadwaita Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html)

### Meson Build with GResource + GSettings Schema
```python
gnome = import('gnome')

# Compile GResource (CSS + assets)
gresource = gnome.compile_resources(
  'shadow-settings-resources',
  'data/io.github.matrixshader.ShadowSettings.gresource.xml',
  source_dir: 'data',
)

# Compile GSettings schema for dev builds
gnome.compile_schemas(
  depend_files: 'data/io.github.matrixshader.ShadowSettings.gschema.xml',
)

# Install GSettings schema
install_data(
  'data/io.github.matrixshader.ShadowSettings.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

# Post-install: compile schemas system-wide
gnome.post_install(glib_compile_schemas: true)

executable('shadow-settings',
  sources, gresource,
  dependencies: deps,
  install: true,
)
```
Source: [Meson GNOME module docs](https://mesonbuild.com/Gnome-module.html)

### AdwTimedAnimation for Row Cascade
```vala
// Animate opacity from 0 to 1 with staggered delay per row
var target = new Adw.CallbackAnimationTarget ((value) => {
    widget.opacity = value;
});
var anim = new Adw.TimedAnimation (widget, 0.0, 1.0, 250, target);
anim.easing = Adw.Easing.EASE_OUT_CUBIC;
// Delay start per row index
GLib.Timeout.add (row_index * 40, () => {
    anim.play ();
    return GLib.Source.REMOVE;
});
```
Source: [Valadoc Adw.TimedAnimation](https://valadoc.org/libadwaita-1/Adw.TimedAnimation.html)

### AdwSpringAnimation for Reset Button Reveal
```vala
// Spring animation for button scale reveal
var spring_params = new Adw.SpringParams (0.7, 1.0, 300.0);
// damping_ratio 0.7 = slight overshoot, mass 1.0, stiffness 300
var target = new Adw.CallbackAnimationTarget ((value) => {
    // Scale via CSS transform or opacity
    button.opacity = value;
});
var anim = new Adw.SpringAnimation (button, 0.0, 1.0, spring_params, target);
anim.play ();
```
Source: [Valadoc Adw.SpringAnimation](https://valadoc.org/libadwaita-1/Adw.SpringAnimation.html), [Valadoc Adw.SpringParams](https://valadoc.org/libadwaita-1/Adw.SpringParams.html)

### CSS Art Deco Section Dividers
```css
/* Art Deco dividers between preference groups */
preferencesgroup > box > .header {
    border-bottom: 2px solid alpha(@accent_bg_color, 0.4);
    padding-bottom: 8px;
    margin-bottom: 4px;
}

/* Pinstripe sidebar border */
navigation-split-view > .sidebar-pane {
    border-right: 1px solid alpha(@accent_bg_color, 0.25);
    background-image: linear-gradient(
        to right,
        transparent 0%,
        transparent 98%,
        alpha(@accent_bg_color, 0.1) 100%
    );
}
```

### CSS Monospace Headers (Batcomputer Effect)
```css
/* Monospace group titles for Batcomputer feel */
preferencesgroup > box > .header > label.title {
    font-family: monospace;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    font-size: 0.85em;
    color: var(--accent-bg-color);
}
```

### Reduce Motion via CSS Class Toggle
```vala
// In ThemeManager or Window
public void set_reduce_motion (bool reduce) {
    var window = (Gtk.Widget) app.active_window;
    if (reduce) {
        window.add_css_class ("reduce-motion");
        // Also disable GTK animations system-wide for this app
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_enable_animations = false;
    } else {
        window.remove_css_class ("reduce-motion");
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_enable_animations = true;
    }
}
```
```css
/* When reduce-motion is active, kill all CSS animations */
window.reduce-motion *,
window.reduce-motion row.setting-modified {
    animation-duration: 0ms !important;
    animation-delay: 0ms !important;
    transition-duration: 0ms !important;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual CssProvider + add_provider_for_display() | GResource auto-loading via AdwApplication | libadwaita 1.0+ | No manual provider code needed; dark/HC handled automatically |
| AdwAboutWindow | AdwAboutDialog | libadwaita 1.5 | Deprecated but still works; use AboutWindow for 1.4 compat |
| @define-color (GTK3 pattern) | var(--variable-name) CSS custom properties | GTK 4.16+ | GTK3 color functions deprecated; use standard CSS variables |
| GLib.Timeout animation loops | AdwTimedAnimation / AdwSpringAnimation | libadwaita 1.0 | Frame-clock integrated, respects gtk-enable-animations |
| lighter()/darker()/shade() GTK color functions | color-mix() / alpha() standard CSS | GTK 4.16+ | Old functions still work but deprecated |

**Deprecated/outdated:**
- `AdwAboutWindow`: Deprecated in libadwaita 1.6, use `AdwAboutDialog` if targeting 1.5+. We use AboutWindow for 1.4 compat.
- `@define-color`: GTK3 pattern still parsed but discouraged. Use CSS custom properties (`--custom-name`).
- `lighter()`, `darker()`, `shade()`, `mix()`, `alpha()`: Deprecated GTK color functions since 4.16. Use `color-mix()` from standard CSS. However, for GTK 4.12 compat, the old functions are safer.

## Open Questions

1. **CSS Selector for PreferencesGroup Headers**
   - What we know: `Adw.PreferencesGroup` has a title label that becomes the group header. Its CSS tree structure needs verification.
   - What's unclear: Exact CSS selectors to target group title labels (`preferencesgroup > box > .header > label.title` is educated guess).
   - Recommendation: Use GTK Inspector (`GTK_DEBUG=interactive shadow-settings`) at runtime to verify widget tree and adjust selectors. This is standard practice for GTK CSS development.

2. **Sidebar First-Item Layout**
   - What we know: User wants a "Preferences" entry at the top of the sidebar containing theme picker and animation toggle.
   - What's unclear: Whether this should be a full PreferencesPage in the content_stack or a special widget. How to visually separate it from category items.
   - Recommendation: Implement as a regular content_stack page. Add a visual separator (e.g., `Gtk.Separator`) in the sidebar between the preferences row and category rows. This keeps the architecture consistent with existing lazy-loading pattern.

3. **SVG Icon Design Tooling**
   - What we know: New icon needed in Art Deco / Batcomputer style. Must be SVG, readable at 128px and 16px.
   - What's unclear: Whether Claude can generate production-quality SVG directly or if hand-authored SVG shapes are sufficient.
   - Recommendation: Author SVG directly in code. Keep shapes geometric (Art Deco = straight lines, circles, symmetry). The existing icon is hand-coded SVG and this approach works well.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual visual inspection + GTK Inspector (no automated UI test framework in project) |
| Config file | none -- Vala/GTK4 projects typically use manual testing for CSS/visual work |
| Quick run command | `ninja -C builddir && ./builddir/shadow-settings` |
| Full suite command | `ninja -C builddir && GTK_DEBUG=interactive ./builddir/shadow-settings` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NFR-1.1 | Custom CSS loaded, not stock Adwaita | smoke | `ninja -C builddir && ./builddir/shadow-settings` (visual check) | N/A -- visual |
| NFR-1.2 | Light mode works | manual | Switch to Gotham Day, verify amber/warm-gray palette | N/A -- visual |
| NFR-1.3 | Dark mode works | manual | Switch to Gotham Night, verify deep blacks + amber accents | N/A -- visual |
| NFR-1.4 | High contrast mode works | manual | Enable HC in GNOME Accessibility, verify readability | N/A -- visual |
| NFR-1.5 | CSS uses libadwaita variables | code review | Verify style.css uses `--window-bg-color` etc., no hardcoded colors | N/A -- review |
| NFR-1.6 | Staggered row cascade animation | manual | Switch panels, observe row-by-row entrance | N/A -- visual |
| NFR-1.7 | Amber glow on modified settings | manual | Change a setting, observe glow pulse | N/A -- visual |
| NFR-1.8 | Reduce motion works | manual | Toggle reduce-motion, verify animations disabled | N/A -- visual |
| NFR-1.9 | Visually distinguishable in screenshot | manual | Screenshot comparison with GNOME Settings/Tweaks/Refine | N/A -- visual |
| FR-8.1 | About dialog shows branding | smoke | Trigger about action, verify fields | N/A -- visual |
| FR-8.2 | matrixshader.com link works | manual | Click website link in about dialog | N/A -- visual |
| FR-8.3 | Tip jar link present | manual | Verify "Tip Jar" link in about dialog | N/A -- visual |

### Sampling Rate
- **Per task commit:** `ninja -C builddir && ./builddir/shadow-settings` (launch and visual check)
- **Per wave merge:** Full visual walkthrough: all 3 themes, HC mode, animations, about dialog
- **Phase gate:** All 3 themes visually correct, animations play, about dialog complete, HC mode accessible

### Wave 0 Gaps
- [ ] `data/io.github.matrixshader.ShadowSettings.gresource.xml` -- GResource manifest for CSS
- [ ] `data/style.css` -- base stylesheet
- [ ] `data/io.github.matrixshader.ShadowSettings.gschema.xml` -- app preferences schema
- [ ] meson.build updates for gnome.compile_resources() and gnome.compile_schemas()

## Sources

### Primary (HIGH confidence)
- [libadwaita Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html) -- auto-loading CSS from GResource, style-dark.css stacking, prefers-color-scheme
- [libadwaita CSS Variables (1.2)](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.2/css-variables.html) -- full variable list with light/dark default values
- [GTK4 CSS Properties](https://docs.gtk.org/gtk4/css-properties.html) -- animation, box-shadow, transform, transition, filter support
- [Valadoc Adw.TimedAnimation](https://valadoc.org/libadwaita-1/Adw.TimedAnimation.html) -- constructor, properties, easing
- [Valadoc Adw.SpringAnimation](https://valadoc.org/libadwaita-1/Adw.SpringAnimation.html) -- constructor, spring params, clamping
- [Valadoc Adw.SpringParams](https://valadoc.org/libadwaita-1/Adw.SpringParams.html) -- damping ratio, mass, stiffness
- [Valadoc Adw.StyleManager](https://valadoc.org/libadwaita-1/Adw.StyleManager.html) -- color_scheme, dark, high_contrast
- [Valadoc Adw.ColorScheme](https://valadoc.org/libadwaita-1/Adw.ColorScheme.html) -- DEFAULT, FORCE_LIGHT, PREFER_LIGHT, PREFER_DARK, FORCE_DARK
- [Valadoc Adw.AboutWindow](https://valadoc.org/libadwaita-1/Adw.AboutWindow.html) -- application_name, version, add_link, website, license_type
- [Valadoc Adw.Easing](https://valadoc.org/libadwaita-1/Adw.Easing.html) -- 34 easing functions
- [libadwaita Style Classes](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/style-classes.html) -- navigation-sidebar, boxed-list, monospace, dimmed, heading, flat, etc.
- [Meson GNOME module](https://mesonbuild.com/Gnome-module.html) -- compile_resources(), compile_schemas()
- [elementary GResource docs](https://docs.elementary.io/develop/apis/gresource) -- gresource.xml format, meson integration

### Secondary (MEDIUM confidence)
- [GNOME Discourse - prefers-color-scheme not working](https://discourse.gnome.org/t/media-prefers-color-scheme-dark-not-working/31884) -- manual CssProvider requires explicit binding; auto-load avoids this
- [GNOME Discourse - Installing GSettings schema with meson](https://discourse.gnome.org/t/installing-gsettings-schema-with-meson/13373) -- gnome.compile_schemas() for dev builds
- [GNOME Wiki HowDoI/GSettings](https://wiki.gnome.org/HowDoI/GSettings) -- schema XML format, enum support
- [libadwaita migration to adaptive dialogs](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/migrating-to-adaptive-dialogs.html) -- AboutWindow -> AboutDialog migration path

### Tertiary (LOW confidence)
- CSS selector paths for PreferencesGroup internals (e.g., `preferencesgroup > box > .header > label.title`) -- needs GTK Inspector verification at runtime
- GTK color functions (`lighter()`, `darker()`) deprecation timeline -- may still work on 4.12 but recommended to move to `color-mix()`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- libadwaita auto-loading, AdwStyleManager, AdwAnimation API all verified via official Valadoc and GNOME docs
- Architecture: HIGH -- three-theme CSS class pattern is well-established; GResource auto-loading is the canonical approach
- Pitfalls: HIGH -- prefers-color-scheme CssProvider issue verified via GNOME Discourse; GResource path mismatch documented
- CSS capabilities: HIGH -- GTK4 CSS properties page confirms box-shadow, @keyframes, opacity, transform all supported
- CSS selectors for Adw widgets: LOW -- internal widget tree structure needs runtime GTK Inspector verification

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable -- libadwaita CSS/animation APIs are mature and rarely change)
