---
phase: 5
slug: search-polish-distribution
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-13
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vala compile + runtime smoke test (no test framework) |
| **Config file** | none |
| **Quick run command** | `meson compile -C builddir` |
| **Full suite command** | `meson compile -C builddir && ./builddir/shadow-settings` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `meson compile -C builddir`
- **After every plan wave:** Run `meson compile -C builddir && ./builddir/shadow-settings`
- **Before `/gsd:verify-work`:** Full build + lint checks must pass
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | FR-6 | smoke | `meson compile -C builddir` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | FR-6 | manual | Launch app, search "font", verify cross-category results | N/A | ⬜ pending |
| 05-01-03 | 01 | 1 | NFR-2 | instrument | Check GLib.message timing output from discover_all() | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 2 | NFR-3 | automated | `ls -la builddir-rel/shadow-settings \| awk '{print $5}'` < 512000 | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 2 | NFR-5 | automated | `flatpak-builder-lint manifest <manifest>` | ❌ W0 | ⬜ pending |
| 05-02-03 | 02 | 2 | NFR-5 | automated | `flatpak-builder-lint appstream <metainfo>` | ❌ W0 | ⬜ pending |
| 05-02-04 | 02 | 2 | NFR-4 | automated | `meson compile -C builddir` — no API beyond libadwaita 1.4 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `io.github.matrixshader.ShadowSettings.json` — Flatpak manifest
- [ ] `data/io.github.matrixshader.ShadowSettings.metainfo.xml` — Appstream metainfo
- [ ] `README.md` — install instructions (native + Flatpak)

*Wave 0 artifacts created during plan execution, not pre-existing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Search filters across categories | FR-6 | UI interaction required | Launch app → type in search → verify results from multiple categories appear |
| Flatpak runs in sandbox | NFR-5 | Requires flatpak-builder | Build with manifest → `flatpak run` → verify settings load |
| Flathub submission accepted | NFR-5 | Human-must-act (Flathub policy) | Open PR on flathub/flathub manually |
| Screenshots in metainfo | NFR-5 | Visual content | Take screenshots, add to metainfo |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
