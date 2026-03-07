# Shadow Settings — Project State

## Current Phase
Phase 1: App Identity & Foundation (NOT STARTED)

## Progress
- [x] Project initialized
- [x] Research complete (Stack, Features, Architecture, Pitfalls)
- [x] Requirements defined
- [x] Roadmap created (5 phases)
- [ ] Phase 1: App Identity & Foundation
- [ ] Phase 2: Dynamic Detection Engine
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
- App ID: `com.github.matrixshader.construct` (needs changing)

## Next Action
Run `/gsd:plan-phase 1` to plan the App Identity & Foundation phase.
