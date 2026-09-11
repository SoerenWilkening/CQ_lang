# Rule-13 review brief, round 1 — bd `l4x4` sub-increment l4x4.b: the in-place controlled-Ry ARM and controlled STATE PREP on a bare `_Bool` (rail-root) condition, incl. the NEGATED condition

Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch `l4x4b-bool-ry-arm` (based on the Track C F2
checkpoint 578dbc4, NOT on `main`), `build/` current (do NOT rebuild; do NOT edit `ir-pass/`, `include/`,
`tests/`, `tools/`). Read in order: `BRIEF_l4x4b.md`, `IMPL_l4x4b.md` (its §2b ERRATA and §7 Q1–Q7),
`SCOPE_l4x4.md` (§2.2 H-1, §2.3 negation, §2.6 partition, §2.7 freeze, §2.9 record sites, §3 hazards),
`probes/README.md` + `probes/impl/`, and `../session-f2-i1/IMPL_f2.md` (the base). Three binaries:
ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (main 0c7380c), F2-BASE
`/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt` (checkpoint 1419b5e — comment-only ahead of
578dbc4, behaviour identical), SUBJECT `/Users/sorenwilkening/Desktop/CQ_l4x4/build/ir-pass/cq-opt`; each
with its sibling `libCQPass.so`; all read-only. Gates already run: `ir-pass-lit` 1810/1809+1 XFAIL; e2e
386/386 (twin matrix Passed, no cell moved); full `ctest -j6` 396/396; `cq-opt-equivalence-full` 1810/0;
three-way corpus diff over 1784: ORACLE→F2 23 (Track C's), F2→SUBJECT 2 DECLINE→ACCEPT (`bare i1 register
condition`), DIAGDIFF 0, OUTDIFF 0; injection matrix 15 fixtures × 7 mutations 0 MISSED / 0 DIRTY.

## What changed

* `ArmClassify::classifyArms`: gate widened at `:2556` (`RailCond = isCondRailLeaf`); rungs (i)+(ii) at
  `:2590-2601`; `comparePredLowerable` and the `HasDataUse`/`ShareCondFlag` block SKIPPED for a rail
  (`:2581`, `:2621`); rung (iii) at `:2689`; the §2.6 five-class re-decline partition is ONE lambda
  `declineRailClass` (`:2720`) called at FOUR accept sites (`:2856` phase, `:2882` eq-fold, `:3763`
  phase-leaf, `:3971` value); rail-only scope fences at `:2940` (in-loop → `control flow inside a loop
  body`, the l4x4.c carve-out), `:2954` (>1 arm), `:2976` (undef angle on a negated arm);
  `RailLadderProven` set at `:3738`, `emitInPlaceRotationRegion` refuses a rail without it (`:689`).
* Emitter: `Value *Cond`; `Flag = RailCond ? Cond : lowerCompareToFlag(…)`; strip + free skipped for a
  rail; `emitRegion` dispatches the rail before the `CmpInst` cast. NEGATION = Ry additivity: `ry(h,θ);
  ry_controlled(h_b,h,−θ)`, the angle by `APFloat::changeSign` (exact); never a `cqrt_x`.
* H-1 (the raw `Value*` control in `taint.ControlledRotations`) fixed structurally in three parts:
  `WeakTrackingVH` mapped type; a deterministic CONTROL-THETAS-FIRST pass in `lowerRotations` (claimed a
  no-op without a rail control, witnessed by 0 OUTDIFF); a loud use-site check (first spelling
  `isIntegerTy(32)` was WRONG and cost an accept — corrected to "the control is no longer the theta call").
* Freeze: arg-1 (the rotated register) frozen as before; arg-0 (`b`, the control) NOT frozen but LEFT
  ALLOCATED, never freed (`isInPlaceGateOn` needs arg-1==H, the `_controlled` bail refuses it, so
  `isTerminalHandle` says no and `preservesBasisUnderRecord` excludes it) — the same disposition the
  compare form gives its condition register (`t11c`). Pinned by `..._rail_dead_register.ll` (FCNT-NOT) and
  `..._rail_data_use.ll`.
* Two fixtures `git mv`'d DECLINE→ACCEPT (IR byte-unchanged): `control_inplace_ry_reject_raw_i1_cond.ll`,
  `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll`. Owner's isolated second region:
  `alloc_i1(0)->h0; ry_i1(h0,.5); alloc_i1(0)->h1; ry_i1(h1,.5); ry_i1_controlled(h0,h1,-.5); measure;
  measure` (`slice_control_inplace_ry_bool_stateprep_negated`).

## Where to look (over-accept is the only unforgivable bug; the owner also wants NO over-decline of a valid circuit)

1. **The control is a LIVE user register — the whole-DAG spine.** `b` dead after the region (no
   measure): does the spine ever ADJOINT `b`'s own chain (`ry_i1(h0,−.5); free(h0)`) after the
   controlled gate read it? That would free a rail entangled with `r` (Rule 6). The implementer says
   `isTerminalHandle` refuses; probe with `b` dead, `b` measured, `b` read as data (`zext`), `b` borrowed
   by a chain (`int z = b + 1`), `b` a CHAINED theta (`b = cq_theta(b0, .3)`; then is `b0`'s rail freed?),
   two regions on one `b` (diamond then prep; prep then kickback; prep then SELECT — the 1b-B.1 CNOT copy
   on a register that is now a `_controlled` control), and a `cq_invert` around it.
2. **Negation by Ry additivity — the state vector.** `ry(h,θ); ry_c(h_b,h,−θ)`: on `b=0` the product is
   `Ry(θ)`, on `b=1` `Ry(−θ)Ry(θ) = I` — exact for the TENSORED `cqrt_ry_<W>` (each qubit of `h`
   independently). Attack the ORDER: the unconditional twin runs FIRST on `h`; if `h` is READ between the
   twin and the controlled gate (a compare, a copy, a measure — can `-O1` schedule one there? can the
   emitter's positional insertion put one there?), the intermediate state `Ry(θ)|r⟩` is observed on the
   `b=1` branch where the source has `|r⟩`. For the PREP the twin acts on a fresh rail (safe); for the
   in-place ARM on `r` it acts on the user's register — find a reader. Also `θ = ±0`, `θ` NaN/inf, and the
   `undef` angle fence at `:2976`.
3. **H-1's three parts.** (a) `WeakTrackingVH` follows the RAUW — but `lowerRotations` RAUWs the theta
   CALL to the handle; a `WeakTrackingVH` on the call becomes null when the call is ERASED, not the handle
   — which is it, and what does the use-site check do on null (loud? silent skip?)? (b) "control thetas
   first" is a deterministic ORDERING change in `lowerRotations` — is the emitted stream order for
   programs WITHOUT a rail control truly unchanged (0 OUTDIFF over 1784 says yes for fixtures; probe a
   program with two independent registers where the ORDER of `cqrt_alloc`s determines handle numbers and
   a golden would move)? (c) a control theta that is itself CHAINED (`b = cq_theta(b0,.3)`) and one whose
   rotation lowering DECLINES (quantum-derived angle) — what is left in the module?
4. **The partition at four accept sites (H-8).** The phase/eq-fold/phase-leaf/value classes must keep
   `bare i1 register condition` for a rail — for the VALUE class specifically (bd `fg9k`'s shape: a long
   arm with a merge phi on a rail condition) confirm the decline; then the eq-fold path (`tryEqFoldArm`)
   with a rail; then a rail condition whose arm is BOTH an in-place Ry and a `cq_phi` (mixed) — must
   decline (which string?).
5. **The skipped `HasDataUse`/`ShareCondFlag` (H-4/H-7).** A rail `b` that is ALSO the arm's rotated
   register (`if (b) b = cq_theta(b, θ)` — must decline: which fence, F1 per SCOPE; confirm), that is the
   SEED (`if (b) r = cq_theta(b, θ)` folded — Track C's α; confirm `t16b`-style accept-as-prep is what you
   get and argue it), that is read by a LATER region's compare (`if (b) r=…; if (b == 1) …`).
6. **F2 on the rail.** The owner's seed `false` under `b0` pinned `false` on the arm edge is admitted by
   Track C's narrowing — re-derive; then a seed that equals the pin of a DIFFERENT live `i1` (a second
   bool `c` derived from `b`: `bool c = !b; if (!b) r = cq_theta(true?…)`) — must still decline (Track C's
   I-4 residual); measure.
7. **In-loop (`:2940`).** The carve-out string `control flow inside a loop body` — does that string exist
   elsewhere, and is the fixture mirroring it exact? A rail arm in a loop whose `b` is INVARIANT (the
   Inc-1b/1b-B.1 rolled accept class for phase/select) — is declining it an OVER-DECLINE the owner will
   hit (Grover as a loop with a controlled prep)? Say so plainly and grade it OVER-DECLINE if the circuit
   is valid; the carve-out is l4x4.c and the owner should know the cost.
8. **`markRailCondRead` at the new sites (Q1).** With the record, the two-TU round-2 program declines;
   confirm the two new sites are the ONLY rail reads this increment adds (grep every `cqrt_ry_*_controlled`
   emission with a rail arg-0) and construct the round-2 window through the PREP (a `%out`-derived `b`).
9. **Q2 (pre-existing, found in passing):** a 6.5 classical-call-arm region followed by a flat region
   declines at the hcrg precedence graph (`reorderable()` admits only `BranchRegion`/`PhaseKickback`) —
   confirm on `main`, grade OVER-DECLINE, and I will file it.
10. **Every accept: `-O1` reachability + state vector; every decline: is the circuit invalid?**

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4_review/`;
plain C `-O1` first, hand IR second; all three binaries where the base matters; grade
CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC; verdict BLOCK / CLEAR-WITH-ITEMS /
CLEAR. Report `session-l4x4/review_l4x4b_r1.md`, probes `session-l4x4/review_l4x4b_r1_probes/` with a
runner. Final message ≤30 lines: verdict, findings one line each with grade, the spine outcome (item 1)
and the negation-order outcome (item 2) explicitly.
