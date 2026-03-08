---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: in-progress
stopped_at: Completed 03-01-PLAN.md
last_updated: "2026-03-08T17:25:30.234Z"
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 6
  completed_plans: 5
---

# Shadow Settings — Project State

## Current Phase
Phase 3: Widget Factory & Panel Generation (1 of 2 plans done)

## Progress
- [x] Project initialized
- [x] Research complete (Stack, Features, Architecture, Pitfalls)
- [x] Requirements defined
- [x] Roadmap created (5 phases)
- [x] Phase 1: App Identity & Foundation
- [x] Phase 2: Dynamic Detection Engine
- [ ] Phase 3: Widget Factory & Panel Generation
- [ ] Phase 4: Visual Identity & Design
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

## Key Decisions (Phase 3)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| EntryRow reset handler | Separate attach_reset_and_tracking_entry() | EntryRow extends PreferencesRow not ActionRow; different add_suffix() method |
| display_factor default | Treat 0.0 as 1.0 (no scaling) | Forward compatibility for future registry entries |
| AUTO enum labels | Auto-capitalize from range data values | No manual label curation needed for dynamically discovered enum values |
| Signal loop prevention | Compare before writing in notify handlers | COMBO/SPIN rows guard against re-entrancy without disconnect/reconnect |

## Last Session
- **Stopped at:** Completed 03-01-PLAN.md
- **Timestamp:** 2026-03-08T17:23:02Z

## Next Action
Execute Plan 03-02: Panel Generation (wire WidgetFactory into window.vala).
