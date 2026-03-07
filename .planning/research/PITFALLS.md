# Domain Pitfalls

**Domain:** GNOME settings/tweaks app (GTK4/libadwaita/Vala) with Flatpak distribution
**Researched:** 2026-03-06

---

## Critical Pitfalls

Mistakes that cause rewrites, Flathub rejection, or broken functionality across distros.

---

### Pitfall 1: Flatpak Cannot Access Host GSettings By Default

**What goes wrong:** Shadow Settings needs to read and write host GNOME settings (`org.gnome.desktop.interface`, `org.gnome.mutter`, `org.gnome.desktop.wm.preferences`, etc.). Inside a Flatpak sandbox, GSettings defaults to a keyfile backend that stores settings in `~/.var/app/$APP/config/` -- completely isolated from the host dconf database. The app launches, creates its own isolated settings store, and every toggle shows defaults instead of the user's actual settings. Writes go nowhere the desktop can see.

**Why it happens:** Flatpak's sandbox model deliberately isolates apps from the host dconf database. The "DConf hole" (direct dconf access) must be explicitly punched through with finish-args permissions.

**Consequences:** App appears non-functional. Toggles don't reflect reality. Changes have zero effect on the desktop.

**Prevention:** Use the same "dconf hole" approach that Refine (page.tesk.Refine) uses in its Flatpak manifest:
```json
"finish-args": [
    "--talk-name=ca.desrt.dconf",
    "--filesystem=xdg-run/dconf",
    "--filesystem=xdg-config/dconf",
    "--env=GIO_EXTRA_MODULES=/app/lib/gio/modules/",
    "--filesystem=host-os:ro"
]
```
The `--talk-name=ca.desrt.dconf` allows D-Bus communication with the host dconf daemon. The filesystem permissions grant access to dconf's runtime and config directories. The `host-os:ro` gives read-only access to the host OS for schema discovery. The `GIO_EXTRA_MODULES` env ensures the dconf GIO module is loaded.

**Detection:** Test early in Flatpak: `flatpak run --command=gsettings $APP_ID list-schemas` -- if it shows nothing or different schemas than the host, the hole isn't punched.

**Confidence:** HIGH -- verified from Refine's actual Flathub manifest and Flatpak official documentation.

**Phase relevance:** Must be solved in the Flatpak packaging phase. Test dconf access before anything else.

---

### Pitfall 2: GSettings Schema Not Found Crashes the App

**What goes wrong:** The current prototype does `new GLib.Settings("org.gnome.mutter")` directly in the construct blocks. If that schema doesn't exist on the user's system (different GNOME version, different distro, not installed), GLib aborts with a fatal error. The app crashes on launch with "GLib-GIO-ERROR: Settings schema 'org.gnome.mutter' is not installed."

**Why it happens:** `GLib.Settings` constructor does not return null on missing schemas -- it calls `g_error()` which is `abort()`. This is by design in GLib. Every single `new GLib.Settings(...)` in the codebase is a potential crash site.

**Consequences:** App crashes on any GNOME distro that ships a different set of schemas. Fatal on the dynamic detection goal since the whole point is to handle schema availability gracefully.

**Prevention:** Always check schema existence before creating a Settings object:
```vala
var source = GLib.SettingsSchemaSource.get_default();
var schema = source.lookup("org.gnome.mutter", true);
if (schema != null) {
    var settings = new GLib.Settings("org.gnome.mutter");
    // Safe to use
}
```
Also check individual keys exist before accessing them:
```vala
if (schema.has_key("center-new-windows")) {
    // Safe to bind/get/set
}
```

**Detection:** Run on a minimal GNOME install (like GNOME on Arch with only core packages) or a distro with older GNOME. If any panel crashes the app, this pitfall is active. The current code has at least 8 `new GLib.Settings(...)` calls with zero safety checks.

**Confidence:** HIGH -- verified from GLib documentation and real crash reports in the wild (NixOS, Arch forums).

**Phase relevance:** Must be the FIRST thing addressed when rearchitecting for dynamic detection. The dynamic detection system IS the fix for this pitfall.

---

### Pitfall 3: pkexec Does Not Work Inside Flatpak Sandbox

