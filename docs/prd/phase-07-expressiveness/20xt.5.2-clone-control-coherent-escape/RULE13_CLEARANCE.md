# Rule-13 clearance — bd 20xt.5.2 (clone-control QROM coherent-escape bypass)

**Verdict: `safe_to_commit = true`** (independent adversarial workflow, opus,
`rule13-20xt52-clone-control-cohescape`, 2026-07-23). Branch `3c6m.14-control-l6`.

## Method

Source frozen (diff sha `de00ee1f26e9`), then a 6-lens adversarial review +
adjudicator. Review agents were FORBIDDEN to rebuild the shared `libCQPass.so`
(they ran the existing `.so` read-only via `opt` on scratch `.ll`); the owner
clean-rebuilt and re-verified afterward (`.so` mtime confirmed untouched at review
time). No source was edited mid-review; the two test-rigor fixes below were applied
AFTER the review and are TEST-ONLY (the cleared production code is byte-identical).

Lenses: `bennett-soundness`, `oob-bounds`, `scope-divergence`,
`cohescape-semantics`, `trace-correctness`, `fixture-rigor`.

## Outcome

- **5 code-soundness lenses CLEAN.** `bennett-soundness`, `scope-divergence`,
  `cohescape-semantics`, `trace-correctness` returned 0 findings; `oob-bounds`
  verified (in its `checked` record) that the bypass removes ONLY the
  coherent-escape reason and leaves every bounds gate intact (index-taint,
  pointer-index-width, `qromIndexKnownInBounds`, pow2 NeedsMask, and the
  un-bypassed emitter fence). (`oob-bounds` hit the workflow's StructuredOutput
  retry cap on its final serialization — its analysis is in the transcript; the
  adjudicator independently re-verified the OOB axis, and the owner confirmed
  both the non-pow2 reject and the Provable-phi over-decline exit non-zero
  loudly.)

- **Adjudicator independently confirmed** the four load-bearing invariants by
  reading source (not trusting the lenses): (1) `ClaimAll`/`inBennettClone` fires
  ONLY inside a Bennett-wrapped clone (single `flattenPredMuxRegions(claimAll=
  true)` caller = `lowerCloneControl`; all others default false); (2) the bypass
  strips ONLY the no-cloning coherent-escape reason, OOB fence fully intact
  (verified by the non-pow2 reject's loud decline, zero leaked loads); (3)
  `emitBennettWrap`'s copy-out-before-reverse always runs for any accepted+emitted
  clone — every intermediate bail is a loud `DS_Error` that rejects the module;
  (4) claim and emit share the predicate and each carries its OWN independent
  bounds fence, so any divergence declines loudly rather than half-lowering.

- **1 confirmed defect (MINOR, test-rigor), non-gating, FIXED:** the accept
  fixture's original CHECK-NOT block was VACUOUS — all negatives followed the last
  positive CHECK, so FileCheck scanned only the trailing declares, and the dead
  un-lowered original `@lookup` (which still holds `br`/`phi`/`load double`) sat
  above the clone. FIX (test-only): `CHECK-LABEL` on the clone + the negatives
  INTERLEAVED between adjacent positive CHECKs so they scan the clone body.
  Verified robust: the fixture now PASSES on the correct lowering and FAILS
  (exit 1) on an injected `cqrt_free(%arr)` (a Rule-6/8 dirty free) and on an
  injected `br i1` (re-introduced control).

- **1 NOTE (additive coverage), FIXED:** the two-table shared-index atanl shape
  (`atanhi[id]`/`atanlo[id]`, the Rule-8 fan-out) was pinned by no fixture. Added
  `spec_accept_qrom_read_arm_two_tables.ll` (verified: one shared index rail fans
  out to two per-read masks, each read reverse-played exactly once in LIFO order,
  shared base + both array handles never freed; PASSES + catches an injected dirty
  free). The census atan2l trace independently confirms this shape lowers soundly
  (2 reads / 2 `_unc`, indices `and .., 3` in-bounds, 0 double-frees).

- **2 refuted notes** (adjudicator).

## Owner-verified (independent of the workflow)

- atan2l census (O1+instcombine model): opt-exit-0 + LINKS + RUNS, 1598-line
  deterministic trace, 1 ry + 1 measure, 2 QROM reads each reversed, 0
  double-frees, masked indices in-bounds, array handles never freed.
- The shared-index reversal (atanl): `cqq.sel32` fans out to two `and(.,3)` masks,
  each read+mask reversed once; base index reversed once, freed once. No UAF.
- Provable-phi over-decline (`{0,1,2}`, no mask, opaque handle) and non-pow2 clone
  read both exit 1 (loud decline, module rejected) — safe, not silent.
- Full ctest 185/185 (184 baseline + 1 new e2e entry; the 3 new lit fixtures ride
  the existing `ir-pass-lit` aggregate entry), fresh clean rebuild.

## Deferred (safe over-declines, NOT correctness debt)

- Provable-phi-index clone read (no OOB sentinel → no mask → opaque
  post-lowerCloneSelect index → `kMsgQramCloneUnbounded` loud decline). Was
  declining before this increment too; strictly additive (this increment only ADDS
  the NeedsMask accept). A follow-up could mask pow2 clone reads uniformly.
- fcmp-condition integer index-select (a separate deferred `lowerCloneSelect`
  widening).
