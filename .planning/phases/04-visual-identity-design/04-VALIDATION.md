---
phase: 04
slug: visual-identity-design
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual visual inspection + GTK Inspector |
| **Config file** | none |
| **Quick run command** | `ninja -C builddir && ./builddir/shadow-settings` |
| **Full suite command** | `ninja -C builddir && GTK_DEBUG=interactive ./builddir/shadow-settings` |
| **Estimated runtime** | ~15 seconds (build + launch) |

---

## Sampling Rate

- **After every task commit:** Run `ninja -C builddir && ./builddir/shadow-settings`
- **After every plan wave:** Full visual walkthrough: all 3 themes, HC mode, animations, about dialog
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | NFR-1 | build | `meson setup builddir --wipe && ninja -C builddir` | N/A | ⬜ pending |
| 04-02-01 | 02 | 1 | NFR-1 | visual | `ninja -C builddir && ./builddir/shadow-settings` | N/A | ⬜ pending |
| 04-03-01 | 03 | 2 | NFR-1 | visual | `ninja -C builddir && ./builddir/shadow-settings` | N/A | ⬜ pending |
| 04-04-01 | 04 | 3 | FR-8 | visual | `ninja -C builddir && ./builddir/shadow-settings` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `data/io.github.matrixshader.ShadowSettings.gresource.xml` — GResource manifest
- [ ] `data/style.css` — base stylesheet stub
- [ ] `data/io.github.matrixshader.ShadowSettings.gschema.xml` — app preferences schema
- [ ] meson.build updates for GResource + GSettings schema compilation

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gotham Night theme | NFR-1 | Visual check | Switch to dark theme, verify deep blacks + amber accents |
| Gotham Day theme | NFR-1 | Visual check | Switch to light theme, verify warm grays + muted gold |
| Wayne Manor theme | NFR-1 | Visual check | Switch to warm theme, verify deep browns + warm amber |
| High contrast mode | NFR-1 | Visual check | Enable HC in GNOME Accessibility, verify readability |
| Row cascade animation | NFR-1 | Visual check | Switch panels, observe staggered row entrance |
| Modified-setting glow | NFR-1 | Visual check | Change a setting, observe amber pulse |
| Reduce motion toggle | NFR-1 | Visual check | Toggle setting, verify animations disabled |
| About dialog fields | FR-8 | Visual check | Open About, verify name/version/links/tip jar |
| Screenshot distinction | NFR-1 | Visual comparison | Compare with GNOME Settings, Tweaks, Refine |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
