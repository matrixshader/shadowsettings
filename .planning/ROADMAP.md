# Shadow Settings — Roadmap

## Milestone 1: Ship It

### Phase 1: App Identity & Foundation
**Goal:** Rename from Construct to Shadow Settings, set permanent app ID, fix all references, null-guard all schema access.

**Why first:** App ID is permanent for Flathub. Every file (desktop, polkit, icons, meson.build) keys off it. Must be right before anything else. Also, null-guarding schema access is the #1 production-readiness fix — current code crashes on missing schemas.

**Requirements addressed:** NFR-6 (App Identity), FR-1 (null-guarding)

**Plans:** 2 plans

Plans:
- [x] 01-01-PLAN.md — Rename app from Construct to Shadow Settings, set app ID to io.github.matrixshader.ShadowSettings
- [x] 01-02-PLAN.md — Create SafeSettings helper and null-guard all GSettings access across panels

**Success criteria:**
- [x] App ID set to `io.github.matrixshader.ShadowSettings` (or finalized alternative)
- [x] All files updated: meson.build, desktop file, polkit policy, icon paths, application.vala
- [x] Binary renamed from `construct` to `shadow-settings`
- [x] Every `new GLib.Settings()` call guarded with `SettingsSchemaSource.lookup()` check
- [x] App builds clean and launches without crashes
- [x] Old "Construct" branding completely removed

---

### Phase 2: Dynamic Detection Engine
**Goal:** Build the schema scanner that discovers all hidden GNOME settings at runtime, replacing hardcoded panel content.

**Why second:** This IS the product. Without dynamic detection, Shadow Settings is just another Tweaks clone. The widget factory (Phase 3) depends on the detection engine's output format.

**Requirements addressed:** FR-1 (Dynamic Detection), FR-2 (Known-Exposed Blocklist), FR-4 (Category Organization)

**Plans:** 2 plans

Plans:
- [x] 02-01-PLAN.md — Create SettingDef data model, SchemaScanner, and CategoryMapper core types
- [x] 02-02-PLAN.md — Populate curated registry with hidden settings, wire dynamic sidebar and settings count

**Success criteria:**
- [x] `SchemaScanner` class that enumerates all installed GSettings schemas via `SettingsSchemaSource.list_schemas()`
- [x] Filter layer with "known-exposed" blocklist (settings GNOME Settings already shows)
- [x] Category mapper that assigns detected keys to logical panels (Power, Windows, Desktop, Appearance, Input)
- [x] Scanner output is a structured data model consumable by the widget factory
- [x] On Fedora: app shows settings that exist but aren't in GNOME Settings
- [x] Settings count displayed somewhere (e.g., "42 hidden settings found on your system")

---

### Phase 3: Widget Factory & Panel Generation
**Goal:** Auto-generate appropriate UI widgets from detected setting metadata, replacing hardcoded panel code.

**Why third:** Depends on Phase 2's detection engine output. Transforms raw schema data into interactive UI.

**Requirements addressed:** FR-3 (Widget Factory), FR-5 (Reset to Default + Changed Highlighting), FR-7 (Logind gating)

**Plans:** 2 plans

Plans:
- [ ] 03-01-PLAN.md — Create WidgetFactory static class with all widget creators, reset-to-default, and changed-settings highlighting
- [ ] 03-02-PLAN.md — Wire factory into window.vala with lazy panel construction, remove dead hardcoded panels

**Success criteria:**
- [ ] `WidgetFactory` that maps `SettingsSchemaKey.get_value_type()` + `get_range()` to correct Adwaita widget
- [ ] Boolean → SwitchRow, Enum → ComboRow, Int range → SpinRow, Double → SpinRow, String → EntryRow/ComboRow
- [ ] Each row shows key summary as title, description as subtitle
- [ ] Range constraints enforced — cannot set invalid values
- [ ] Reset-to-default action on each setting (compare current vs default value)
- [ ] Changed settings visually highlighted (CSS class on modified rows)
- [ ] Logind features auto-hidden when `/.flatpak-info` exists
- [ ] Lazy panel construction (build widgets only on first panel visit)

---

### Phase 4: Visual Identity & Design
**Goal:** Transform from stock Adwaita into a distinctive, recognizable app with custom CSS, animations, and visual polish.

**Why fourth:** Design on real content. Panels must be functional before we style them — otherwise we're designing in the dark.

**Requirements addressed:** NFR-1 (Visual Identity), FR-8 (About Dialog & Branding)

**Success criteria:**
- [ ] Custom CSS stylesheet loaded via GResource at APPLICATION priority
- [ ] Distinctive visual identity — not stock Adwaita toggle lists
- [ ] Light mode, dark mode, and high contrast all work correctly
- [ ] CSS uses libadwaita variables for theme-adaptive colors
- [ ] Panel transitions with AdwTimedAnimation or spring animations
- [ ] About dialog with Matrix Shader branding, tip jar link, matrixshader.com link
- [ ] App icon (SVG) that reflects Shadow Settings identity
- [ ] Visually distinguishable from GNOME Settings/Tweaks/Refine in a screenshot

---

### Phase 5: Search, Polish & Distribution
**Goal:** Add search, final polish, Flatpak packaging, and Flathub submission.

**Why last:** Search needs all panels built. Flatpak adds sandbox complexity — native build should be solid first.

**Requirements addressed:** FR-6 (Search), NFR-2 (Performance), NFR-3 (Binary Size), NFR-4 (GNOME Compat), NFR-5 (Flatpak)

**Success criteria:**
- [ ] Search across all settings (index summaries + descriptions)
- [ ] Search filters across all categories
- [ ] Launch time under 500ms, schema scan under 100ms
- [ ] Binary under 500KB
- [ ] Flatpak manifest with correct permissions (dconf portal, D-Bus for logind)
- [ ] `flatpak-builder-lint` passes clean
- [ ] Appstream metainfo.xml with screenshots and descriptions
- [ ] GitHub repo created (matrixshader/shadow-settings)
- [ ] Flathub submission PR opened
- [ ] README with install instructions (native + Flatpak)
