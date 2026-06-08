# Phase 5 — per-op uncomputation PRD (PARTIALLY SUPERSEDED · archived 2026-06-08)

This directory holds the **per-op uncomputation** PRD and implementation plan.
Like the sibling `phase04-controlled-form/`, it belongs to the **taint-driven**
design — **not** the pre-taint `quantum`-keyword era documented elsewhere under
`old-design/`. It is filed here only because this is the repository's archive for
superseded design documents.

**Why archived — but read the nuance.** Unlike Phase 4 (which was removed
wholesale in `7cde677`), Phase 5 is a *mixed* case:

- **What survived and is LIVE.** The uncompute spine —
  `EmitInverse` / `ChainWalk` / `FreePoint` / `Uncomputation` — shipped (old-gen
  Steps 0–3) and is **still in the tree, reused by the swap-route emitter** for
  reverse-play and rail cleanup (see `CLAUDE.md` Rule 14). The current
  design-of-record for that spine is [`docs/backend.md`](../../../../backend.md)
  §9–10, **not** this PRD.
- **What is dead.** The PRD's control-coupled mechanics — `InShadowAdjoint`,
  `ControlFlag` image-subtraction, the `_controlled_inv`-nested-in-Phase-4-flag-
  bracket path — depend on machinery excised in `7cde677`
  (`ControlDetection` / `MergeDissolution` / `ControlFlag.cpp`). Their producers
  are gone and `ControlStub.cpp` loud-declines all tainted control, so the
  in-shadow path is now **unreachable dead code** in the live spine (a cleanup
  breadcrumb). The PRD also frames uncompute as a *separate phase after control*,
  which the swap-route doctrine supersedes — reverse-play is now mandatory **in
  every increment, never deferred** (`CLAUDE.md` Rules 5–6).

- **Current Phase 4/5 design:** [`docs/design/rssa-swap-control/`](../../../../design/rssa-swap-control/)
  (`OVERVIEW.md` + `SCOPING.md`), [`docs/backend.md`](../../../../backend.md)
  §9–10, and [`ROADMAP.md`](../../../../../ROADMAP.md).
- **Contents (reference only):** `PRD.md`, `IMPLEMENTATION.md` — the old-gen
  per-op-uncomputation phase docs.
- The old-generation Phase 5 **bd issues** (epic `test_C_libtooling-2kh` + ten
  children) were **erased 2026-06-08** in the swap-route reconciliation. The one
  piece of irreplaceable knowledge they held — the **divergent-arm uncompute
  soundness invariant** and its round-1 silent miscompile (`543bd85`) — is
  preserved in `bd remember` under key
  `divergent-arm-uncompute-soundness-guard`. The closed Steps 0–2 are likewise
  preserved in `phase5-step{0,1,2}-*` memories.

**Do not revive the dead control-coupled path** — see
[`CLAUDE.md`](../../../../../CLAUDE.md) → "Key Prohibitions". The hard-won
correctness lessons carry forward into the swap-route emitter, restructured
rather than deleted.

> Internal back-links inside the archived documents below were not re-pathed
> after the move (matching the rest of `old-design/`); follow the live pointers
> above instead.
