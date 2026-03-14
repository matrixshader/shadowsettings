---
phase: 05-search-polish-distribution
plan: "02"
subsystem: infra
tags: [flatpak, flathub, appstream, meson, distribution]

# Dependency graph
requires:
  - phase: 05-01
    provides: Search and deprecated key filter features that are being packaged
provides:
  - Flatpak manifest with GNOME Platform 48, release buildtype, minimal sandbox permissions
  - Appstream metainfo.xml with all Flathub-required fields
  - Meson install rule for metainfo to share/metainfo/
  - README with native and Flatpak install instructions
  - NFR-3 verified: release binary 212KB (< 500KB target)
  - NFR-4 verified: build succeeds against GTK4 4.12+ / libadwaita 1.4+
affects: [flathub-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Flatpak manifest uses org.gnome.Platform//48 with --buildtype=release for NFR-3 compliance"
    - "Metainfo uses developer id attribute (not deprecated developer_name tag)"

key-files:
  created:
    - io.github.matrixshader.ShadowSettings.json
    - data/io.github.matrixshader.ShadowSettings.metainfo.xml
    - README.md
  modified:
    - meson.build

key-decisions:
  - "No --filesystem=home, --socket=session-bus, or --system-talk-name=org.freedesktop.login1 in finish-args (logind auto-hidden via /.flatpak-info check)"
  - "--metadata=X-DConf=migrate-path for GSettings migration (keyfile backend automatic with GNOME 48 runtime)"
  - "Screenshot URL placeholder points to data/screenshots/main.png on GitHub (human takes screenshot before submission)"
  - "GNOME Platform 48 chosen as runtime (latest stable at time of submission)"
  - "Metainfo install_dir uses share/metainfo/ (not deprecated share/appdata/)"

patterns-established:
  - "Metainfo: install to share/metainfo/ via meson install_data, not share/appdata/"
  - "Metainfo: developer element uses id attribute with child name element, not deprecated developer_name tag"

requirements-completed: [NFR-2, NFR-3, NFR-4, NFR-5]

# Metrics
duration: 5min
completed: 2026-03-14
---

# Phase 5 Plan 02: Distribution Packaging Summary

**Flatpak manifest, Appstream metainfo, and README created for Flathub submission; NFR-3 release binary at 212KB (target < 500KB) and NFR-4 build against GTK4 4.12+/libadwaita 1.4+ both verified**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-14T20:50:35Z
- **Completed:** 2026-03-14T20:55:40Z
- **Tasks:** 2 of 3 (Task 3 is checkpoint:human-verify)
- **Files modified:** 4

## Accomplishments

- Flatpak manifest created with GNOME Platform 48, release buildtype, and minimal sandbox permissions (no filesystem=home, no session-bus)
- Appstream metainfo XML created with all Flathub-required fields: developer id, content_rating oars-1.1, releases, screenshots placeholder, launchable
- Meson install rule added for metainfo to share/metainfo/ (not deprecated share/appdata/)
- README created with native and Flatpak install instructions for Fedora and Ubuntu/Debian
- NFR-3 verified: release binary is 212KB, well under 500KB target
- NFR-4 verified: build succeeds cleanly against GTK4 >= 4.12 and libadwaita-1 >= 1.4

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Flatpak manifest, metainfo, and meson install rules** - `8a0e865` (chore)
2. **Task 2: Create README and verify NFR compliance** - `a2698dd` (docs)

**Plan metadata:** committed after state updates

## Files Created/Modified

- `io.github.matrixshader.ShadowSettings.json` - Flatpak manifest for Flathub submission
- `data/io.github.matrixshader.ShadowSettings.metainfo.xml` - Appstream metainfo with all Flathub-required fields
- `meson.build` - Added metainfo install_data rule to share/metainfo/
- `README.md` - Project description, features, Flatpak install, build-from-source, license

## Decisions Made

- No `--filesystem=home`, `--socket=session-bus`, or `--system-talk-name=org.freedesktop.login1` in finish-args — logind features already auto-hide inside Flatpak via `/.flatpak-info` check (implemented in Phase 3)
- `--metadata=X-DConf=migrate-path` used for GSettings migration support with GNOME 48's keyfile backend
- Screenshot URL placeholder points to `data/screenshots/main.png` on GitHub — human must take screenshot before Flathub submission
- GNOME Platform 48 chosen as runtime (latest stable at time of execution)
- Metainfo installs to `share/metainfo/` not deprecated `share/appdata/`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. `builddir-rel` already existed from prior work; release binary was already compiled, confirming 212KB size.

## User Setup Required

External services require manual configuration before Flathub submission:

1. **GitHub repo** — Create public repo `matrixshader/shadow-settings` at github.com/new, push code to main branch
2. **Screenshot** — Take at least one screenshot, save to `data/screenshots/main.png`, commit and push
3. **Flathub PR** — Fork `flathub/flathub`, create branch, add manifest, open PR manually (AI submission prohibited by Flathub policy)

## Next Phase Readiness

- All distribution files are complete: manifest, metainfo, README
- Task 3 checkpoint requires human visual verification of the complete Phase 5 output (search, deprecated key filtering, distribution files)
- After human verification, the app is ready for Flathub submission
- Human checklist provided in Task 3 checkpoint message

---
*Phase: 05-search-polish-distribution*
*Completed: 2026-03-14*
