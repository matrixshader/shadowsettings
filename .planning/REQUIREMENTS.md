# Shadow Settings — Requirements

## Vision
The best GNOME settings app. Dynamically detects hidden settings on any system, presents them in a visually distinctive UI, and distributes via Flathub to every GNOME desktop user.

## Functional Requirements

### FR-1: Dynamic Schema Detection Engine
The app MUST scan the system at runtime using `SettingsSchemaSource.list_schemas()` to discover all installed GSettings schemas. It MUST filter results to show only settings that exist on the system but are NOT exposed in GNOME Settings. All schema/key access MUST be null-guarded — if a schema or key doesn't exist, the setting silently doesn't appear (no crashes, no greyed-out toggles).

**Acceptance:** App launches on a clean Fedora, Ubuntu, and Debian install without crashes. Shows different settings on each based on what's actually hidden.

### FR-2: Known-Exposed Blocklist
The app MUST maintain a curated blocklist of GSettings keys that GNOME Settings already exposes in its GUI. This blocklist prevents Shadow Settings from duplicating what the system Settings app already shows. The blocklist MUST be versioned by GNOME version where possible.

**Acceptance:** No setting visible in Shadow Settings is also visible in GNOME Settings on the same system.

### FR-3: Widget Factory
The app MUST auto-generate appropriate UI widgets based on key metadata from `SettingsSchemaKey`:
- Boolean → `AdwSwitchRow`
- Enum / string with choices → `AdwComboRow`
- Integer with range → `AdwSpinRow`
- Double with range → `AdwSpinRow` (decimal)
- String → `AdwEntryRow` or `AdwComboRow` if choices exist
- String array → custom multi-select

Each widget MUST display the key's summary as title and description as subtitle (from schema XML). Each widget MUST enforce range constraints from the schema to prevent invalid values.

**Acceptance:** Every detected hidden setting renders with the correct widget type and cannot be set to an invalid value.

### FR-4: Category Organization
Detected settings MUST be organized into logical categories by user intent (Power, Windows, Desktop, Appearance, Input, etc.) — not by dconf path. Settings from schemas that span multiple categories (e.g., `org.gnome.desktop.interface` has fonts AND clock settings) MUST be split into appropriate categories.

**Acceptance:** User can find any setting in the category where they'd expect it.

### FR-5: Reset to Default
Every setting MUST have a way to reset to its default value. The app MUST visually indicate which settings have been modified from their defaults (changed-settings highlighting).

**Acceptance:** User can identify all changed settings at a glance and reset any individual setting to default.

### FR-6: Search
The app MUST provide search across all detected settings, indexing key summaries and descriptions. Search MUST filter results across all categories.

**Acceptance:** Typing "font" shows all font-related settings regardless of category.

### FR-7: Logind Configuration (Native Only)
For native (non-Flatpak) installs, the app MUST support lid close behavior configuration via logind.conf.d drop-in files, using pkexec for privilege escalation. This feature MUST be automatically disabled when running inside a Flatpak sandbox.

**Acceptance:** Lid close settings work on native install. Feature is hidden (not greyed out) in Flatpak.

### FR-8: About Dialog & Branding
The app MUST include an About dialog with:
- App name, version, description
- "Made by Matrix Shader" attribution
- Link to matrixshader.com
- Buy Me a Coffee / iknowkungfu tip jar link
- License info

**Acceptance:** About dialog shows all required branding elements with working links.

## Non-Functional Requirements

### NFR-1: Visual Identity
The app MUST have a distinctive visual identity using custom GTK4 CSS — not stock Adwaita. It MUST support light mode, dark mode, and high contrast mode. Custom styling MUST use libadwaita CSS variables for theme-adaptive colors. The visual design MUST make the app recognizable in screenshots.

**Acceptance:** The app is visually distinguishable from GNOME Settings, Tweaks, and Refine in a screenshot.

### NFR-2: Performance
The app MUST launch in under 500ms. Schema scanning MUST complete in under 100ms. Panel construction MUST be lazy (build widgets only when panel is first visited).

**Acceptance:** Cold start to interactive UI in under 500ms on a mid-range laptop.

### NFR-3: Binary Size
The compiled binary MUST be under 500KB. Native Vala compilation (no runtime interpreter).

**Acceptance:** `ls -la` shows binary under 500KB.

### NFR-4: GNOME Version Compatibility
The app MUST work on GNOME 43+ (GTK4 4.12+, libadwaita 1.4+). Schema detection handles version differences automatically.

**Acceptance:** App builds and runs on systems with GTK4 4.12+ and libadwaita 1.4+.

### NFR-5: Flatpak Distribution
The app MUST be packaged as a Flatpak and submitted to Flathub. The Flatpak build MUST handle GSettings access through the dconf portal. Features requiring pkexec MUST be automatically hidden.

**Acceptance:** App installs from Flathub and functions correctly (minus logind features).

### NFR-6: App Identity
App ID: to be finalized (e.g., `io.github.matrixshader.ShadowSettings` — must use `io.github.*` not `com.github.*` per Flathub requirements). All files (desktop, polkit, icons, metainfo) MUST use the final app ID consistently.

**Acceptance:** `flatpak-builder-lint` passes with no app ID warnings.

## Out of Scope
- Theme/icon pack switching (Gradience covers this)
- GNOME Extensions management (Extension Manager covers this)
- Raw dconf editing (dconf-editor covers this)
- Replacing GNOME Settings (complementing it)
- Non-GNOME desktops (KDE, XFCE, etc.)
- Windows/macOS
- Backup/restore all settings (defer to future)
- Autostart/services management