**What goes wrong:** The logind-helper.vala uses `pkexec bash -c "mkdir -p ... && printf ... > ..."` to write to `/etc/systemd/logind.conf.d/`. Inside a Flatpak sandbox, pkexec is unavailable -- SUID binaries cannot run inside the sandbox. The power panel's lid-close settings silently fail or throw errors.

**Why it happens:** Flatpak strips SUID bits and blocks privilege escalation binaries by design. pkexec, sudo, su -- none of them work inside the sandbox.

**Consequences:** All logind/systemd configuration features are completely broken in the Flatpak build. Since this is the primary distribution method, most users get a broken power panel.

**Prevention:** Two approaches:
1. **D-Bus system bus approach:** Use `--system-talk-name=org.freedesktop.login1` in finish-args and communicate with logind over D-Bus. For writing config files, ship a small helper binary installed on the host (outside the sandbox) that the Flatpak app talks to via D-Bus. This is how Fedora Media Writer and similar apps handle privilege escalation.
2. **Host command execution:** Use `--talk-name=org.freedesktop.Flatpak` to run commands on the host via `flatpak-spawn --host pkexec ...`. However, this permission is heavily scrutinized by Flathub reviewers and may be rejected. It effectively breaks the sandbox.

The D-Bus helper approach is preferred. Ship a systemd service or polkit helper that runs outside the sandbox and accepts D-Bus method calls for the specific config writes needed.

**Detection:** Build the Flatpak and try changing lid-close behavior. If nothing happens (no polkit dialog, no config written), this pitfall is active.

**Confidence:** HIGH -- Flatpak documentation explicitly states SUID binaries do not work in the sandbox.

**Phase relevance:** Must be redesigned before Flatpak packaging. The current pkexec+bash approach needs complete replacement.

---

### Pitfall 4: Restarting systemd-logind Kills All User Sessions

**What goes wrong:** After writing logind.conf changes, the app might try to restart `systemd-logind` to apply them. Running `systemctl restart systemd-logind` destroys all active login sessions -- the user gets logged out, their graphical session dies, and unsaved work is lost.

**Why it happens:** logind tracks all user sessions. Restarting the service drops that tracking. The current code has commented-out restart attempts (lines 78-88 in logind-helper.vala), showing the developer already struggled with this.

**Consequences:** User loses their entire desktop session. Data loss. App gets a 1-star review and an uninstall.

**Prevention:** The current code actually has the right instinct in its comments: "logind re-reads its config files on its own for some keys. For lid switch, it reads config on each lid event." This is correct -- HandleLidSwitch is read at event time, not at config load time. Do NOT restart logind. Simply write the drop-in file and inform the user that changes take effect on the next lid close / power button press.

For keys that genuinely need a logind restart (rare), display a clear warning dialog: "This change requires a logout to take effect" and let the user decide.

**Detection:** If the code ever calls `systemctl restart systemd-logind` without explicit user consent and session-saving, this pitfall is active.

**Confidence:** HIGH -- confirmed by systemd issue tracker and Ubuntu bug reports. Sessions are irrecoverably lost.

**Phase relevance:** Already partially handled in current code (restart is commented out). Formalize the "changes take effect on next event" messaging in the UI phase.

---

### Pitfall 5: App ID Must Be Correct From Day One

**What goes wrong:** The current app ID is `com.github.matrixshader.construct`. This needs to change to the new Shadow Settings ID. Changing a Flatpak app ID after Flathub publication is extremely painful -- users lose their settings, the rename requires Flathub reviewer approval, and Flathub only accepts renames that change the domain portion. Additionally, `com.github.*` is reserved for GitHub's own projects; apps hosted on GitHub must use `io.github.*`.

**Why it happens:** Flatpak app IDs are permanent identifiers tied to settings storage paths, D-Bus names, file paths, polkit actions, desktop files, and icons. Everything keys off the app ID.

**Consequences:** Either stuck with a wrong/rejected ID, or forced through a painful migration that loses early users' settings.

**Prevention:** Choose the final app ID NOW before any Flathub submission. The correct format for a GitHub-hosted project is:
- `io.github.matrixshader.ShadowSettings` (if repo is on github.com/matrixshader)
- Or acquire a domain and use `com.matrixshader.ShadowSettings` (if matrixshader.com proves ownership)

