# Phase PRDs

One subdirectory per phase, named `phase-NN-<short-slug>`. Each phase's
PRD lives at `PRD.md` inside its phase directory; companion artifacts
(implementation plans, design notes, test plans) land alongside it as
the phase progresses.

Numbering is two-digit zero-padded for natural ordering through Phase
10. See [`ROADMAP.md`](../../ROADMAP.md) for the canonical phase
sequence and per-phase scope.

## Convention

- PRDs are written **at the start** of their phase, not in advance
  (per `ROADMAP.md` §"Document posture"). They memorialize the design
  decisions resolved during PRD-discovery discussion so the rationale
  survives between sessions and across the v1.0 freeze.
- A PRD does not duplicate the ROADMAP or the spec documents
  (`frontend.md`, `backend.md`, etc.). It captures phase-specific
  decisions, deliverables, and done criteria.
- Implementation plans, when written, live next to the PRD as
  `IMPLEMENTATION.md` in the same phase directory.

## Index

| Phase | Goal | PRD |
|---|---|---|
| 1 | New intrinsic surface in `CQ.h` | [`phase-01-intrinsic-surface/PRD.md`](phase-01-intrinsic-surface/PRD.md) |
| 2 | IR pass: taint sources, gate-triggered allocation | [`phase-02-taint-allocation/PRD.md`](phase-02-taint-allocation/PRD.md) |
| 3 | IR pass: full opcode lowering | [`phase-03-opcode-lowering/PRD.md`](phase-03-opcode-lowering/PRD.md) |
| 4 | IR pass: swap-routed control flow | [`phase-04-swap-route-control/PRD.md`](phase-04-swap-route-control/PRD.md) · [design](../design/rssa-swap-control/) · [archived controlled-form PRD](../archive/old-design/phases/phase04-controlled-form/PRD.md) |
| 5 | IR pass: per-op uncomputation | live spine: [`backend.md`](../backend.md) §9–10 · [archived PRD](../archive/old-design/phases/phase05-uncomputation/PRD.md) |

> **Phase 4 note.** The original **controlled-form** lowering was excised
> (commit `7cde677`) and replaced by the **RSSA swap-route** design
> ([`docs/design/rssa-swap-control/`](../design/rssa-swap-control/)); its PRD is
> archived at
> [`docs/archive/old-design/phases/phase04-controlled-form/`](../archive/old-design/phases/phase04-controlled-form/).
> The swap-route PRD ([`phase-04-swap-route-control/PRD.md`](phase-04-swap-route-control/PRD.md))
> was written at the start of the emitter work (2026-06-09); it covers the **4.1
> phase-arm increment** in full and records the binding decisions for 4.2–4.5.
>
> **Phase 5 note.** The per-op-uncomputation **PRD** was written against the
> controlled-form Phase 4 and is archived at
> [`…/phase05-uncomputation/`](../archive/old-design/phases/phase05-uncomputation/).
> Its **uncompute spine** (`EmitInverse`/`ChainWalk`/`FreePoint`/`Uncomputation`)
> nonetheless **survived the rebuild and is live** — reused by the swap-route
> emitter (`CLAUDE.md` Rule 14); the design-of-record for it is `backend.md`
> §9–10. The control-coupled bits of the PRD (`InShadowAdjoint`, `ControlFlag`
> subtraction) are dead post-`7cde677`. The old-generation Phase 5 bd issues were
> erased 2026-06-08.
