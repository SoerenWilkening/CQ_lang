# Phase 4 — controlled-form control lowering (SUPERSEDED · archived 2026-06-08)

This directory holds the **controlled-op** approach to tainted control flow. It
belongs to the **taint-driven** design — **not** the pre-taint `quantum`-keyword
era documented elsewhere under `old-design/`. It is filed here only because this
is the repository's archive for superseded design documents.

The controlled-op path (mint a flag → substitute each arm gate with a
`_controlled` template → dissolve the `phi` → uncompute the flag → linearize the
CFG) shipped (Phase 4 core + 4.1 switch/escape + 4.2 mux + 4.3 if-completeness +
4.x MUX-EXCH) and was then **removed wholesale** in commit `7cde677` so the RSSA
**swap-route** design could be built without it shaping the implementation.

- **Current Phase 4 design:** [`docs/design/rssa-swap-control/`](../../../../design/rssa-swap-control/)
  (`OVERVIEW.md` + `SCOPING.md`) and [`ROADMAP.md`](../../../../../ROADMAP.md)
  §"Phase 4 — RSSA swap-routed tainted control flow".
- **Contents (reference only):**
  - `PRD.md`, `IMPLEMENTATION.md`, `MISSING_CASES.md` — the controlled-form phase docs.
  - `npu6-mux-exch-gate-spec.md` — the MUX-EXCH uncompute-safety gate spec.
- The excised modules (`ControlDetection`, `ControlFlag`, `ControlledLowering`,
  `ControlledSubstitution`, `FlagConjunction`, `CFGLinearization`,
  `MergeDissolution`, `SwitchNormalization`) are recoverable from git history
  (branch `rssa-swap-control`).

**Do not revive this approach** — see [`CLAUDE.md`](../../../../../CLAUDE.md)
→ "Key Prohibitions". The hard-won correctness lessons carry forward into the
swap-route emitter, restructured rather than deleted.

> Internal back-links inside the archived documents below were not re-pathed
> after the move (matching the rest of `old-design/`); follow the live pointers
> above instead.