Since matrixshader.com exists, `com.matrixshader.ShadowSettings` is likely the right choice. Update ALL references: meson.build, application.vala, .desktop file, polkit policy, icon paths, metainfo.

**Detection:** If any file references `com.github.matrixshader.construct`, this pitfall is still active.

**Confidence:** HIGH -- Flathub requirements documentation is explicit about `com.github.*` being reserved.

**Phase relevance:** Must be resolved in the very first phase, before any packaging work. Rename everything up front.

---

### Pitfall 6: Flathub Submission Rejection for Permission Overreach

**What goes wrong:** Shadow Settings inherently needs broad permissions (dconf access, host-os filesystem, potentially system D-Bus). The Flathub linter flags many of these as errors. `--talk-name=org.freedesktop.Flatpak` (which allows running host commands) is restricted and requires a case-by-case exception. Submissions with excessive permissions get rejected or delayed in review.

**Why it happens:** Flathub enforces minimal permissions. A settings app is architecturally at odds with sandboxing -- its entire purpose is to modify system state.

**Consequences:** Submission rejected. Weeks of back-and-forth with reviewers. App stuck in limbo.

**Prevention:**
1. Study what Refine (page.tesk.Refine) got approved with -- it uses `--talk-name=ca.desrt.dconf`, `--filesystem=xdg-run/dconf`, `--filesystem=xdg-config/dconf`, `--filesystem=host-os:ro`, and `--talk-name=org.freedesktop.Flatpak`. If Refine got approved with these permissions, Shadow Settings can too with proper justification.
2. Run `flatpak-builder-lint` against your manifest BEFORE submission. Fix all errors. Document justifications for warnings.
3. Request exceptions proactively by submitting PRs to the flatpak-builder-lint exceptions file.
4. Minimize permissions to exactly what's needed. Don't request `--filesystem=home` when `--filesystem=host-os:ro` suffices.

**Detection:** Run `flatpak-builder-lint` on your manifest. Any errors = guaranteed rejection.

**Confidence:** HIGH -- Flathub linter docs enumerate exact rules.

**Phase relevance:** Flatpak packaging phase. Run the linter early and often.

---

## Moderate Pitfalls

Issues that cause bugs, poor UX, or compatibility problems but don't require full rewrites.

---

### Pitfall 7: GTK4 CSS Custom Styling Breaks Across Dark/Light Mode

**What goes wrong:** Custom CSS with hardcoded colors looks great in light mode, then becomes unreadable or ugly in dark mode (or vice versa). Custom backgrounds disappear, text becomes invisible against same-colored backgrounds, borders vanish.

**Prevention:**
- Use libadwaita CSS variables (`--accent-bg-color`, `--window-bg-color`, `--card-bg-color`, etc.) instead of hardcoded hex colors. These automatically adapt to light/dark/high-contrast modes.
- Use media queries for mode-specific overrides: `@media (prefers-color-scheme: dark) { ... }`
- Test in all three modes: light, dark, high-contrast. libadwaita provides `AdwStyleManager` for programmatic detection.
- Load CSS via `AdwApplication` resource loading (`style.css` in GResource), which handles priority correctly.

**Detection:** Toggle dark mode with `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` and visually inspect every panel.

**Confidence:** HIGH -- documented in libadwaita Styles & Appearance docs.

**Phase relevance:** UI/visual redesign phase. Must be validated before shipping custom CSS.

---

### Pitfall 8: GtkStyleContext Deprecation in GTK 4.10+

**What goes wrong:** `gtk_style_context_add_provider()` and most `GtkStyleContext` methods are deprecated since GTK 4.10. Code using these methods generates deprecation warnings and may break in future GTK versions. The non-deprecated alternatives are `gtk_style_context_add_provider_for_display()` (display-level) and `Widget.add_css_class()` (widget-level).

**Prevention:**
- For app-wide CSS, use `gtk_style_context_add_provider_for_display()` with `GTK_STYLE_PROVIDER_PRIORITY_APPLICATION`.
- For per-widget styling, use `widget.add_css_class("my-class")` and define `.my-class { ... }` in CSS.
- Use `gtk_css_provider_load_from_string()` instead of the deprecated `load_from_data()` (deprecated since 4.12).
- In Vala: `Gtk.StyleContext.add_provider_for_display(display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)`.

**Detection:** Compile with `-Wdeprecated` and check for GtkStyleContext warnings.

