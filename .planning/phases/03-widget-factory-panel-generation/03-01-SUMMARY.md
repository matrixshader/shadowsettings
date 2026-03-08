---
phase: 03-widget-factory-panel-generation
plan: 01
subsystem: ui
tags: [vala, gtk4, libadwaita, gsettings, widget-factory, adw-switch-row, adw-combo-row, adw-spin-row, adw-entry-row, font-dialog-button]

# Dependency graph
requires:
  - phase: 02-dynamic-detection-engine
    provides: SettingDef struct, WidgetHint enum, SchemaScanner with get_key_info(), SafeSettings helper
provides:
  - WidgetFactory static class with create_row() entry point
  - Data-driven widget generation for all 8 WidgetHint types
  - Reset-to-default mechanism via GSettings.get_user_value()/reset()
  - Changed-settings highlighting via setting-modified CSS class
  - GSettings object cache preventing duplicate objects per schema_id
affects: [03-02-panel-generation, 04-visual-identity]

# Tech tracking
tech-stack:
  added: []
  patterns: [widget-factory-dispatch, gsettings-cache, reset-with-user-value, entry-row-separate-suffix-handler]

key-files:
  created:
    - src/core/widget-factory.vala
  modified:
    - meson.build

key-decisions:
  - "EntryRow uses separate attach_reset_and_tracking_entry() since EntryRow extends PreferencesRow not ActionRow"
  - "display_factor=0.0 treated as 1.0 (no scaling) for forward compatibility"
  - "AUTO hint enum values get auto-capitalized labels from range data"
  - "COMBO/SPIN rows sync widget on settings.changed signal to handle reset correctly"

patterns-established:
  - "WidgetFactory.create_row(def, scanner) as single entry point for all widget types"
  - "attach_reset_and_tracking() for ActionRow-based widgets, attach_reset_and_tracking_entry() for EntryRow"
  - "get_cached_settings() via static HashTable for GSettings object deduplication"
  - "Guard against signal loops by comparing current value before writing in notify handlers"

requirements-completed: [FR-3, FR-5]

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 3 Plan 1: Widget Factory Summary

**WidgetFactory static class dispatching SettingDef metadata to interactive Adwaita widgets with GSettings bindings, reset-to-default buttons, and changed-settings CSS highlighting**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-08T17:14:49Z
- **Completed:** 2026-03-08T17:23:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created WidgetFactory with create_row() dispatching on all 8 WidgetHint enum values (SWITCH, COMBO, SPIN_INT, SPIN_DOUBLE, FONT, ENTRY, AUTO, CUSTOM)
- Implemented GSettings object cache via HashTable to avoid duplicate objects per schema_id
- Added reset-to-default button on every row using get_user_value() for detection and settings.reset() for action
- Dynamic setting-modified CSS class applied/removed via GSettings changed signal
- AUTO hint resolves schema key type at runtime and dispatches to correct widget creator
- Clean build verified with meson setup --wipe + ninja

## Task Commits

Each task was committed atomically:

1. **Task 1: Create WidgetFactory with all widget creators and reset/changed highlighting** - `a6bb87e` (feat)
2. **Task 2: Add widget-factory.vala to meson.build** - `9ab990d` (chore)

## Files Created/Modified
- `src/core/widget-factory.vala` - WidgetFactory static class (372 lines) with create_row() entry point, 7 widget creators, AUTO resolution, GSettings cache, reset button, and CSS tracking
- `meson.build` - Added src/core/widget-factory.vala to sources list

## Decisions Made
- EntryRow needs a separate reset/tracking helper because it extends Adw.PreferencesRow (not Adw.ActionRow), so add_suffix() is a different method
- display_factor of 0.0 (default unset double) treated as 1.0 (no scaling) for forward compatibility when registry entries start using it
- AUTO hint enum values get labels auto-generated from range data values (capitalized, hyphens/underscores replaced with spaces)
- COMBO and SPIN rows connect to settings.changed signal to sync widget value on external changes (e.g., reset), with guard checks to prevent re-entrancy loops

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] EntryRow is not an ActionRow -- separate suffix handler needed**
- **Found during:** Task 2 (build verification)
- **Issue:** attach_reset_and_tracking() accepts Adw.ActionRow but Adw.EntryRow extends Adw.PreferencesRow, not ActionRow. Vala compiler error: "Cannot convert from unowned Adw.EntryRow to unowned Adw.ActionRow"
- **Fix:** Created attach_reset_and_tracking_entry() overload that accepts Adw.EntryRow and calls its own add_suffix()
- **Files modified:** src/core/widget-factory.vala
- **Verification:** Clean build with meson setup --wipe + ninja
- **Committed in:** a6bb87e (amended into Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Type hierarchy mismatch required a second reset/tracking method. No scope creep.

## Issues Encountered
None beyond the auto-fixed EntryRow type issue.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- WidgetFactory is ready to be wired into window.vala's build_category_page() (Plan 03-02)
- Plan 03-02 will replace placeholder ActionRows with WidgetFactory.create_row() calls
- CSS class "setting-modified" is being applied but not yet styled (Phase 4 handles visual design)

## Self-Check: PASSED

- FOUND: src/core/widget-factory.vala
- FOUND: commit a6bb87e (Task 1)
- FOUND: commit 9ab990d (Task 2)

---
*Phase: 03-widget-factory-panel-generation*
*Completed: 2026-03-08*
