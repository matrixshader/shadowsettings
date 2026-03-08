---
phase: 2
slug: dynamic-detection-engine
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-07
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Meson compile (no unit test framework — GTK4/Vala app) |
| **Config file** | meson.build |
| **Quick run command** | `cd /home/neo/shadow-settings && meson compile -C build 2>&1 \| tail -5` |
| **Full suite command** | `cd /home/neo/shadow-settings && rm -rf build && meson setup build && meson compile -C build` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick compile
- **After every plan wave:** Run full clean rebuild
- **Before `/gsd:verify-work`:** Full rebuild + launch test
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 02-01-01 | 01 | 1 | FR-1, FR-4 | compile | `ls src/core/setting-def.vala` | ⬜ pending |
| 02-01-02 | 01 | 1 | FR-1, FR-4 | compile | `meson compile -C build` | ⬜ pending |
| 02-02-01 | 02 | 2 | FR-1, FR-2 | compile | `ls src/registry/*.vala` | ⬜ pending |
| 02-02-02 | 02 | 2 | FR-1, FR-4 | compile | `meson compile -C build` | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Meson build system already configured.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App launches showing dynamic sidebar | FR-1 | Requires display server | Run `./build/shadow-settings`, verify sidebar shows detected categories |
| Settings count displayed | FR-1 | Visual verification | Check subtitle/header shows "N hidden settings found" |
| No GNOME Settings duplicates | FR-2 | Editorial verification | Cross-check displayed settings against GNOME Settings panels |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-07
