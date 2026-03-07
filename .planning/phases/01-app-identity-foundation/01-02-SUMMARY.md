---
phase: 01-app-identity-foundation
plan: 02
subsystem: ui
tags: [vala, gtk4, gsettings, null-safety, schema-lookup]

requires:
  - phase: 01-app-identity-foundation/01
    provides: ShadowSettings namespace and app identity
provides:
  - SafeSettings helper with try_get() and has_key() static methods
  - Null-guarded GSettings access across all 5 panels
  - Graceful degradation when schemas are missing
affects: [02-dynamic-detection-engine, 03-widget-factory]

tech-stack:
  added: []
  patterns: [SafeSettings.try_get() for all GSettings access, null-check wrapping for widget groups]

key-files:
  created:
    - src/helpers/safe-settings.vala
  modified:
    - src/panels/power.vala
    - src/panels/windows.vala
    - src/panels/desktop.vala
    - src/panels/appearance.vala
    - src/panels/input.vala
    - meson.build

key-decisions:
  - "Silent skip on missing schemas -- no empty-state UI or error messages in Phase 1"
  - "Session idle_delay shown standalone if power schema missing but session schema exists"

patterns-established:
  - "SafeSettings.try_get() pattern: always use SafeSettings.try_get() instead of new GLib.Settings()"
  - "Null-check grouping: wrap entire widget groups in if (settings != null) blocks"
  - "Independent schema groups: each schema's widgets are independently guarded"

requirements-completed: [FR-1]

duration: 3min
completed: 2026-03-07
---

# Phase 1 Plan 2: SafeSettings Null-Guarding Summary

**SafeSettings helper with SettingsSchemaSource.lookup() null-guard replacing all 13 direct GLib.Settings constructors across 5 panels**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-07T04:00:27Z
- **Completed:** 2026-03-07T04:03:53Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Created SafeSettings helper class with try_get() and has_key() static methods using SettingsSchemaSource.lookup()
- Replaced all 13 direct GLib.Settings constructor calls with SafeSettings.try_get() across all 5 panels
- Every settings-dependent widget group wrapped in null check for graceful degradation
- App compiles cleanly and binary produced successfully

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SafeSettings helper and add to build** - `74f210b` (feat)
2. **Task 2: Null-guard all panel GSettings access** - `d5c689b` (feat)
3. **Task 3: Build and verify null-guarded app compiles** - verification only, no code changes

## Files Created/Modified
- `src/helpers/safe-settings.vala` - SafeSettings class with try_get() and has_key() static methods, cached SettingsSchemaSource
- `src/panels/power.vala` - 2 schemas null-guarded (power, session), lid close group unchanged (uses LogindHelper)
- `src/panels/windows.vala` - 2 schemas null-guarded (wm.preferences, mutter)
- `src/panels/desktop.vala` - 3 schemas null-guarded (interface, sound, screensaver), each group independent
- `src/panels/appearance.vala` - 2 schemas null-guarded (interface, wm.preferences), titlebar font independently guarded
- `src/panels/input.vala` - 4 schemas null-guarded (mouse, keyboard, touchpad, input-sources), each group independent
- `meson.build` - Added safe-settings.vala to sources list

## Decisions Made
- Silent skip on missing schemas -- panels show reduced content with no error messages or empty-state UI (deferred to Phase 3 widget factory)
- Session idle_delay is shown in a standalone group if power schema is missing but session schema exists, preserving that functionality independently
- LogindHelper-based lid close group kept unconditional since it does not use GSettings

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 1 complete: app has proper identity (Plan 01) and null-safe GSettings access (Plan 02)
- Ready for Phase 2 (Dynamic Detection Engine) which will use SafeSettings and SettingsSchemaSource for runtime schema scanning
- The SafeSettings.try_get() pattern established here is the foundation for all future GSettings access

## Self-Check: PASSED

All files found. All commits verified (74f210b, d5c689b). Summary exists.

---
*Phase: 01-app-identity-foundation*
*Completed: 2026-03-07*
