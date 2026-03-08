---
phase: 03
slug: widget-factory-panel-generation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual testing (Vala/GTK4 app — no unit test framework) |
| **Config file** | none |
| **Quick run command** | `cd builddir && ninja && ./shadow-settings` |
| **Full suite command** | `meson setup builddir --wipe && ninja -C builddir && ./builddir/shadow-settings` |
| **Estimated runtime** | ~15 seconds (build) |

---

## Sampling Rate

- **After every task commit:** Run `cd builddir && ninja && ./shadow-settings`
- **After every plan wave:** Run `meson setup builddir --wipe && ninja -C builddir`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | FR-3 | manual | `ninja && ./shadow-settings` | N/A | ⬜ pending |
| 03-01-02 | 01 | 1 | FR-5 | manual | `ninja && ./shadow-settings` | N/A | ⬜ pending |
| 03-02-01 | 02 | 2 | FR-3, FR-7 | manual | `ninja && ./shadow-settings` | N/A | ⬜ pending |
| 03-02-02 | 02 | 2 | NFR-2 | manual | `ninja && ./shadow-settings` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no test infrastructure to set up for manual testing. Build verification is sufficient.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Boolean → SwitchRow | FR-3-a | GTK widget rendering | Launch app, navigate to Privacy, verify switches |
| Combo → ComboRow | FR-3-b | GTK widget rendering | Navigate to Windows > Titlebar Actions, verify dropdowns |
| SpinInt → SpinRow | FR-3-c | GTK widget rendering | Navigate to Windows > Auto-Raise Delay, verify spinner |
| Font → FontDialogButton | FR-3-d | GTK widget rendering | Navigate to Appearance > Fonts, verify font picker |
| Entry → EntryRow | FR-3-e | GTK widget rendering | Navigate to Windows > Drag Modifier, verify text entry |
| Title/subtitle display | FR-3-f | Visual check | Every row shows label + subtitle from registry |
| Range constraints | FR-3-g | Interactive check | SpinRow cannot exceed min/max |
| Reset button visible | FR-5-a | Visual check | Change a setting, verify undo button appears |
| Reset restores default | FR-5-b | Interactive check | Click reset, verify value returns to default |
| Changed CSS class | FR-5-c | GTK Inspector | Change setting, inspect for `setting-modified` class |
| Power hidden in Flatpak | FR-7 | Environment check | Verify `/.flatpak-info` check hides Power |
| Lazy panel construction | NFR-2 | Debug/print check | Verify build only called on navigation |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
