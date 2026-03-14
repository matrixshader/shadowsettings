---
phase: 05-search-polish-distribution
verified: 2026-03-14T00:00:00Z
status: gaps_found
score: 11/14 must-haves verified
re_verification: false
gaps:
  - truth: "flatpak-builder-lint passes clean (NFR-5 acceptance criterion)"
    status: failed
    reason: "No lint run documented. flatpak-builder-lint may not be installed but the ROADMAP success criterion explicitly requires it to pass."
    artifacts:
      - path: "io.github.matrixshader.ShadowSettings.json"
        issue: "Manifest exists and is structurally correct, but lint has not been run — documented as human TODO"
    missing:
      - "Run flatpak-builder-lint manifest io.github.matrixshader.ShadowSettings.json"
      - "Run flatpak-builder-lint appstream data/io.github.matrixshader.ShadowSettings.metainfo.xml"
  - truth: "GitHub repo is created and code is pushed to main (ROADMAP success criterion)"
    status: failed
    reason: "No git remote is configured. Repo matrixshader/shadow-settings has not been created or pushed. This is a user-action gap documented in the plan but unresolved."
    artifacts:
      - path: "git remote"
        issue: "No remote configured — git remote -v returns empty"
    missing:
      - "Create public GitHub repo matrixshader/shadow-settings at github.com/new"
      - "git remote add origin https://github.com/matrixshader/shadow-settings.git && git push -u origin main"
  - truth: "Flathub submission PR is opened (ROADMAP success criterion)"
    status: failed
    reason: "Flathub submission PR has not been opened. This requires the GitHub repo to exist first (gap above) and is an explicit human-only task. The ROADMAP lists it as a success criterion."
    artifacts: []
    missing:
      - "Take screenshot and save to data/screenshots/main.png (metainfo image URL will 404 without it)"
      - "Fork flathub/flathub, create branch, add manifest, open PR manually"
human_verification:
  - test: "Launch app and activate search"
    expected: "Search button (magnifying glass) visible in sidebar header; clicking it or pressing Ctrl+F slides down the SearchBar with a SearchEntry"
    why_human: "GTK4 widget visibility and animation cannot be verified programmatically"
  - test: "Type 'font' into search"
    expected: "Results from multiple categories (Appearance, Windows) appear, each in a PreferencesGroup with the category name as header"
    why_human: "Requires runtime schema enumeration against the live system"
  - test: "Type 'menubar' or 'tearoff' into search"
    expected: "Zero results — deprecated keys like menubar-accel and menus-have-tearoff are filtered out"
    why_human: "Depends on which schemas are installed on the running system"
  - test: "Press Escape while search is active"
    expected: "SearchBar collapses, sidebar subtitle restores to 'N hidden settings found', previous panel reappears"
    why_human: "Signal flow and UI state restoration requires runtime observation"
  - test: "Type 'xyzxyz' (no match)"
    expected: "Adw.StatusPage 'No Results' empty state shown with edit-find-symbolic icon"
    why_human: "Empty-state rendering requires GTK4 runtime"
  - test: "Launch time measurement"
    expected: "Cold start to interactive UI in under 500ms; schema scan logs under 100ms"
    why_human: "Timing requires running on the target hardware; no instrumentation log added to discover_all()"
---

# Phase 5: Search, Polish & Distribution — Verification Report

