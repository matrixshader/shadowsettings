---
phase: 04-visual-identity-design
plan: 01
subsystem: ui
tags: [gtk4-css, libadwaita, gresource, gsettings, theming, art-deco, vala]

# Dependency graph
requires:
  - phase: 03-widget-factory-panel-generation
    provides: "WidgetFactory, lazy panel construction, sidebar + content_stack layout"
provides:
  - "GResource-bundled CSS with 3 Art Deco theme palettes"
  - "ThemeManager class for CSS class switching + color scheme control"
  - "GSettings schema for theme and reduce-motion persistence"
  - "Preferences sidebar panel with theme picker and animation toggle"
  - "High contrast CSS overrides for accessibility"
affects: [05-search-polish-distribution, 04-02]

# Tech tracking
tech-stack:
  added: [gnome.compile_resources, gnome.compile_schemas, gnome.post_install]
  patterns: [gresource-auto-loading, css-class-theming, gsettings-app-preferences]

key-files:
  created:
    - data/io.github.matrixshader.ShadowSettings.gresource.xml
    - data/io.github.matrixshader.ShadowSettings.gschema.xml
    - data/style.css
    - data/style-dark.css
    - data/style-hc.css
    - data/style-hc-dark.css
    - src/core/theme-manager.vala
  modified:
    - meson.build
    - src/application.vala
    - src/window.vala

key-decisions:
  - "CSS class switching on window for 3-theme system (gotham-night, gotham-day, wayne-manor) + AdwStyleManager for dark/light"
  - "Read preferences from GSettings directly in construct block to avoid ThemeManager timing dependency"
  - "Preferences panel as first sidebar item with visual separator from category rows"

patterns-established:
  - "GResource auto-loading: style.css + style-dark.css + style-hc.css + style-hc-dark.css loaded automatically by libadwaita"
  - "Theme switching: CSS class on window + AdwStyleManager.color_scheme; ThemeManager persists to GSettings"
  - "Reduce motion: CSS class 'reduce-motion' disables animations + gtk_enable_animations toggle"
  - "SafeSettings.try_get() for app schema: returns null on first run before install, graceful fallback"

requirements-completed: [NFR-1]

# Metrics
duration: 5min
completed: 2026-03-09
---

# Phase 4 Plan 01: Visual Identity & Theme Infrastructure Summary

**Three-theme Art Deco CSS system with GResource auto-loading, ThemeManager class switching, and in-app Preferences panel for theme and motion control**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-09T00:59:15Z
- **Completed:** 2026-03-09T01:04:51Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- GResource-bundled CSS with 3 distinct Art Deco palettes: Gotham Night (dark/amber), Gotham Day (light/gold), Wayne Manor (warm/brown)
- ThemeManager with CSS class switching, AdwStyleManager color scheme control, and GSettings persistence
- Preferences sidebar panel as first item with theme ComboRow (4 options) and Reduce Motion SwitchRow
- Art Deco styling: monospace uppercase headers, accent dividers, scanline texture, card-like rows, sidebar pinstripe
- High contrast CSS overrides for accessibility (thickened borders, removed textures, boosted indicators)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GResource manifest, GSettings schema, CSS stylesheets, and wire into meson.build** - `063f095` (feat)
2. **Task 2: Create ThemeManager and wire preferences panel into sidebar** - `7417647` (feat)

**Plan metadata:** [pending] (docs: complete plan)

## Files Created/Modified
- `data/io.github.matrixshader.ShadowSettings.gresource.xml` - GResource manifest bundling 4 CSS files
- `data/io.github.matrixshader.ShadowSettings.gschema.xml` - App preferences schema (theme, reduce-motion)
- `data/style.css` - Base CSS: 3 theme palettes, Art Deco styling, scanline texture, reduce-motion rules (226 lines)
- `data/style-dark.css` - Dark-mode-specific CSS adjustments
- `data/style-hc.css` - High contrast overrides for WCAG AAA compliance
- `data/style-hc-dark.css` - Combined high contrast + dark overrides
- `src/core/theme-manager.vala` - ThemeManager class: apply_theme(), set_reduce_motion(), GSettings persistence
- `meson.build` - Added compile_resources, compile_schemas, post_install, gschema install, theme-manager source
- `src/application.vala` - ThemeManager instantiation in activate(), about action placeholder
- `src/window.vala` - Preferences sidebar entry, separator, build_preferences_page() with theme picker and motion toggle

## Decisions Made
- **CSS class switching for multi-theme:** Three themes share the same dark/light mode via CSS classes on window, not separate stylesheets. AdwStyleManager handles color scheme (FORCE_DARK/FORCE_LIGHT/DEFAULT).
- **Read GSettings directly in construct:** The preferences panel reads persisted values from GSettings directly rather than via ThemeManager, since ThemeManager doesn't exist yet during Window construct. Avoids timing dependency.
- **Preferences as regular content_stack page:** Preferences panel is a full PreferencesPage in the content_stack, consistent with existing lazy-loading architecture. Separated from categories by a styled separator.
- **Owned getter for current_theme:** Vala requires `owned get` for string properties returning from GSettings.get_string() (which returns an owned string).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed CSS !important syntax (unsupported in GTK4)**
- **Found during:** Task 2 (launch test)
- **Issue:** GTK4 CSS parser reported "Junk at end of value" for `animation-duration: 0ms !important`. GTK4 CSS does not support the `!important` modifier.
- **Fix:** Removed `!important` from all three reduce-motion CSS properties
- **Files modified:** data/style.css
- **Verification:** App launches with zero CSS parse warnings
- **Committed in:** 7417647 (Task 2 commit)

**2. [Rule 1 - Bug] Fixed construct-time ThemeManager access assertion failure**
- **Found during:** Task 2 (launch test)
- **Issue:** `build_preferences_page()` called during Window construct tried to access `Application.theme_manager` which was null (ThemeManager created in `activate()` AFTER Window construct). Caused `CRITICAL: assertion 'self != NULL' failed`.
- **Fix:** Changed preferences page to read persisted values directly from GSettings via `SafeSettings.try_get()` instead of via ThemeManager. ThemeManager is only used for writes (notify handlers fire after construct).
- **Files modified:** src/window.vala
- **Verification:** App launches cleanly with no critical assertions
- **Committed in:** 7417647 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for correct app startup. No scope creep.

## Issues Encountered
- GSettings schema not found in dev builds without explicit GSETTINGS_SCHEMA_DIR. This is expected behavior documented in research (Pitfall 6). SafeSettings.try_get() handles gracefully by returning null. Setting `GSETTINGS_SCHEMA_DIR=builddir` (with manually compiled schemas) confirms full functionality.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Theme infrastructure complete: CSS auto-loaded, ThemeManager wired, preferences panel accessible
- Ready for Plan 02: animations (staggered row cascade, amber glow pulse, spring reveals), About dialog, app icon
- The `setting-modified` CSS class indicator is styled (inset amber border) but awaits animation from Plan 02

## Self-Check: PASSED

All 10 created/modified files verified on disk. Both task commits (063f095, 7417647) found in git history. SUMMARY.md exists.

---
*Phase: 04-visual-identity-design*
*Completed: 2026-03-09*
