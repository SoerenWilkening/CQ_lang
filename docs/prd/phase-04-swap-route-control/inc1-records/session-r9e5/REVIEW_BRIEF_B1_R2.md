# Rule-13 round-2 brief — bd `r9e5` 1b-B.1, the fix round on `review_b1_r1.md`'s items

Branch `3qlq-inc1b-b-rail-select`, 2026-09-10. Tree = checkpoint f9387f7 + the round-1 fix (uncommitted,
built in `build/`). Round 1 (`review_b1_r1.md`) returned CLEAR-WITH-ITEMS; this round reviews the fix
and looks for the "fifth thing" round 1 said to assume.

## What the fix changed (`git diff HEAD -- ir-pass/`)

1. **F-B1R1-1 (the SSA-name / wire asymmetry) — FIXED in the shared helper, both callers.**
   `ArmClassify.cpp`: new exported `railWireNamesBackward(Rail, Taint, Out)` — the rail, each chained
   ancestor theta (stepping through arg-0 while it is TAINTED, `lowerRotations`' own `Chained`
   relation), and the first NON-theta tainted parent (collected, NOT entered — its operands are other
   rails). `railMeasuredBeforeReadPoint` asks its `cq_measure` question over that closure. Forward names
   are deliberately not collected (a forward chained theta preceding the read point is already rung
   (iii)'s decline). Both the select and the two kickback callers get it. Measured: the reviewer's
   108-program corpus re-run moves exactly `r02`, `r22`, `h14` (select) and `r21`, `r41` (kickback),
   all ACCEPT → DECLINE `condition measured before the control route`; nothing else moves. Fixtures:
   `control_swap_reject_select_rail_measured_{parent_name,parent_before_chain,template_parent}.ll`,
   `control_phase_kickback_reject_rail_measured_parent_name.ll`, and the STOP pin
   `control_swap_select_rail_other_register_measured.ll` (measure of the cast's SOURCE `q`, a different
   rail, still accepts).
2. **F-B1R1-2 (the dead drift guard / the value-arm bypass) — a REAL tripwire.**
   `ControlPlan.h`: `ControlRegion::RailLadderProven`, set by `classifySelectRegion` on ACCEPT iff the
   tree has rail leaves; `emitSelectRegion` refuses a rail-carrying tree without it, with the original
   `bare i1 register condition` string, BEFORE any emission. `SwapRouteEmit::emitValueRegion`'s
   self-built `SelectRegion` does not set it (structurally `CmpInst`-only today; bd `fg9k` must go
   through the ladder). The old `RootIsRail` re-ask is kept (dead, harmless).
3. **F-B1R1-3 — pinned.** `control_swap_select_rail_inplace_xor_bridge.ll` (the reviewer's `ll/x01`:
   the xor lowers OUT of place, the second Ry moves `%h_op`, the merge controls on `%h`), and the
   `railCondWireDisposition` header names BOTH consumers and both pins.
4. **F-B1R1-4** — `IMPL_B1.md` counts annotated. Lit corpus 1759 → 1765.

## Attack surface for this round

* `railWireNamesBackward`'s STOP rules: a parent that is a phi (loop header rail, region merge), a
  `select` of rails, a 6.5/4.5 `%out`, a clone `Argument`, a QRAM load, a `zext`/`trunc` chain of
  depth 2 (`t2 = trunc(zext(q))`), a theta whose arg-0 is a `cq_theta` result of ANOTHER width (i32
  → i1 through a cast — is the cast a separate rail? yes, out of place; pin it), a source theta with
  a CLASSICAL seed that is nevertheless in `Tainted` (can that happen?), a rail measured through a
  FORWARD name in a LOOP (the theta after the select in program order, the measure after it — is
  rung (iii) really the decline there? measure it), a measure reachable only through an `invoke`/
  `unreachable`/abort park, a measure of the parent in a CLONE.
* Over-declines the widening introduced: any legitimate program where a name on the closure is
  measured AFTER the read point but `isPotentiallyReachable` says reachable (a loop with the measure
  after the select in the same body is the intended decline — show one where it is NOT intended, if
  any).
* The `RailLadderProven` tripwire: can ANY path today deliver a rail-carrying tree to
  `emitSelectRegion` without the classifier (measure `emitValueRegion`'s and `ClassicalCallArmEmit`'s
  reachability with rail conditions from C and hand IR — expected: they decline earlier with the same
  string); does the flag survive `repropagateControlMerges`' second round (a round-2 rail select)?
* Round 1's "fifth thing": pick the three areas of `REVIEW_BRIEF_B1.md` §"Where to look" you find
  least covered by round 1's §6 and probe them again with fresh programs (≥30 total this round).

## Method and report

As round 1 (`REVIEW_BRIEF_B1.md` §Method): PRE binary = the round-1 POST binary is GONE (rebuilt);
use the saved pre-B.1 pair for A/B and `review_b1_r1_probes/VERDICTS_POST.txt` as the round-1 record.
Do not rebuild, do not edit `ir-pass/`/`tests/`/`tools/`. Report to
`inc1-records/session-r9e5/review_b1_r2.md`, probes to `review_b1_r2_probes/`. Verdict BLOCK /
CLEAR-WITH-ITEMS / CLEAR; every accept argued from the state vector; report only what you ran.