**Phase Goal:** Add search, final polish, Flatpak packaging, and Flathub submission.
**Verified:** 2026-03-14
**Status:** gaps_found — 11/14 must-haves fully verified; 3 gaps (lint, GitHub push, Flathub PR)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|---------|
| 1  | Deprecated GTK2/GTK3 keys are filtered out and never shown to the user | VERIFIED | `DEPRECATED_KEYS` const (14 entries) at schema-scanner.vala:24-39; `is_deprecated_key()` at line 152; filter call at line 86 inside `discover_all()` before curated lookup |
| 2  | User can activate search by clicking the search button or typing anywhere in window | VERIFIED | `search_btn` ToggleButton with BIDIRECTIONAL bind to `search_bar.search-mode-enabled` at window.vala:183-188; `set_key_capture_widget(this)` at line 80 enables type-anywhere capture |
| 3  | User can type a query and see matching settings from all categories | VERIFIED | `perform_search()` at window.vala:326 iterates `categories` array; `WidgetFactory.create_row(def, scanner)` called at line 349 for each match |
| 4  | Search results are grouped by category with category name headers | VERIFIED | `Adw.PreferencesGroup` per category with `group.title = cat.title` at window.vala:341-343 inside `perform_search()` |
| 5  | Empty search query returns to the previously viewed panel | VERIFIED | `perform_search()` early-return at line 327-332 restores `content_stack.visible_child_name = last_panel_id` and original subtitle |
| 6  | No-results state shows a clear 'No Results' message | VERIFIED | `Adw.StatusPage` with `title = "No Results"` and `description = "No settings match ..."` at window.vala:373-376 |
| 7  | Pressing Escape dismisses search and returns to previous panel | VERIFIED | `search_entry.stop_search.connect(() => { search_bar.search_mode_enabled = false; })` at line 85; `search_bar.notify["search-mode-enabled"]` handler at line 89 restores panel and subtitle |
| 8  | Schema scan completes under 100ms (NFR-2 performance budget) | UNCERTAIN | No timing instrumentation added to `discover_all()`. No GLib.message timing call. Claimed in SUMMARY but not measurable from code. Needs human timing test. |
| 9  | Flatpak manifest exists with correct app ID, runtime, and permissions | VERIFIED | `io.github.matrixshader.ShadowSettings.json` exists; app-id `io.github.matrixshader.ShadowSettings`, runtime `org.gnome.Platform//48`, `--buildtype=release`; NO `--filesystem=home`, NO `--socket=session-bus` |
| 10 | Metainfo XML exists with all Flathub-required fields | VERIFIED | `data/io.github.matrixshader.ShadowSettings.metainfo.xml` exists; has `developer id="io.github.matrixshader"` with name child, `content_rating type="oars-1.1"`, `releases`, `screenshots`, `launchable` |
| 11 | Metainfo is installed to correct path via meson | VERIFIED | `meson.build` line 79-82: `install_data('data/...metainfo.xml', install_dir: get_option('datadir') / 'metainfo')` |
| 12 | Release build binary is under 500KB (NFR-3) | VERIFIED | `builddir-rel/shadow-settings` is 216,336 bytes (211KB) — confirmed by `ls -la` |
| 13 | App compiles cleanly against GTK4 4.12+ and libadwaita 1.4+ (NFR-4) | VERIFIED | `meson.build` lines 9-10 declare `dependency('gtk4', version: '>= 4.12')` and `dependency('libadwaita-1', version: '>= 1.4')`; build binary exists |
| 14 | README has install instructions for both native and Flatpak | VERIFIED | `README.md` contains `flatpak install flathub io.github.matrixshader.ShadowSettings`, Fedora/Ubuntu dnf/apt commands, `meson setup builddir`, and system-wide install commands |

**Score:** 11/14 truths verified (2 uncertain/human-needed, 3 failed per ROADMAP success criteria)

---

## Required Artifacts

### 05-01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/core/schema-scanner.vala` | DEPRECATED_KEYS filter in discover_all() | VERIFIED | 14-entry const array at line 24; `is_deprecated_key()` helper at line 152; filter applied at line 86 |
| `src/window.vala` | Search UI with SearchBar, SearchEntry, and filter loop | VERIFIED | All fields declared (lines 13-17); SearchBar/SearchEntry constructed (lines 73-80); `perform_search()` at line 326 |

### 05-02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `io.github.matrixshader.ShadowSettings.json` | Flatpak manifest | VERIFIED | Exists at repo root; contains `org.gnome.Platform`, `--buildtype=release`, correct finish-args |
| `data/io.github.matrixshader.ShadowSettings.metainfo.xml` | Appstream metainfo | VERIFIED | Exists; contains `desktop-application` component type, all Flathub-required fields |
| `meson.build` | Metainfo install rule | VERIFIED | `install_data` for metainfo targeting `share/metainfo/` at lines 79-82 |
| `README.md` | Install instructions | VERIFIED | Exists; contains `shadow-settings` in Flatpak install command and build instructions |

