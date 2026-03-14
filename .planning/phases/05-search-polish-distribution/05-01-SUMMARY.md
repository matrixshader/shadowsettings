---
phase: 05-search-polish-distribution
plan: 01
subsystem: ui
tags: [vala, gtk4, libadwaita, search, gsettings, schema-scanner]

# Dependency graph
requires:
  - phase: 04-visual-identity
    provides: Window UI with sidebar NavigationSplitView, content Stack, CategoryInfo[], SchemaScanner, categories instance field
  - phase: 03-widget-factory
    provides: WidgetFactory.create_row() for creating interactive setting rows
provides:
  - Search UI with Gtk.SearchBar + Gtk.SearchEntry in sidebar header
  - Ctrl+F shortcut and type-anywhere key capture to activate search
  - Cross-category result filtering with PreferencesGroup category headers
  - No-results StatusPage empty state
  - Search dismissal restoring previous panel and subtitle
  - DEPRECATED_KEYS filter removing 14 GTK2/GTK3 keys from auto-discovery
affects: [05-search-polish-distribution, distribution, flathub]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SearchBar with set_key_capture_widget(window) enables type-anywhere search activation"
    - "Bind search_btn.active to search_bar.search-mode-enabled BIDIRECTIONAL for toggle sync"
    - "Remove old search stack child on each keystroke to prevent content_stack accumulation"
    - "DEPRECATED_KEYS constant as schema_id:key-name strings filtered before curated check"

key-files:
  created: []
  modified:
    - src/core/schema-scanner.vala
    - src/window.vala

key-decisions:
  - "Search results grouped by category using PreferencesGroup — consistent with existing panel layout"
  - "No Animator.cascade_rows() on search results — animation on every keystroke is jarring"
  - "last_panel_id tracked in row_selected handler so search dismissal can restore correct panel"
  - "DEPRECATED_KEYS filter runs before curated override check to ensure deprecated keys are excluded regardless of registry"

patterns-established:
  - "perform_search() removes old 'search' stack child before adding new one to prevent stack accumulation"
  - "search_bar.notify[search-mode-enabled] handler restores subtitle and panel on dismiss"

requirements-completed: [FR-6, NFR-2]

# Metrics
duration: 2min
completed: 2026-03-14
---

# Phase 5 Plan 1: Search & Deprecated Key Filter Summary

**Gtk.SearchBar with type-anywhere key capture delivering cross-category settings search, plus DEPRECATED_KEYS filter removing 14 obsolete GTK2/GTK3 keys from auto-discovery**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T20:45:39Z
- **Completed:** 2026-03-14T20:47:34Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added DEPRECATED_KEYS constant (14 entries) + is_deprecated_key() helper to SchemaScanner; deprecated GTK2/GTK3 keys like can-change-accels and menus-have-tearoff no longer surface in the UI
- Search toggle button (magnifying glass) appears in sidebar header; clicking it or pressing Ctrl+F activates SearchBar with SearchEntry
- Type-anywhere key capture (set_key_capture_widget) activates search from any keyboard input in the window
- perform_search() iterates all categories, matches label/subtitle case-insensitively, groups results by category with PreferencesGroup headers
- No-results state shows Adw.StatusPage with edit-find-symbolic icon
- Escape (stop_search signal) and search dismissal restore the previously viewed panel and subtitle

## Task Commits

Each task was committed atomically:

1. **Task 1: Add deprecated key filter to SchemaScanner** - `5492344` (feat)
2. **Task 2: Implement search UI with cross-category filtering** - `a3eb71a` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `src/core/schema-scanner.vala` - Added DEPRECATED_KEYS const (14 keys), is_deprecated_key() helper, and deprecation check in discover_all() loop
- `src/window.vala` - Added search_bar, search_entry, sidebar_title, display_count, last_panel_id instance fields; SearchBar + SearchEntry + search toggle button; Ctrl+F shortcut; perform_search() method

## Decisions Made
- Search results not animated via Animator.cascade_rows() — animating on every keystroke would be jarring at 150ms debounce rate
- last_panel_id is tracked in row_selected (not in panel build) so the value always represents the most recently manually-selected panel
- DEPRECATED_KEYS check runs before curated override lookup so curated registry entries for deprecated keys are also excluded
- Old "search" stack child removed before each new search via get_child_by_name("search") + remove() to prevent unbounded accumulation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Search feature complete, ready for Phase 5 Plan 2 (distribution/Flatpak packaging)
- All 598+ auto-discovered settings are now searchable via type-anywhere or Ctrl+F
- Deprecated keys filtered, no GTK2/GTK3 noise in results

---
*Phase: 05-search-polish-distribution*
*Completed: 2026-03-14*
