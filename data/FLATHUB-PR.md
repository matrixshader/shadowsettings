# Flathub Submission PR

## Where to open
https://github.com/flathub/flathub/compare/master...Ehomey:flathub:add-shadow-settings

Click that link ^ and it opens the PR creation page. Paste the title and body below.

---

## PR Title
Add io.github.matrixshader.ShadowSettings

## PR Body

**Shadow Settings** discovers and surfaces hidden GNOME desktop settings that aren't exposed in the standard Settings app. It scans your system at runtime using `GSettingsSchemaSource` to find settings specific to your GNOME version and installed components — no hardcoded lists.

**App ID:** `io.github.matrixshader.ShadowSettings`
**License:** GPL-3.0-or-later
**Homepage:** https://matrixshader.com
**Repository:** https://github.com/matrixshader/shadowsettings

### Features
- Dynamically discovers hundreds of hidden GSettings keys at runtime
- Organizes settings into logical categories (Desktop, Appearance, Windows, Input, Power, Accessibility, Privacy)
- Full-text search across all discovered settings
- Reset any setting to its default value with visual change tracking
- Three distinctive Art Deco visual themes (Gotham Night, Gotham Day, Wayne Manor)
- Filters deprecated GTK2/GTK3 keys that have no effect in modern GNOME
- Logind lid-close settings on native installs (auto-hidden in Flatpak sandbox)

### Technical Details
- **Stack:** Vala + GTK4 + libadwaita + Meson
- **Runtime:** org.gnome.Platform 48
- **Binary size:** ~211KB (release build)
- **Startup:** <50ms, schema scan <11ms
- **Compatibility:** GNOME 43+ (GTK4 4.12+, libadwaita 1.4+)

### Checklist
- [x] App builds and runs
- [x] `flatpak-builder-lint manifest` passes clean
- [x] `flatpak-builder-lint appstream` passes (screenshot warning until image is live)
- [x] Metainfo has all required fields (id, license, name, summary, description, screenshots, releases, developer, content_rating)
- [x] Desktop file installed
- [x] App icon installed (scalable + symbolic SVGs)
- [x] GSettings schema installed with post-install compile

---

## BEFORE opening the PR:
1. Take a screenshot (see instructions below)
2. Push the screenshot to the repo
3. Update the commit hash in the manifest on your fork branch
4. Then open the PR using the link above
