# Phase 4: Visual Identity & Design - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Transform Shadow Settings from stock Adwaita into a visually distinctive, recognizable app with custom CSS, animations, branding, and an in-app theme system. The app should be visually distinguishable from GNOME Settings, Tweaks, and Refine in a screenshot.

</domain>

<decisions>
## Implementation Decisions

### Theme System
- Three visual themes: Dark (Gotham night), Light (Gotham day), Warm (Wayne Manor)
- All three share the same Art Deco / Batman: The Animated Series DNA — same visual language, different "exposure"
- Default auto-selects based on system `prefer-dark` / `prefer-light` — dark system gets Gotham night, light system gets Gotham day
- User can override to any of the three via in-app setting

### Theme Picker & App Preferences
- First sidebar item: a "Shadow Settings" or "Preferences" entry at the top of the sidebar
- Contains: theme picker (3 themes) and animation toggle
- The app practices what it preaches — its own settings live in its own UI

### Color Identity — Art Deco / Batman: The Animated Series
- Visual reference: Batman: The Animated Series (1992) — Art Deco Gotham, noir aesthetic, dramatic contrast
- NOT "vibe code purple" — warm, grounded palette
- Dark theme (Gotham Night): deep blacks, amber/gold primary accents (like Gotham streetlights), deep crimson/red for alerts and reset actions
- Light theme (Gotham Day): warm grays, muted gold accents — daylight version of the same city
- Warm theme (Wayne Manor): deep browns, warm amber — cozy, rich, premium feel
- All themes use libadwaita CSS variables for theme-adaptive colors

### Batcomputer Aesthetic — Claude's Discretion on Depth
- Direction: the app should feel like accessing hidden system controls from the Batcave
- Claude decides how deep to commit based on what looks coolest: scan line textures, monospace headers, green phosphor glow options, wireframe dividers, HUD-style category headers — all on the table
- The line between "subtle nods" and "full commitment" is Claude's call — optimize for cool factor

### Layout & Spacing
- Row density: Claude's discretion — pick what looks best with Art Deco direction
- Group separation: bold section headers / Art Deco dividers between groups — NOT cards, NOT minimal spacing
- Sidebar: subtle gradient or Art Deco pinstripe divider between sidebar and content area — not unified, not fully split-tone

### Animations & Transitions
- Cinematic level — spring animations, not minimal
- Page transitions: crossfade between categories (already set up)
- Row entrance: staggered cascade — rows appear one by one, top to bottom, with slight delay. Like credits rolling.
- Modified-setting highlight: animated amber glow/pulse when a setting changes from default, settles into subtle persistent highlight
- Reset button: animated reveal (spring in)
- Sidebar selection: pulse effect
- Reduce motion: available as in-app setting (alongside theme picker), defaults to system's gtk-enable-animations. When active, all animations become instant.

### About Dialog (per FR-8)
- App name, version, description
- "Made by Matrix Shader" attribution
- Link to matrixshader.com
- Buy Me a Coffee / iknowkungfu tip jar link
- License info

### App Icon
- Claude's discretion on concept — Batcomputer/radar/schematic direction is on the table alongside gear-with-shadow
- Must read well at 128px and 16px
- Should reflect the Art Deco / Batcomputer aesthetic
- SVG format

</decisions>

<specifics>
## Specific Ideas

- "Batman: The Animated Series" (1992) is THE visual reference — Art Deco Gotham, not generic dark mode
- "Batcomputer" aesthetic for the hidden-controls feel — like you're accessing what the system doesn't want you to see
- Amber/gold for primary accents (Gotham streetlights), crimson for alerts/reset
- Three themes are three "exposures" of the same city — night, day, interior
- The dark/shadow theme is the signature — what people will screenshot and share

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Gtk.Stack` with `CROSSFADE` transition already in window.vala — page transitions are wired
- `setting-modified` CSS class already applied by WidgetFactory in Phase 3 — ready for styling
- `AdwNavigationSplitView` for sidebar/content split — standard libadwaita pattern

### Established Patterns
- `Adw.Application` with GResource support — CSS can be loaded at APPLICATION priority
- libadwaita 1.8 CSS media queries for `prefers-color-scheme` — single stylesheet handles light/dark/HC
- No existing CSS files — blank canvas, no conflicts

### Integration Points
- `application.vala` — CSS provider loading point (activate or startup)
- `window.vala` construct block — sidebar first-item for preferences
- `meson.build` — GResource compilation for CSS + icon SVG
- `data/icons/hicolor/` — existing icon directory structure

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-visual-identity-design*
*Context gathered: 2026-03-08*
