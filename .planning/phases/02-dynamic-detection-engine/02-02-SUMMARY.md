---
phase: 02-dynamic-detection-engine
plan: 02
subsystem: registry
tags: [vala, gsettings, registry, hidden-settings, dynamic-sidebar, schema-scanner]

# Dependency graph
requires:
  - phase: 02-dynamic-detection-engine
    provides: SettingDef struct, SchemaScanner, CategoryMapper from plan 02-01
provides:
  - 6 curated registry files with 54 hidden setting definitions
  - Dynamic sidebar population from scanner+mapper pipeline
  - Settings count display in sidebar subtitle
  - Placeholder category pages organized by group
affects: [03-widget-factory, 03-panel-generation, 04-visual-identity]

# Tech tracking
tech-stack:
  added: []
  patterns: [registry-static-methods, flatpak-detection, dynamic-sidebar-from-categories]

key-files:
  created:
    - src/registry/desktop.vala
    - src/registry/appearance.vala
    - src/registry/windows.vala
    - src/registry/input.vala
    - src/registry/power.vala
    - src/registry/privacy.vala
  modified:
    - src/window.vala
    - meson.build

key-decisions:
  - "Registry uses static methods returning SettingDef[] (not const arrays) to avoid Vala nullable field limitation"
  - "Power/logind entries included in registry for completeness but skipped by scanner; PowerPanel used directly for native installs"
  - "org.gnome.desktop.wm.preferences split: 2 font keys in Appearance, 10 WM keys in Windows (FR-4)"
  - "Settings count includes logind entries (+2) when running natively for accurate display"

patterns-established:
  - "Registry.get_*_settings() static method pattern for each category's curated settings"
  - "Dynamic sidebar: scanner.scan() -> mapper.map() -> build rows from CategoryInfo[]"
  - "Flatpak detection via /.flatpak-info file existence check"

requirements-completed: [FR-1, FR-2, FR-4]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 2 Plan 2: Setting Registry & Dynamic Sidebar Summary

**54 curated hidden settings across 6 registry files with dynamic sidebar populated from SchemaScanner + CategoryMapper pipeline**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T16:20:56Z
- **Completed:** 2026-03-08T16:25:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Created 6 registry files defining 54 curated hidden GNOME settings that are NOT exposed by GNOME Settings
- Rewrote window.vala to dynamically build sidebar from SchemaScanner + CategoryMapper output instead of hardcoded PANELS array
- Settings count displayed in sidebar subtitle (e.g., "42 hidden settings found")
- Placeholder category pages show settings organized by group, proving detection engine works end-to-end
- Power/logind category preserved for native installs with Flatpak detection

## Task Commits

Each task was committed atomically:

1. **Task 1: Create all 6 registry files with curated hidden settings** - `0debbbc` (feat)
2. **Task 2: Rewrite window.vala for dynamic sidebar and settings count, update meson.build** - `cf59d41` (feat)

## Files Created/Modified
- `src/registry/desktop.vala` - 12 settings: sound, lock screen, user menu, shell
- `src/registry/appearance.vala` - 10 settings: fonts, text rendering, cursor, misc
- `src/registry/windows.vala` - 16 settings: titlebar buttons/actions, focus, behavior
- `src/registry/input.vala` - 7 settings: mouse, touchpad, keyboard
- `src/registry/power.vala` - 2 settings: logind lid-close (CUSTOM widget hint)
- `src/registry/privacy.vala` - 7 settings: camera/mic, lockdown
- `src/window.vala` - Dynamic sidebar from scanner+mapper, settings count, placeholder pages
- `meson.build` - Added 6 registry source files

## Decisions Made
- Registry files use static methods (`get_*_settings()`) returning `SettingDef[]` instead of const arrays, avoiding Vala's limitation with nullable fields in const struct arrays
- Power/logind entries are included in registry for documentation completeness but intentionally skipped by SchemaScanner (org.freedesktop.login1 is not a gsettings schema); PowerPanel used directly for native installs
- `org.gnome.desktop.wm.preferences` keys deliberately split: titlebar-font and titlebar-uses-system-font in Appearance, all other WM keys in Windows (satisfies FR-4)
- Settings count in sidebar includes +2 for logind entries when running natively, since those are real hidden settings even though they bypass gsettings

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 54 curated settings registered and dynamically detected at runtime
- Sidebar dynamically built from available schemas on the running system
- Placeholder category pages ready for Phase 3 widget factory to replace with interactive controls
- PowerPanel preserved as-is for native logind support until Phase 3 CUSTOM widget handling
- No blockers for downstream plans

## Self-Check: PASSED

All 8 files verified present. Both commit hashes (0debbbc, cf59d41) found in git log.

---
*Phase: 02-dynamic-detection-engine*
*Completed: 2026-03-08*
