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