**Confidence:** HIGH -- GTK4 deprecation notices in official docs.

**Phase relevance:** UI/visual redesign phase when adding custom CSS.

---

### Pitfall 9: GNOME Schema Keys Change Between Versions

**What goes wrong:** Settings keys get added, removed, or renamed across GNOME versions:
- GNOME 45: Window shading removed, auto-start from media disabled by default
- GNOME 46: `show-status-shapes` key removed from `org.gnome.desktop.a11y.interface`, significant schema file reorganization
- GNOME 47: Break reminder schema added
- GNOME 48: Screen limits schema introduced, default font changed from Cantarell to Adwaita

Hardcoding key names that only exist in certain versions crashes the app on other versions (see Pitfall 2).

**Prevention:** The dynamic detection system handles this by design -- enumerate available schemas and keys at runtime. But be aware of specific changes:
- Never assume `org.gnome.mutter` has the same keys across GNOME 43-48.
- Test on both the oldest supported GNOME (43) and the latest (48).
- For the "hidden settings" detection (comparing GNOME Settings UI vs available schemas), the set of "exposed" settings also changes per version.

**Detection:** Test on multiple GNOME versions. Fedora ships latest GNOME quickly; Ubuntu LTS ships older. If any panel crashes or shows wrong data on either, this pitfall is active.

**Confidence:** MEDIUM -- specific key changes verified from gsettings-desktop-schemas NEWS file, but full enumeration across all schemas is incomplete.

**Phase relevance:** Dynamic detection phase. The detection system must be resilient to schema changes by design.

---

### Pitfall 10: logind Drop-In File Path Confusion

**What goes wrong:** There are two different drop-in mechanisms that look similar but are completely different:
- `/etc/systemd/logind.conf.d/*.conf` -- configuration drop-ins (what you want)
- `/etc/systemd/system/systemd-logind.service.d/*.conf` -- service unit drop-ins (NOT what you want)

Using `systemctl edit systemd-logind` creates a service drop-in, which ignores `[Login]` section content with "Unknown section 'Login'" warnings. The settings appear saved but are silently ignored.

**Prevention:** The current code correctly uses `/etc/systemd/logind.conf.d/99-construct.conf` (configuration drop-in path). Keep it that way. Name the file with a high number prefix (90-99 range) so local drop-ins take priority over vendor ones.

After renaming the app, update the drop-in filename to match: `99-shadow-settings.conf`.

**Detection:** Write a config change, then run `systemd-analyze cat-config systemd/logind.conf` to verify the drop-in is being read. If your `[Login]` section doesn't appear, wrong path.

**Confidence:** HIGH -- confirmed by Arch Linux forums and Fedora bug reports.

**Phase relevance:** Already correct in current code. Just update the filename during rename.

---

### Pitfall 11: libadwaita Widget Deprecations Across Versions

**What goes wrong:** libadwaita 1.4 deprecated `AdwLeaflet`, `AdwFlap`, `AdwSqueezer`, and `AdwViewSwitcherTitle` in favor of `AdwNavigationSplitView` and `AdwBreakpoint`. libadwaita 1.5 deprecated old dialog/preferences-window APIs. libadwaita 1.6 deprecated `.opaque` button style class. Using deprecated widgets means the app will break when these are removed.

**Prevention:**
- The current prototype already uses `AdwNavigationSplitView` and `AdwPreferencesPage` (good).
- When targeting libadwaita >= 1.4 (which is already the constraint in meson.build), avoid all deprecated 1.4 widgets.
- For dialogs (like About, preferences sub-windows), use the new `AdwDialog` API from 1.5+ instead of `AdwPreferencesWindow` for sub-pages.
- Check valadoc.org/libadwaita-1 for current deprecation status of any widget before using it.

**Detection:** Compile and check for deprecation warnings. If targeting `libadwaita-1 >= 1.4`, any use of AdwLeaflet/AdwFlap/AdwSqueezer is a warning sign.

**Confidence:** HIGH -- confirmed from Alice's blog (libadwaita maintainer) release announcements.

**Phase relevance:** Already partially handled. Revisit during any UI additions.

---

### Pitfall 12: Accent Color Override Does Not Update StyleManager API

