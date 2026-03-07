# Research Summary: Shadow Settings

**Domain:** GNOME desktop settings/tweaks application
**Researched:** 2026-03-06
**Overall confidence:** HIGH

## Executive Summary

Shadow Settings is a GTK4/libadwaita settings app that dynamically detects hidden GNOME settings at runtime. The existing prototype has a solid foundation -- Vala/GTK4/libadwaita/Meson is the correct stack, and the 5 working panels prove the core concept. The primary technical challenge is the transition from hardcoded settings panels to a dynamic detection engine, and the GLib API for this (`GSettingsSchemaSource`, `SettingsSchema`, `SettingsSchemaKey`) is comprehensive, well-documented, and natively available in Vala.

The Vala + GTK4 + libadwaita stack is validated. The installed versions (Vala 0.56.18, GTK4 4.20.3, libadwaita 1.8.4, GLib 2.86.4, Meson 1.8.5) are all current stable releases. Vala compiles to native binaries with first-class GObject/GSettings support -- there is no language impedance mismatch. The competitors (Refine uses Python/PyGObject, Tweaks uses Python/GTK3) are either slower or dated; Vala gives Shadow Settings a performance and binary-size advantage.

The critical architectural challenge is defining "hidden." There is no API that says "GNOME Settings exposes key X." The solution is a two-layer approach: runtime schema discovery (dynamic, self-maintaining) combined with a curated filter of "known exposed" keys (the small hardcoded element). This gives the self-maintaining property for schema detection while ensuring the app doesn't degenerate into dconf-editor.

Flatpak distribution introduces the most complexity. GSettings access works through the dconf portal in modern runtimes. But pkexec (used for logind config) does not work in Flatpak at all -- the logind features must be gated based on environment detection. Flathub submission requires careful permission management and thorough metadata. The app should ship a native build first for full functionality, with Flatpak as the broad-reach distribution (minus logind features).

## Key Findings

**Stack:** Vala 0.56.18 + GTK4 4.20+ + libadwaita 1.4+ + Meson + GResource bundling. All current, all correct.

**Architecture:** Dynamic detection via `SettingsSchemaSource.list_schemas()` -> filter with known-exposed blocklist -> category mapping -> widget factory based on `SettingsSchemaKey.get_value_type()` + `get_range()`.

**Critical pitfall:** Direct `new GLib.Settings(schema_id)` without `SettingsSchemaSource.lookup()` will crash on systems missing schemas. Every schema/key access in the prototype needs null-guarding. This is the #1 production-readiness fix.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **App Identity & Foundation** - Rename from "Construct" to "Shadow Settings", set permanent app ID, update all references (desktop file, polkit, icons)
   - Addresses: App ID migration (PITFALLS #5/#15), branding
   - Avoids: Flathub app ID is permanent -- must be right before any public release

2. **Dynamic Detection Engine** - Build schema scanner, hidden filter, and category mapper
   - Addresses: Core value prop (FEATURES: dynamic detection), schema safety (PITFALLS #2)
   - Avoids: Hardcoded settings lists (the thing that makes Tweaks/Refine stale)

3. **Widget Factory & Panel Generation** - Auto-generate UI rows from detected key metadata
   - Addresses: SettingWidgetFactory (ARCHITECTURE), type-appropriate widgets (STACK: VariantType mapping)
   - Avoids: Desktop-breaking invalid values (PITFALLS #5) via range constraints

4. **Visual Identity** - Custom CSS, distinctive styling, light/dark/HC support
   - Addresses: Custom visual identity (FEATURES: differentiator), CSS via GResource (STACK)
   - Avoids: Specificity wars (PITFALLS #7), dark mode breakage (PITFALLS #6)

5. **Polish & Extras** - Search, changed-settings highlighting, animations, about dialog
   - Addresses: Search, changed highlighting, branding (FEATURES: differentiators)

6. **Flatpak Packaging & Flathub** - Manifest, metadata, permission tuning, submission
   - Addresses: Flatpak distribution (FEATURES: table stakes for reach)
   - Avoids: pkexec sandbox issue (PITFALLS #3), permission rejection (PITFALLS #6), metadata issues (PITFALLS #13)

**Phase ordering rationale:**
- Phase 1 first because app ID is permanent and affects every subsequent file.
- Phase 2 before 3 because the widget factory depends on the detection engine's output format.
- Phase 4 after functional panels are working so visual design can be tested against real content.
- Phase 6 last because Flatpak adds complexity (sandbox testing, permission negotiation) and the native build should be solid first.

**Research flags for phases:**
- Phase 2: Needs deeper research -- defining the "known exposed" blocklist requires auditing gnome-control-center source to see which keys it surfaces. This is a one-time research task.
- Phase 3: Standard patterns. The widget factory is well-understood from the GSettings introspection API.
- Phase 4: Moderate research -- CSS variables are documented, but achieving a distinctive look within libadwaita constraints requires design iteration, not library research.
- Phase 6: Needs deeper research -- Flatpak dconf access, schema enumeration inside sandbox, and Flathub permission negotiation all need hands-on testing. Study Refine's Flathub manifest closely.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against installed versions. All APIs confirmed in Valadoc. |
| Schema introspection | HIGH | `SettingsSchemaSource`, `SettingsSchema`, `SettingsSchemaKey` fully documented with exact Vala signatures. |
| Features | HIGH | Table stakes validated against competitor feature sets. Differentiators validated against technical capabilities. |
| Architecture | HIGH | Detection -> Filter -> Map -> Factory pattern is standard for this problem. Code examples verified against Valadoc. |
| CSS/visual design | HIGH | libadwaita CSS variables documented (60+ variables). CssProvider loading pattern confirmed. Media queries new in 1.8. |
| Flatpak dconf access | MEDIUM | Documented approach works for Refine. Need hands-on testing for schema enumeration inside sandbox. |
| Flatpak pkexec limitation | HIGH | Confirmed: privilege escalation impossible in Flatpak. Feature gating required. |
| Flathub submission | MEDIUM | Requirements documented, but reviewer behavior is variable. Study Refine's accepted manifest as precedent. |
| Pitfalls | HIGH | 17 pitfalls identified from official docs, issue trackers, and code review. |

## Gaps to Address

- **gnome-control-center audit:** Need to enumerate which GSettings keys GNOME Settings actually exposes in its GUI, to build the "known exposed" blocklist. This requires reading gnome-control-center source or comparing `gsettings list-recursively` output against the Settings UI.
- **Flatpak schema enumeration testing:** Does `SettingsSchemaSource.get_default()` inside a Flatpak sandbox return host schemas or runtime schemas? Need hands-on testing.
- **Flathub permission precedent:** Review Refine's accepted Flathub manifest in detail to understand what permissions were approved and any special exceptions granted.
- **Visual design direction:** The "distinctive look" differentiator is a design question, not a research question. Research confirms the technical capabilities (CSS variables, Snapshot API, animations) exist. The creative direction needs design exploration.