---

## Key Link Verification

### 05-01 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `src/window.vala` | `src/core/schema-scanner.vala` | `scanner.discover_all()` returns filtered results | WIRED | `scanner.discover_all(curated_overrides)` at window.vala:45; DEPRECATED_KEYS filter applied inside discover_all() at scanner:86 |
| `src/window.vala (perform_search)` | `src/core/widget-factory.vala` | `WidgetFactory.create_row(def, scanner)` for each match | WIRED | `WidgetFactory.create_row(def, scanner)` called at window.vala:349 inside `perform_search()` loop |
| `src/window.vala (search_bar)` | `src/window.vala (perform_search)` | `search_entry.search_changed` triggers `perform_search()` | WIRED | `search_entry.search_changed.connect(() => { perform_search(search_entry.text); })` at window.vala:82-84 |

### 05-02 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `io.github.matrixshader.ShadowSettings.json` | `meson.build` | `--buildtype=release` in config-opts | WIRED | `"config-opts": ["--buildtype=release"]` at manifest line 20 |
| `data/...metainfo.xml` | `meson.build` | `install_data` for metainfo to `share/metainfo/` | WIRED | meson.build lines 79-82 confirmed |
| `io.github.matrixshader.ShadowSettings.json` | `data/...desktop` | `command: shadow-settings` matches desktop Exec field | WIRED | Manifest `"command": "shadow-settings"` matches `.desktop` `Exec=shadow-settings` |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| FR-6 | 05-01 | Search across all detected settings, indexing summaries and descriptions | SATISFIED | `perform_search()` iterates all categories, matches `def.label` and `def.subtitle` case-insensitively |
| NFR-2 | 05-01, 05-02 | Launch under 500ms; schema scan under 100ms; lazy panel construction | PARTIAL | Lazy panels: confirmed (panels_built HashTable). Schema scan timing: not instrumented — no GLib.message timing output. Binary at 216KB suggests fast load but needs human timing. |
| NFR-3 | 05-02 | Compiled binary under 500KB | SATISFIED | Release binary: 216,336 bytes (211KB). Well under 500KB. |
| NFR-4 | 05-02 | Works on GNOME 43+ (GTK4 4.12+, libadwaita 1.4+) | SATISFIED | meson.build declares minimum versions; all APIs used (SearchBar, SearchEntry, StatusPage) available since GTK4 4.0 / libadwaita 1.0 |
| NFR-5 | 05-02 | Flatpak packaging submitted to Flathub | PARTIAL | Manifest and metainfo created and correct. GitHub repo not pushed. Flathub submission PR not opened. Screenshot for metainfo not taken (`data/screenshots/` does not exist). |

---

## ROADMAP Success Criteria Assessment

The ROADMAP lists 9 success criteria for Phase 5. Mapping each:

| # | ROADMAP Success Criterion | Status | Notes |
|---|--------------------------|--------|-------|
| 1 | Search across all settings (index summaries + descriptions) | VERIFIED | perform_search() covers label + subtitle |
| 2 | Search filters across all categories | VERIFIED | Iterates all CategoryInfo[] entries |
| 3 | Launch time under 500ms, schema scan under 100ms | UNCERTAIN | No timing instrumentation; needs human test |
| 4 | Binary under 500KB | VERIFIED | 211KB release binary confirmed |
| 5 | Flatpak manifest with correct permissions (dconf portal) | VERIFIED | Manifest correct; `--metadata=X-DConf=migrate-path` present |
| 6 | `flatpak-builder-lint` passes clean | FAILED | Not run; documented as human TODO but listed as ROADMAP success criterion |
| 7 | Appstream metainfo.xml with screenshots and descriptions | PARTIAL | metainfo.xml is complete but screenshot URL points to a file that does not yet exist (`data/screenshots/main.png` absent; no `screenshots/` dir) |
| 8 | GitHub repo created (matrixshader/shadow-settings) | FAILED | No remote configured; code not pushed |
| 9 | Flathub submission PR opened | FAILED | Blocked by item 8; not done |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `data/io.github.matrixshader.ShadowSettings.metainfo.xml` | 28 | Screenshot image URL points to `data/screenshots/main.png` which does not exist on disk or GitHub | Warning | Flathub validators and appstream-util will flag a broken image URL; submission will fail validation without a real screenshot |