**What goes wrong:** If the app overrides accent colors via CSS variables (`--accent-bg-color`, etc.) for custom styling, `AdwStyleManager` API calls will still return the system's accent color, not the app's override. Code that reads accent color from StyleManager and uses it for programmatic drawing will be out of sync with the CSS-applied color.

**Prevention:** When overriding accent colors:
- Also set `--accent-color` manually (the non-bg variant).
- Adjust foreground colors if the custom accent is too bright/dark for text contrast.
- For programmatic drawing, read colors from CSS via `gtk_style_context_lookup_color()` or `gtk_style_context_get_color()`, not from `AdwStyleManager`.

**Detection:** Override an accent color and then check if any programmatic drawing uses mismatched colors.

**Confidence:** HIGH -- explicitly documented in libadwaita Styles & Appearance page.

**Phase relevance:** UI/visual redesign phase, only if overriding accent colors.

---

## Minor Pitfalls

Issues that cause minor annoyances or technical debt.

---

### Pitfall 13: Missing Metainfo / Desktop File Validation

**What goes wrong:** Flathub requires metainfo files that pass `appstreamcli validate` and desktop files that pass `desktop-file-validate`. Missing screenshots, missing OARS ratings, wrong content types, or malformed XML cause linter failures.

**Prevention:**
- Include at least one screenshot in metainfo (with caption text).
- Include OARS content rating (even if all-ages).
- Validate early: `appstreamcli validate data/com.matrixshader.ShadowSettings.metainfo.xml`
- Desktop file must have `Categories=` with valid FreeDesktop categories.
- Icon must be SVG or >= 256x256 PNG, installed at the correct path.

**Detection:** Run `flatpak-builder-lint` and `appstreamcli validate` locally before submission.

**Confidence:** HIGH -- Flathub requirements page.

**Phase relevance:** Flatpak packaging phase.

---

### Pitfall 14: Flatpak AI-Generated Code Prohibition

**What goes wrong:** Flathub's requirements state: "Submission pull requests must not be generated, opened, or automated using AI tools or agents. Submissions or changes where most of the code is written by or using AI without any meaningful human input, review, justification or moderation of the code are not allowed."

**Prevention:** The Flatpak manifest, metainfo, and packaging files should be human-written or at minimum human-reviewed with meaningful modifications. The application code itself is not the issue -- the packaging submission PR is. Do not auto-generate the Flathub submission PR. Write it manually, review every line, and be prepared to explain every permission choice.

**Detection:** Ensure the Flathub submission PR is authored and reviewed by a human. Add meaningful commit messages explaining packaging decisions.

**Confidence:** HIGH -- explicitly stated in Flathub requirements.

**Phase relevance:** Flathub submission phase.

---

### Pitfall 15: Polkit Policy File Must Match New App ID

**What goes wrong:** The current polkit policy is `com.github.matrixshader.construct.policy` with action ID `com.github.matrixshader.construct.write-system-config`. After renaming, these must all match the new app ID. Mismatched polkit action IDs cause "action not registered" errors and privilege escalation silently fails.

**Prevention:** When renaming the app ID, update all of these in lockstep:
- `polkit/*.policy` filename
- `<action id="...">` inside the policy XML
- `meson.build` install_data path for polkit
- Any code referencing the polkit action ID

**Detection:** After rename, run `pkaction --verbose --action-id com.matrixshader.ShadowSettings.write-system-config` to verify the action is registered.

**Confidence:** HIGH -- standard polkit behavior.

**Phase relevance:** App rename phase (first phase).

---

### Pitfall 16: Flatpak Runtime Version Mismatch

**What goes wrong:** Building against `org.gnome.Platform//47` but deploying on a system with GNOME 43 means the app works in the sandbox (which bundles the runtime) but the host's gsettings schemas may not have keys the app expects. Conversely, building against an old runtime means missing newer libadwaita features.

**Prevention:**
- Use `org.gnome.Platform//46` or `//47` as runtime (matches the libadwaita >= 1.4 constraint).
- Remember: the Flatpak runtime provides the libraries the app links against, but the HOST provides the gsettings schemas the app reads. These can be different versions.
- The dynamic detection system mitigates this by checking key existence before access.

**Detection:** Test on a system running an older GNOME version than the Flatpak runtime targets.

**Confidence:** MEDIUM -- understood conceptually, specific version combinations not tested.

