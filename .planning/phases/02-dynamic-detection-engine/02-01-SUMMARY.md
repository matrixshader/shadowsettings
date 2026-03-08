---
phase: 02-dynamic-detection-engine
plan: 01
subsystem: core
tags: [vala, gsettings, schema-detection, data-model, runtime-scan]

# Dependency graph
requires:
  - phase: 01-app-identity-foundation
    provides: SafeSettings helper for null-safe GSettings access
provides:
  - SettingDef struct for declarative setting descriptions
  - WidgetHint enum for widget type selection
  - CategoryInfo struct for sidebar grouping
  - SchemaScanner class for runtime schema/key validation
  - CategoryMapper class for ordered category grouping
  - CATEGORY_ORDER constant for sidebar presentation order
affects: [02-02-setting-registry, 03-widget-factory, 03-panel-generation]

# Tech tracking
tech-stack:
  added: []
  patterns: [data-driven-settings, runtime-schema-detection, category-ordered-grouping]

key-files:
  created:
    - src/core/setting-def.vala
    - src/core/schema-scanner.vala
    - src/core/category-mapper.vala
  modified:
    - meson.build

key-decisions:
  - "CATEGORY_ORDER uses const string[] at namespace level (not static) -- Vala allows const for plain string arrays"
  - "SchemaScanner owns its own SettingsSchemaSource instance (not reusing SafeSettings) for separation of concerns"
  - "CategoryMapper extracts title/icon from first SettingDef in each group rather than separate lookup table"

patterns-established:
  - "SettingDef struct: all setting metadata in one value type for registry declarations"
  - "scan-then-map pipeline: SchemaScanner.scan() filters, CategoryMapper.map() groups"
  - "has_key() before get_key(): always guard SettingsSchemaKey access to prevent abort"

requirements-completed: [FR-1, FR-4]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 2 Plan 1: Core Data Model & Detection Engine Summary

**SettingDef/WidgetHint/CategoryInfo data model with SchemaScanner runtime detection and CategoryMapper ordered grouping**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T04:38:52Z
- **Completed:** 2026-03-08T04:57:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created the SettingDef struct that declaratively describes any GSettings key with schema, label, category, widget hint, and constraints
- Built SchemaScanner that filters a SettingDef array to only settings existing on the running system via SettingsSchemaSource lookup
- Built CategoryMapper that groups filtered settings by category in CATEGORY_ORDER sidebar order, omitting empty categories
- All three new files compile cleanly into the shadow-settings binary

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SettingDef data model and supporting types** - `2e945ba` (feat)
2. **Task 2: Create SchemaScanner and CategoryMapper, update meson.build** - `abc83b8` (feat)

## Files Created/Modified
- `src/core/setting-def.vala` - WidgetHint enum, SettingDef struct, CategoryInfo struct, CATEGORY_ORDER constant
- `src/core/schema-scanner.vala` - SchemaScanner class with scan() and get_key_info() methods
- `src/core/category-mapper.vala` - CategoryMapper class with map() method for ordered category grouping
- `meson.build` - Added three new src/core/ source files to build

## Decisions Made
- CATEGORY_ORDER uses `const string[]` at namespace level -- Vala allows const for plain string arrays even though structs with nullable fields cannot be const
- SchemaScanner owns its own SettingsSchemaSource instance rather than reusing SafeSettings, keeping detection logic self-contained
- CategoryMapper extracts title and icon from the first SettingDef encountered in each category group, avoiding a separate lookup table

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed CATEGORY_ORDER declaration from static to const**
- **Found during:** Task 2 (build verification)
- **Issue:** `public static string[] CATEGORY_ORDER = {...}` rejected by valac 0.56.18 with "Non-constant field initializers not supported in this context"
- **Fix:** Changed to `public const string[] CATEGORY_ORDER = {...}` which Vala accepts for plain string arrays at namespace level
- **Files modified:** src/core/setting-def.vala
- **Verification:** Clean build with zero errors
- **Committed in:** abc83b8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Anticipated by plan (Pitfall 1 warning). Trivial keyword change, no scope creep.

## Issues Encountered
None beyond the anticipated Pitfall 1 const/static issue.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Core data model and detection engine ready for Plan 02-02 (Setting Registry)
- SettingDef struct provides the contract for registry file declarations
- SchemaScanner and CategoryMapper provide the pipeline for runtime filtering and grouping
- No blockers for downstream plans

## Self-Check: PASSED

All 4 files verified present. Both commit hashes (2e945ba, abc83b8) found in git log.

---
*Phase: 02-dynamic-detection-engine*
*Completed: 2026-03-08*
