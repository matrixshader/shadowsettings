---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: Completed 04-02-PLAN.md (Phase 4 complete)
last_updated: "2026-03-14T20:48:35.042Z"
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 10
  completed_plans: 9
---

# Shadow Settings — Project State

## Current Phase
Phase 5: Search, Polish & Distribution (1 of 2 plans done)

## Progress
- [x] Project initialized
- [x] Research complete (Stack, Features, Architecture, Pitfalls)
- [x] Requirements defined
- [x] Roadmap created (5 phases)
- [x] Phase 1: App Identity & Foundation
- [x] Phase 2: Dynamic Detection Engine
- [x] Phase 3: Widget Factory & Panel Generation
- [x] Phase 4: Visual Identity & Design
- [ ] Phase 5: Search, Polish & Distribution

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Name | Shadow Settings | The settings hiding in the shadow of your system |
| Stack | Vala + GTK4 + libadwaita + Meson | Existing prototype, native binary, first-class GObject support |
| App ID | `io.github.matrixshader.ShadowSettings` | Flathub requires `io.github.*` not `com.github.*` |
| Detection | Dynamic schema scanning at runtime | Self-maintaining, works across distros/versions |
| Distribution | Flathub (Flatpak) + native | Flathub for reach, native for full features (logind) |
| Brand | Standalone, not Matrix Shader product | Links to Matrix Shader in About dialog, but separate project |
| Missing schema UX | Silent skip, no empty-state UI | Phase 1 simplicity; better UX deferred to Phase 3 widget factory |
| SafeSettings pattern | Static helper with cached SettingsSchemaSource | All GSettings access via SafeSettings.try_get(), never direct constructor |
| CATEGORY_ORDER type | `const string[]` at namespace level | Vala allows const for plain string arrays; static rejected as non-constant initializer |
| SchemaScanner source | Own SettingsSchemaSource instance | Separation of concerns from SafeSettings helper |
| Registry pattern | Static methods returning SettingDef[] | Avoids Vala nullable field limitation in const struct arrays |
| Power/logind in registry | Included but skipped by scanner | Documentation completeness; PowerPanel handles native logind directly |
| WM prefs split | 2 font keys in Appearance, 10 in Windows | FR-4: same schema across multiple categories by editorial curation |

## Critical Findings from Research
1. Every `new GLib.Settings()` in prototype will crash on missing schemas — must null-guard (Phase 1)
2. pkexec broken in Flatpak — logind features must auto-hide in sandbox (Phase 3)
3. App ID `com.github.*` rejected by Flathub — must use `io.github.*` (Phase 1)
4. libadwaita 1.8 supports CSS media queries for light/dark/HC in single stylesheet (Phase 4)
5. `SettingsSchemaSource` API provides everything needed for dynamic detection (Phase 2)
6. No settings app has visual identity — huge opportunity (Phase 4)

## Existing Code
Location: `/home/neo/shadow-settings/` (renamed from `construct/`)
- 5 working panels (Power, Windows, Desktop, Appearance, Input)
- gsettings bindings functional
- logind helper with pkexec
- Zero custom CSS
- All hardcoded — no dynamic detection
- App ID: `io.github.matrixshader.ShadowSettings` (DONE - Plan 01-01)
- All GSettings access null-guarded via SafeSettings helper (DONE - Plan 01-02)

## Plan Completion
| Phase | Plan | Status | Duration | Commit |
|-------|------|--------|----------|--------|
| 01 | 01-01 (App Identity Rename) | COMPLETE | 5min | 3a9e0b0, 7cf54a5 |
| 01 | 01-02 (SafeSettings Null-Guarding) | COMPLETE | 3min | 74f210b, d5c689b |
| 02 | 02-01 (Core Data Model & Detection) | COMPLETE | 4min | 2e945ba, abc83b8 |
| 02 | 02-02 (Setting Registry & Dynamic Sidebar) | COMPLETE | 4min | 0debbbc, cf59d41 |
| 03 | 03-01 (Widget Factory) | COMPLETE | 8min | a6bb87e, 9ab990d |
| 03 | 03-02 (Panel Generation) | COMPLETE | 5min | b877e4d, 18144ad |
| 04 | 04-01 (Theme Infrastructure) | COMPLETE | 5min | 063f095, 7417647 |
| 04 | 04-02 (Animations, About & Icon) | COMPLETE | 5min | a2fe7d2, 7dcf25c, d4632d1 |
| 05 | 05-01 (Search & Deprecated Key Filter) | COMPLETE | 2min | 5492344, a3eb71a |

## Key Decisions (Phase 3)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| EntryRow reset handler | Separate attach_reset_and_tracking_entry() | EntryRow extends PreferencesRow not ActionRow; different add_suffix() method |
| display_factor default | Treat 0.0 as 1.0 (no scaling) | Forward compatibility for future registry entries |
| AUTO enum labels | Auto-capitalize from range data values | No manual label curation needed for dynamically discovered enum values |
| Signal loop prevention | Compare before writing in notify handlers | COMBO/SPIN rows guard against re-entrancy without disconnect/reconnect |
| Lazy construction tracking | HashTable<string,bool> for panels_built | Simple and efficient gate for build_category_page_with_widgets() |
| First panel eager | Build first category page at startup | Prevents blank content area on launch (research Pitfall 6) |
| Dead panel cleanup | Remove from meson.build, keep files on disk | Files serve as reference; full cleanup in a future pass |

## Key Decisions (Phase 4)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| CSS class switching for themes | window.gotham-night/gotham-day/wayne-manor classes | 3 themes need more than dark/light toggle; CSS classes + StyleManager color scheme |
| GSettings direct read in construct | SafeSettings.try_get() in build_preferences_page() | ThemeManager doesn't exist during Window construct; read directly from GSettings |
| Preferences as content_stack page | Full PreferencesPage in same stack | Consistent with lazy-loading architecture; no special-case routing |
| Owned getter for current_theme | Vala `owned get` property | GSettings.get_string() returns owned string; Vala ownership rules require explicit transfer |
| AdwAboutWindow for About dialog | AdwAboutWindow (not AdwAboutDialog) | Available since libadwaita 1.2, ensuring GNOME 43+ compatibility per NFR-4 |
| Gear icon only for prefs | No label, just gear icon in sidebar | Cleaner sidebar that doesn't compete with category names |

## Key Decisions (Phase 5)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Search results not animated | No Animator.cascade_rows() on search results | Animating on every keystroke at 150ms debounce rate is jarring |
| DEPRECATED_KEYS filter position | Before curated override check in discover_all() | Ensures deprecated keys excluded regardless of registry presence |
| Search stack cleanup | Remove old "search" child before each new search | Prevents unbounded content_stack accumulation on repeated searches |
| last_panel_id tracking | Updated in row_selected handler | Always tracks most recently manually-selected panel for search dismissal restore |

## Last Session
- **Stopped at:** Completed 05-01-PLAN.md (Search & Deprecated Key Filter)
- **Timestamp:** 2026-03-14T20:47:34Z

## Next Action
Phase 5: Search, Polish & Distribution. Plan 05-02 is next.