**Phase relevance:** Flatpak packaging phase.

---

### Pitfall 17: Button Layout String Parsing Fragility

**What goes wrong:** The current `update_button_layout()` in windows.vala constructs button layout strings like `"appmenu:minimize,maximize,close"`. Different GNOME versions and distros have different default layouts (e.g., Ubuntu puts close on the left: `"close,minimize,maximize:"`). Parsing and reconstructing these strings can lose custom arrangements or produce invalid layouts.

**Prevention:**
- Parse the existing layout into left/right lists, modify only what the user changed, and reconstruct.
- Handle the Ubuntu-style left-side close button correctly.
- Validate output format before writing (must have exactly one colon separator).

**Detection:** Set a non-standard button layout (`close:minimize,maximize`) and toggle minimize off/on. If the layout gets corrupted, this pitfall is active.

**Confidence:** MEDIUM -- based on code review of current implementation.

**Phase relevance:** Panel refinement phase.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| App rename / ID change | Pitfall 5 (wrong app ID), Pitfall 15 (polkit mismatch) | Choose final ID first, update everything in lockstep |
| Dynamic detection system | Pitfall 2 (schema crash), Pitfall 9 (version differences) | Schema/key existence checks before every GSettings access |
| UI/visual redesign | Pitfall 7 (dark mode), Pitfall 8 (deprecated CSS API), Pitfall 12 (accent colors) | Use CSS variables, test all three color schemes |
| Flatpak packaging | Pitfall 1 (dconf access), Pitfall 3 (pkexec broken), Pitfall 6 (linter rejection) | Study Refine's manifest, replace pkexec with D-Bus helper |
| Flathub submission | Pitfall 6 (permission review), Pitfall 13 (metadata), Pitfall 14 (AI prohibition) | Run linter, validate metainfo, human-author the PR |
| Power panel (logind) | Pitfall 4 (logind restart kills sessions), Pitfall 10 (drop-in path confusion) | Never restart logind, use correct config drop-in path |

---

## Sources

- [Flatpak Sandbox Permissions Documentation](https://docs.flatpak.org/en/latest/sandbox-permissions.html)
- [Flathub App Requirements](https://docs.flathub.org/docs/for-app-authors/requirements)
- [Flathub Builder Lint Documentation](https://docs.flathub.org/docs/for-app-authors/linter)
- [Flathub App Review Wiki](https://github.com/flathub/flathub/wiki/App-Review)
- [Settings in a Sandbox World (Matthias Clasen)](https://blogs.gnome.org/mclasen/2019/07/12/settings-in-a-sandbox-world/)
- [Refine Flathub Manifest (page.tesk.Refine)](https://github.com/flathub/page.tesk.Refine/blob/master/page.tesk.Refine.json)
- [gsettings-desktop-schemas NEWS](https://github.com/GNOME/gsettings-desktop-schemas/blob/master/NEWS)
- [libadwaita Styles & Appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html)
- [Libadwaita 1.4 Release (Alice)](https://blogs.gnome.org/alicem/2023/09/15/libadwaita-1-4/)
- [Libadwaita 1.5 Release (Alice)](https://blogs.gnome.org/alicem/2024/03/15/libadwaita-1-5/)
- [Libadwaita 1.6 Release (Alice)](https://blogs.gnome.org/alicem/2024/09/13/libadwaita-1-6/)
- [GTK4 GtkStyleContext Deprecation Issue](https://gitlab.gnome.org/GNOME/gtk/-/issues/5342)
- [GLib.SettingsSchemaSource (Valadoc)](https://valadoc.org/gio-2.0/GLib.SettingsSchemaSource.html)
- [logind.conf Manual](https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html)
- [systemd-logind Session Loss Bug](https://bugs.launchpad.net/bugs/1944711)
- [Flatpak PolicyKit Support Request](https://github.com/flatpak/flatpak/issues/4789)
- [org.freedesktop.login1 D-Bus Interface](https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html)
- [Overriding logind.conf (Arch Forums)](https://bbs.archlinux.org/viewtopic.php?id=285193)
- [Fedora logind Restart Bug](https://discussion.fedoraproject.org/t/systemd-logind-requires-restart-after-reboot-to-recognize-login-section-drop-in-is-not-invalid/131463)
