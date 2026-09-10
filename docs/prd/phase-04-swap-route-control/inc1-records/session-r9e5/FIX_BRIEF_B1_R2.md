# Fix brief — round-2 BLOCK F-B1R2-1 (bd `r9e5` 1b-B.1): re-verify every emitted RAIL read under FINAL taint

Branch `3qlq-inc1b-b-rail-select` at checkpoint f8d29e8. Report: `review_b1_r2.md` §2 (read it whole,
including the discriminator table and §6 "what round 3 should do"); probes `review_b1_r2_probes/`
(`ll/e04`, `ll/e05`, `ll/e06`, `ll/e07`, `ll/e11`, `c/e02`, `c/e03`, `multi/e16_{caller,lib}.c`).

## The defect, in one paragraph

The rail ladder (rungs (ii) measured-before and (iii) the wire question) is asked inside
`detectControlRegions` at ROUND-1 taint. `repropagateControlMerges` then re-seeds taint from the 6.5/4.5
`%out` rails, and `lowerRotations` decides chained-vs-source with FINAL taint
(`Chained = taint.Tainted.count(Op)`, `RotationLowering.cpp:231`). A `cq_theta_i1(%x, θ)` whose `%x`
is DERIVED from `%out` is a SOURCE theta to both closures at round 1 (`railWireNamesBackward` stops;
`findNonDiagonalWireGate`'s F-1b-1 ancestry does not cross), so its sibling `cq_theta_i1(%x, θ')` is off
the wire and rung (iii) is clean — and a CHAINED theta to the lowering, which puts both siblings on ONE
rail. The select's copies (emitted at round 1) then control on `Ry(θ')Ry(θ)|x⟩` while the SSA condition
names `Ry(θ)|x⟩`. Plain C, two TUs (`e16`): declines `bare i1 register condition` on `main`, compiles on
this tree at exit 0, verify-clean, STRICT-2b clean. Same window for rung (ii) (`e06`/`c/e02`: the
measure form). Pre-existing for the COMPARE select (`e08`/`e13` accept on `main` with the same wrong
stream) — NOT this fix's; filed separately (see §4).

## DECIDED: option 1 — re-verify, do not re-derive (the bd `eqpx` (1b) tripwire pattern)

No prediction of what round 2 will taint (option 2 is a PREDICTION — the exact shape of the eight
findings in CLAUDE.md's CORRECTNESS-RISK section), no blunt closure (option 3 costs `e11`'s correct
opaque-classical-seed accept). Instead:

1. **RECORD every emitted rail READ.** `TaintSet` gains
   `SmallVector<std::pair<llvm::WeakTrackingVH /*Rail: the cq_theta_i1 call*/, llvm::WeakTrackingVH
   /*FirstRead: the first emitted cqrt_* call that takes the rail as an operand*/>, 4> RailCondReads;`
   Written at the emission sites that read a rail as a control:
   * `CondTreeEmit::emitCondNetwork` — (a) the `CopyRailRoot` mint: the `cqrt_cnot(rail, bf)` call;
     (b) a NON-root rail leaf: the first node gate created with the rail in `N.L`/`N.R` (record inside
     `emitCondNode`'s forward emission, once per rail — a shared rail records its first gate only).
     Do it in the network so the select, the nest and any future data-path caller get it for free.
   * `SwapRouteEmit::emitKickbackGroup` when `FlagIsRail` — the first `cqrt_rz_i1(rail, ·)` it emits
     (the flat kickback root and the nest's outer root both come through here).
   * `AngleSelectEmit::emitPhaseAngleSelect` on a rail — its first `cqrt_rz_i1(rail, ·)`.
   The read point must be a call that SURVIVES to the stage below — the select is erased by
   `emitSelectRegion` step 6 and the branch by `flattenRegion`, so neither may be the anchor.
   `WeakTrackingVH` because later stages may erase instructions; a nulled entry is SKIPPED (say why:
   an erased read cannot be a live control read), never treated as a failure.
2. **RE-VERIFY after the round-2 fixpoint, in BOTH entry points of `CQLoweringPass.cpp`** (the
   `repropagateControlMerges` calls at ~409 and ~824 — read the P7/`deleteGlobalPhases` placement
   comments there: this is the "a stage that runs ONCE has a round-2-FALSE premise" lesson, and the fix
   sits exactly where P7 was moved to). New stage `reverifyRailCondReads(M, taint)`
   (in `ArmClassify.cpp` next to the helper, declared in `ArmAnalysis.h`): for each record, rebuild a
   `DominatorTree` for the function (per function, cached across records), then ask with FINAL taint
   * rung (ii): `railMeasuredBeforeReadPoint(Rail, FirstRead, taint, &DT)` → decline
     `condition measured before the control route`;
   * rung (iii): `findNonDiagonalWireGate({Rail}, /*CrossValueRouting=*/true, nullptr, nullptr, &taint)`
     non-null AND `findNonDiagonalWireGate({Rail}, true, /*EmitPoint=*/FirstRead, &DT, &taint)`
     non-null → decline `condition predates a non-diagonal gate`.
   Anchor the diagnostic on `FirstRead` (it carries the region's `!dbg`). LOUD and FINAL — `opt` exits
   non-zero; the already-emitted stream is discarded with the module. NEVER a silent fallback. The
   ordinary (round-1-clean) programs pay two walks per rail read and change nothing — measure that:
   the whole lit corpus and every golden must be byte-identical except the new fixtures.
   ⚠ The walker looks for `cq_theta_` users; the region's own emitted `cqrt_*` gates are not thetas
   and are invisible to it — say so in the stage's header, it is why re-asking after emission is sound.
   ⚠ Ask the position-free walk with `Taint` (the F-1b-1 crossing) — that is the whole point: at final
   taint the crossing now reaches the sibling.
3. **Do NOT change the classifier's round-1 ladder** (it stays as the early, cheap, detect-before-mutate
   answer); do NOT touch `RotationLowering`; do NOT widen anything for the compare select (§4).

## Rule 12 — fixtures (red on f8d29e8, green after)

* `control_swap_reject_select_rail_round2_sibling_theta.ll` — `ll/e04` verbatim (hand IR: the 6.5 arm
  producing `%out`, `%x = trunc %out`, two sibling `cq_theta_i1(%x, ·)`, the rail select). DECLINE
  `condition predates a non-diagonal gate`. RED on f8d29e8 (it ACCEPTS there — say so in the header
  with the wrong stream quoted).
* `control_swap_reject_select_rail_round2_measured_parent.ll` — `ll/e06` (the measure form; rung (ii)).
  DECLINE `condition measured before the control route`.
* `control_swap_select_rail_round2_opaque_seed_accept.ll` — `ll/e11` (the seed is a `load volatile` of a
  global `i1` that STAYS classical; two SEPARATE registers). ACCEPT, with an ordered CHECK on the two
  `cqrt_alloc_i1` mints and the two independent `cqrt_ry_i1`, and a `CNCNT` — the discriminator that
  the fix is a re-verification and not option 3.
* `control_swap_select_rail_round1_sibling_theta_control.ll` — `ll/e05` (`%x = trunc %q`, tainted at
  ROUND 1): DECLINES on both binaries at round 1 — the control that the classifier's own ladder still
  fires first. If an identical fixture already exists (`..._stale_sibling_theta.ll`), cite it instead.
* The KICKBACK spelling: try to reach the window for the flat kickback (`e09` declined for an
  unrelated structural reason — find a spelling that gets past it, e.g. keep `%out` live through a
  measure as `e16` does); if one accepts on f8d29e8, add `control_phase_kickback_reject_rail_round2_sibling_theta.ll`;
  if none does, record the measured attempts in `FIX_B1_R2.md` §Measured and do not fabricate one.
* e2e: `tests/e2e/slice_control_select_bool_round2_window.c` + `_lib.c` through `run_slice_multi.sh`
  (`e16` verbatim) as a DECLINE slice IF the harness has a decline mode; otherwise pin it in lit only
  and say so. Also `slice_control_select_bool_round2_opaque_seed.c` (the accept twin from C, if
  reachable with a `volatile` global; measure).
* Injection check on the accept: an injected sibling `cqrt_ry_i1` on the rail between the two
  cnots must turn `RYCNT`/`ORD` red.

## Measure and report (`FIX_B1_R2.md` in this directory)

Pre (f8d29e8, saved: copy `build/ir-pass/{cq-opt,libCQPass.so}` to your scratch BEFORE rebuilding) vs
post over (a) all 1765 lit fixtures — expect 0/0/0 outside the new files; (b) the round-2 reviewer's
corpus `review_b1_r2_probes/run.sh` and `run_multi.sh` — expect exactly `e04`, `e06`, `e07`,
`c/e02`, `multi/e16` (and any kickback spelling you reach) to move, ALL to a decline, and `e11`
unmoved; (c) the round-1 corpus `review_b1_r1_probes/run_corpus.sh POST` — expect 0 movers vs the
orchestrator's post-fix-1 record `scratchpad/VERDICTS_FIX1.txt` (re-run PRE too if the scratch is gone);
(d) `probes/` (the 39) — expect 0 movers; (e) every e2e golden byte-unchanged (`git status --porcelain
tests/`); (f) `ctest -R ir-pass-lit`, `ctest -j6 -R '^e2e-'`, and the full `ctest -j6`. Report only
what you ran, with numbers.

## §4 — filed, not fixed here

The COMPARE select (`e08`/`e13`: `icmp eq %b, 1` with `b = cq_theta(%out_derived)`, sibling theta) has
the same window and ACCEPTS on `main` with the wrong stream — a PRE-EXISTING P1, bd (orchestrator files
it). The record structure above is deliberately shaped to take compare SEEDS next (`Prov` of each leaf,
read point = the leaf's mint template) so that increment is an extension, not a second stage. The
kickback and nest get the record from this fix because the sites are shared (`emitKickbackGroup`,
`emitCondNetwork`); say in `FIX_B1_R2.md` whether any kickback program moved.

Non-negotiables: no `cqrt_x` on a user register; no new runtime symbol; never a silent fallback; do not
commit; the orchestrator runs the final gate and launches round 3.