No TODO/FIXME/placeholder comments found in modified source files. No empty implementations or console.log-only stubs. Code is substantive throughout.

---

## Human Verification Required

### 1. Launch time measurement

**Test:** Run `time ./builddir/shadow-settings` — measure from launch to first interactive frame.
**Expected:** Under 500ms cold start.
**Why human:** Requires timing on the target hardware. No GLib.message timing was added to `discover_all()` so there is no programmatic measurement point.

### 2. Schema scan timing

**Test:** Add a temporary `GLib.message("scan time: %lld ms", ...)` around `scanner.discover_all()` in window.vala, rebuild, and observe output.
**Expected:** Under 100ms (NFR-2).
**Why human:** No instrumentation was added; cannot verify from code alone.

### 3. Search cross-category results

**Test:** Launch app, press Ctrl+F, type "font".
**Expected:** Results from at least Appearance and Windows categories appear, each under a PreferencesGroup header bearing the category name.
**Why human:** Depends on which GSettings schemas are installed on the running system.

### 4. Deprecated key filtering

**Test:** Search for "menubar", "tearoff", "can-change-accels".
**Expected:** Zero results.
**Why human:** Requires runtime to confirm the keys are actually excluded from the discovered set.

### 5. Escape key / search dismissal

**Test:** Activate search, navigate to a category, activate search again, then press Escape.
**Expected:** Previous category panel restores; subtitle reverts to "N hidden settings found".
**Why human:** Signal flow and UI state restoration requires GTK4 runtime observation.

### 6. Screenshot for metainfo

**Test:** Take at least one screenshot of the running app, save to `data/screenshots/main.png`.
**Expected:** Screenshot URL in metainfo.xml resolves after pushing to GitHub.
**Why human:** Visual content; requires human judgment on quality.

### 7. flatpak-builder-lint

**Test:** Run `flatpak-builder-lint manifest io.github.matrixshader.ShadowSettings.json` and `flatpak-builder-lint appstream data/io.github.matrixshader.ShadowSettings.metainfo.xml`.
**Expected:** Both pass with no errors (ROADMAP success criterion 6).
**Why human:** Tool may not be installed in current environment; requires Flatpak tooling.

---

## Gaps Summary

Three gaps block the full ROADMAP success criteria, all in the distribution/submission area rather than the search feature itself.

**Gap 1 — flatpak-builder-lint not run.** The ROADMAP explicitly lists "flatpak-builder-lint passes clean" as a success criterion. The manifest and metainfo are structurally correct (developer id attribute, oars-1.1 content_rating, correct install path), so lint is likely to pass, but it has not been confirmed. The 05-02-PLAN.md notes the human can run linting before submission.

**Gap 2 — GitHub repo not created or pushed.** The ROADMAP requires "GitHub repo created (matrixshader/shadow-settings)". No git remote is configured. This is a user-action prerequisite that the 05-02 plan correctly flags as human-required, but it remains incomplete.

**Gap 3 — Flathub submission PR not opened.** Directly blocked by Gap 2. The 05-02 plan correctly identifies this as human-only (AI submission prohibited by Flathub policy). The `data/screenshots/` directory does not exist, and the metainfo screenshot URL will 404 until a screenshot is committed and pushed.

These gaps are all downstream user actions, not coding defects. The search feature (FR-6) and all packaging artifacts (NFR-3, NFR-4, core NFR-5) are fully implemented and wired. NFR-2 performance is implemented structurally (lazy panels, efficient scanner) but lacks timing confirmation.

---

_Verified: 2026-03-14_
_Verifier: Claude (gsd-verifier)_
