# Shadow Settings

## What This Is

A GTK4/libadwaita settings app for GNOME that dynamically detects and surfaces every hidden, removed, or buried desktop setting on the user's system. Unlike GNOME Tweaks (stale GTK3), Refine (stock toggle lists), or dconf-editor (raw registry browser), Shadow Settings scans the system at runtime, shows only what's actually hidden on *your* distro and GNOME version, and presents it in a visually distinctive UI that people actually want to use. For every GNOME desktop Linux user across all distros.

## Core Value

Every hidden setting on your GNOME system, surfaced automatically with zero hardcoded lists — the app maintains itself by design.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Dynamic schema detection — query gsettings schemas at runtime, show only settings that exist but aren't exposed in GNOME Settings
- [ ] Graceful degradation — if a schema/key doesn't exist on this system, that setting silently doesn't appear (no crashes, no greyed-out toggles)
- [ ] Visually distinctive UI — custom CSS, not stock Adwaita toggle lists. This should look like a product, not a homework assignment.
- [ ] Power settings panel — lid close behavior (logind), suspend timeouts, power button action, screen dim/blank
- [ ] Window management panel — titlebar buttons, titlebar click actions, focus mode, center new windows, edge tiling
- [ ] Desktop panel — hot corners, animations, clock format/details, battery percentage, sound settings, lock screen
- [ ] Appearance panel — fonts (interface, document, monospace, titlebar), text rendering (scaling, hinting, antialiasing), cursor size
- [ ] Input panel — mouse acceleration/speed, touchpad tap-to-click, keyboard repeat settings, Caps Lock remapping
- [ ] About dialog with branding — "Made by Matrix Shader", matrixshader.com link, Buy Me a Coffee / iknowkungfu tip jar link
- [ ] Flatpak/Flathub distribution — packaged for easy install across all GNOME distros

### Out of Scope

- Bundling into Matrix Shader project — this is a standalone Linux tool, not part of the shader product
- GNOME Extensions management — separate concern, other tools handle this
- Theme/icon switching — Gradience and similar tools cover this
- Non-GNOME desktops — KDE, XFCE, etc. have their own settings. This is GNOME-specific.
- Windows/macOS — Linux only

## Context

- Existing prototype code at `~/shadow-settings/` (formerly `construct/`), built with Vala/GTK4/libadwaita/Meson
- Working binary exists — 5 panels (Power, Windows, Desktop, Appearance, Input) with functional gsettings bindings and logind helper
- Current UI is 100% stock Adwaita — zero custom CSS, no visual identity
- The prototype uses hardcoded settings panels — needs to be rearchitected for dynamic detection
- Subtitle was "Settings They Took" — being replaced with Shadow Settings branding
- App ID will change from `com.github.matrixshader.construct` to new Shadow Settings ID

### Competition Analysis

| App | Status | Gap |
|-----|--------|-----|
| GNOME Tweaks | GTK3, barely maintained, flat toggle list | Looks dated, static settings list |
| Refine | New libadwaita, TheEvilSkeleton | Still just stock toggle lists, no detection |
| dconf-editor | Raw key/value browser | Developer tool, not user-facing |
| KDE System Settings | 500+ settings, comprehensive | Overwhelming, inconsistent KCM quality |
| Elementary Switchboard | Best design, modular plugs | Dead with Elementary OS |

### Technical Opportunities

- GTK4 Snapshot API — programmatic drawing, blur effects, layered composition
- libadwaita spring animations — physics-based fluid motion
- GTK4 CSS — gradients, transitions, variables, pseudo-classes, hot-reloading
- Apps like Mission Center, Rnote, Elastic prove distinctive visual experiences are possible in libadwaita
- Nobody is using any of these capabilities in a settings app

## Constraints

- **Stack**: Vala + GTK4 + libadwaita + Meson — already committed, existing code uses this
- **Runtime detection**: Must query system at launch, not ship hardcoded schema lists
- **Root access**: Logind config requires pkexec for writes — polkit policy needed
- **Flatpak sandboxing**: Need to handle gsettings access and pkexec within Flatpak constraints
- **GNOME versions**: Should work across GNOME 43+ (GTK4 4.12+, libadwaita 1.4+)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Vala over Rust/Python | Existing codebase, compiles to native binary (50-200KB), <50ms startup, first-class GObject support | — Pending |
| Dynamic detection over hardcoded lists | Self-maintaining by design, works across distros/versions without per-release updates | — Pending |
| Standalone repo, not bundled with Matrix Shader | Different audience, different purpose — bundling forces the website to be a catch-all | — Pending |
| Flathub distribution | One package covers every distro, standard Linux app distribution | — Pending |
| Custom visual identity | Every settings app looks the same. Standing out visually is a competitive advantage and drives viral sharing (r/unixporn, Reddit, etc.) | — Pending |

---
*Last updated: 2026-03-06 after initialization*
