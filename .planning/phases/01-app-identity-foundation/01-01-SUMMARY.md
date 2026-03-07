---
phase: 01-app-identity-foundation
plan: 01
subsystem: infra
tags: [vala, gtk4, meson, app-id, flathub, polkit, branding]

# Dependency graph
requires: []
provides:
  - "Permanent app ID: io.github.matrixshader.ShadowSettings"
  - "Binary name: shadow-settings"
  - "ShadowSettings namespace in all Vala source files"
  - "Renamed desktop, polkit, and icon files"
affects: [01-app-identity-foundation, 02-dynamic-detection-engine, 05-search-polish-distribution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "App ID as io.github.* prefix (Flathub requirement)"
    - "Logind drop-in named after app: 99-shadow-settings.conf"

key-files:
  created:
    - "data/io.github.matrixshader.ShadowSettings.desktop"
    - "polkit/io.github.matrixshader.ShadowSettings.policy"
    - "data/icons/hicolor/scalable/apps/io.github.matrixshader.ShadowSettings.svg"
  modified:
    - "meson.build"
    - "src/main.vala"
    - "src/application.vala"
    - "src/window.vala"
    - "src/panels/power.vala"
    - "src/panels/windows.vala"
    - "src/panels/desktop.vala"
    - "src/panels/appearance.vala"
    - "src/panels/input.vala"
    - "src/helpers/logind-helper.vala"

key-decisions:
  - "App ID set to io.github.matrixshader.ShadowSettings (Flathub-compliant)"
  - "Namespace changed from Construct to ShadowSettings across all Vala files"
  - "Sidebar subtitle changed to 'The Settings They Took' (previously 'Settings They Took')"

patterns-established:
  - "All files use io.github.matrixshader.ShadowSettings as the app ID consistently"
  - "Binary is shadow-settings everywhere (meson.build, desktop file)"

requirements-completed: [NFR-6]

# Metrics
duration: 5min
completed: 2026-03-07
---

# Phase 1 Plan 1: App Identity Rename Summary

**Full rename from Construct to Shadow Settings with io.github.matrixshader.ShadowSettings app ID, ShadowSettings namespace, and clean build verification**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-07T03:52:40Z
- **Completed:** 2026-03-07T03:57:40Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Renamed all data files (desktop, polkit, icon) from com.github.matrixshader.construct to io.github.matrixshader.ShadowSettings
- Updated all 9 Vala source files from Construct namespace to ShadowSettings namespace
- Updated meson.build with new project name, binary name, and file paths
- Changed window title from "The Construct" to "Shadow Settings"
- Changed logind drop-in from 99-construct.conf to 99-shadow-settings.conf
- Clean build verified: shadow-settings binary compiles at 275KB with zero errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename data files and update their contents** - `3a9e0b0` (feat)
2. **Task 2: Update all source files and meson.build with new identity** - `7cf54a5` (feat)
3. **Task 3: Build and verify the renamed app launches** - No code changes (build verification only)

## Files Created/Modified
- `data/io.github.matrixshader.ShadowSettings.desktop` - Desktop entry with new name, exec, icon
- `polkit/io.github.matrixshader.ShadowSettings.policy` - Polkit policy with new action ID
- `data/icons/hicolor/scalable/apps/io.github.matrixshader.ShadowSettings.svg` - Renamed icon (content unchanged)
- `meson.build` - Project name, binary name, install paths all updated
- `src/main.vala` - ShadowSettings.Application reference
- `src/application.vala` - New app ID and ShadowSettings namespace
- `src/window.vala` - New title, sidebar header, namespace
- `src/panels/power.vala` - ShadowSettings namespace
- `src/panels/windows.vala` - ShadowSettings namespace
- `src/panels/desktop.vala` - ShadowSettings namespace
- `src/panels/appearance.vala` - ShadowSettings namespace
- `src/panels/input.vala` - ShadowSettings namespace
- `src/helpers/logind-helper.vala` - ShadowSettings namespace, 99-shadow-settings.conf

## Decisions Made
- App ID set to `io.github.matrixshader.ShadowSettings` (Flathub requires io.github.* prefix, not com.github.*)
- Namespace changed from `Construct` to `ShadowSettings` across all Vala files
- Sidebar subtitle updated from "Settings They Took" to "The Settings They Took"

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- App identity is locked in and permanent -- all subsequent work builds on this foundation
- Plan 01-02 (SafeSettings null-guarding) can proceed immediately
- Build system verified working with clean compilation

## Self-Check: PASSED

- All 13 files verified present on disk
- Both task commits (3a9e0b0, 7cf54a5) verified in git history

---
*Phase: 01-app-identity-foundation*
*Completed: 2026-03-07*
